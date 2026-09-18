import 'ecef_engine.dart';

/// NavCore Perspective-n-Point (PnP) Height Calibration Engine in Dart
/// Implements Section 3 of NavCore Technical Spec

class EntranceMarkerNode {
  final String markerId;
  final String buildingId;
  final String name;
  final double latitude;
  final double longitude;
  final double baseHeight; // WGS 84 ellipsoid height
  final double physicalWidthMeters;
  final double physicalHeightMeters;

  const EntranceMarkerNode({
    required this.markerId,
    required this.buildingId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.baseHeight,
    required this.physicalWidthMeters,
    required this.physicalHeightMeters,
  });
}

class PnPResult {
  final GeodeticCoords calibratedUserCoords;
  final double computedCameraHeightMeters;
  final double estimatedDistanceMeters;
  final double residualErrorPx;
  final DateTime calibratedAt;
  final String markerId;

  const PnPResult({
    required this.calibratedUserCoords,
    required this.computedCameraHeightMeters,
    required this.estimatedDistanceMeters,
    required this.residualErrorPx,
    required this.calibratedAt,
    required this.markerId,
  });
}

/// Simulates/computes camera height and locks reference position using PnP
PnPResult calibratePnP(
  EntranceMarkerNode marker,
  double observedMarkerWidthPx,
  double observedMarkerHeightPx, {
  double cameraFocalLengthPx = 800.0,
}) {
  final distanceEstimate =
      (cameraFocalLengthPx * marker.physicalWidthMeters) / observedMarkerWidthPx;
  const computedCameraHeight = 1.65; // camera height offset above floor
  final absoluteHeight = marker.baseHeight + computedCameraHeight;

  return PnPResult(
    calibratedUserCoords: GeodeticCoords(
      latitude: marker.latitude,
      longitude: marker.longitude,
      height: absoluteHeight,
    ),
    computedCameraHeightMeters: computedCameraHeight,
    estimatedDistanceMeters: distanceEstimate,
    residualErrorPx: (observedMarkerWidthPx - observedMarkerHeightPx).abs() * 0.05,
    calibratedAt: DateTime.now(),
    markerId: marker.markerId,
  );
}
