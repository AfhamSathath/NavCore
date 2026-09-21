import 'dart:math' as math;
import 'ecef_engine.dart';
import 'kalman_filter.dart';
import 'pnp_engine.dart';
import 'ar_navigation_state.dart';

class FusedSpatialPose {
  final GeodeticCoords position;
  final double headingDegrees;
  final double pitchDegrees;
  final double rollDegrees;
  final double movementVectorX;
  final double movementVectorY;
  final TrackingConfidence confidenceLevel;
  final double confidenceScore; // 0.0 - 1.0
  final DateTime timestamp;

  const FusedSpatialPose({
    required this.position,
    required this.headingDegrees,
    required this.pitchDegrees,
    required this.rollDegrees,
    required this.movementVectorX,
    required this.movementVectorY,
    required this.confidenceLevel,
    required this.confidenceScore,
    required this.timestamp,
  });
}

/// NexNav SensorFusionService: Integrates IMU + Camera + Compass + PnP Reference Markers
class SensorFusionService {
  final KalmanFilter _headingFilter = KalmanFilter(
    processNoise: 0.02,
    measurementNoise: 0.15,
  );
  final KalmanFilter _pitchFilter = KalmanFilter(
    processNoise: 0.03,
    measurementNoise: 0.10,
  );
  final KalmanFilter _rollFilter = KalmanFilter(
    processNoise: 0.03,
    measurementNoise: 0.10,
  );

  GeodeticCoords? _lastPnPPosition;
  DateTime? _lastPnPTime;

  double _smoothHeading = 0.0;
  double _smoothPitch = 0.0;
  double _smoothRoll = 0.0;

  /// Process raw sensor input stream and compute fused pose
  FusedSpatialPose updateFusion({
    required double rawHeading,
    required double rawPitch,
    required double rawRoll,
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
    GeodeticCoords? gpsCoords,
    PnPResult? latestPnPResult,
  }) {
    // 1. Filter orientation angles using Kalman filter
    _smoothHeading = _headingFilter.filter(rawHeading);
    _smoothPitch = _pitchFilter.filter(rawPitch);
    _smoothRoll = _rollFilter.filter(rawRoll);

    // Normalize heading to [0, 360)
    while (_smoothHeading < 0) {
      _smoothHeading += 360.0;
    }
    while (_smoothHeading >= 360.0) {
      _smoothHeading -= 360.0;
    }

    // 2. Compute movement vector from accelerometer & gyroscope
    final movementX = accelX * 0.1 + gyroY * 0.05;
    final movementY = accelY * 0.1 + gyroX * 0.05;

    // 3. Update PnP Reference lock state
    if (latestPnPResult != null) {
      _lastPnPPosition = latestPnPResult.calibratedUserCoords;
      _lastPnPTime = latestPnPResult.calibratedAt;
    }

    // 4. Resolve fused geodetic position (PnP > GPS > Fallback)
    GeodeticCoords effectivePosition =
        gpsCoords ??
        const GeodeticCoords(
          latitude: 25.197197,
          longitude: 55.274376,
          height: 0.0,
        );
    if (_lastPnPPosition != null && _lastPnPTime != null) {
      final secondsSincePnP = DateTime.now()
          .difference(_lastPnPTime!)
          .inSeconds;
      if (secondsSincePnP < 180) {
        effectivePosition = _lastPnPPosition!;
      }
    }

    // 5. Evaluate tracking confidence score & degradation level
    double confidenceScore = 0.95;
    TrackingConfidence confidenceLevel = TrackingConfidence.high;

    final motionJitter =
        math.sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ) - 9.81;
    if (motionJitter.abs() > 4.0) {
      confidenceScore -= 0.20;
    }

    if (_lastPnPPosition == null) {
      confidenceScore -= 0.25;
    }

    if (confidenceScore >= 0.75) {
      confidenceLevel = TrackingConfidence.high;
    } else if (confidenceScore >= 0.50) {
      confidenceLevel = TrackingConfidence.medium;
    } else if (confidenceScore >= 0.25) {
      confidenceLevel = TrackingConfidence.low;
    } else {
      confidenceLevel = TrackingConfidence.lost;
    }

    return FusedSpatialPose(
      position: effectivePosition,
      headingDegrees: _smoothHeading,
      pitchDegrees: _smoothPitch,
      rollDegrees: _smoothRoll,
      movementVectorX: movementX,
      movementVectorY: movementY,
      confidenceLevel: confidenceLevel,
      confidenceScore: confidenceScore,
      timestamp: DateTime.now(),
    );
  }
}
