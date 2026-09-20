import 'dart:math';
import 'ecef_engine.dart';

/// NavCore Bearing & AR Spatial Placement Engine in Dart
/// Implements Section 5 of NavCore Technical Spec

// ignore: constant_identifier_names
enum CompassBearingBadge { N, NE, E, SE, S, SW, W, NW }

const double earthRadiusMeters = 6371000.0; // Mean Earth radius in meters

/// Calculates Horizontal Haversine Distance between two geodetic points
double haversineDistance(GeodeticCoords user, GeodeticCoords target) {
  final phi1 = (user.latitude * pi) / 180.0;
  final phi2 = (target.latitude * pi) / 180.0;
  final deltaPhi = ((target.latitude - user.latitude) * pi) / 180.0;
  final deltaLambda = ((target.longitude - user.longitude) * pi) / 180.0;

  final a =
      sin(deltaPhi / 2.0) * sin(deltaPhi / 2.0) +
      cos(phi1) * cos(phi2) * sin(deltaLambda / 2.0) * sin(deltaLambda / 2.0);

  final c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
  return earthRadiusMeters * c;
}

/// Calculates forward azimuth / compass bearing angle (0° - 360°)
double calculateBearingAngle(GeodeticCoords user, GeodeticCoords target) {
  final phiUser = (user.latitude * pi) / 180.0;
  final phiTarget = (target.latitude * pi) / 180.0;
  final deltaLambda = ((target.longitude - user.longitude) * pi) / 180.0;

  final y = sin(deltaLambda) * cos(phiTarget);
  final x =
      cos(phiUser) * sin(phiTarget) -
      sin(phiUser) * cos(phiTarget) * cos(deltaLambda);

  final bearingRad = atan2(y, x);
  final bearingDeg = (bearingRad * 180.0) / pi;

  return (bearingDeg + 360.0) % 360.0;
}

/// Classifies compass bearing angle into 8-point compass badges using 45° windows
CompassBearingBadge classifyCompassBadge(double bearingDeg) {
  final normalized = (bearingDeg + 360.0) % 360.0;

  if (normalized >= 337.5 || normalized < 22.5) return CompassBearingBadge.N;
  if (normalized >= 22.5 && normalized < 67.5) return CompassBearingBadge.NE;
  if (normalized >= 67.5 && normalized < 112.5) return CompassBearingBadge.E;
  if (normalized >= 112.5 && normalized < 157.5) return CompassBearingBadge.SE;
  if (normalized >= 157.5 && normalized < 202.5) return CompassBearingBadge.S;
  if (normalized >= 202.5 && normalized < 247.5) return CompassBearingBadge.SW;
  if (normalized >= 247.5 && normalized < 292.5) return CompassBearingBadge.W;
  return CompassBearingBadge.NW;
}

/// Resolves localized user coordinates relative to active indoor mall coordinate anchor.
/// Removes raw indoor GPS coordinate fluctuations by anchoring all spatial calculations to the indoor mall reference anchor.
GeodeticCoords getEffectiveUserCoords(GeodeticCoords userCoords, GeodeticCoords mallAnchor) {
  // Always anchor user position calculation to the indoor mall reference anchor
  // to avoid raw indoor GPS drift & coordinate jumps.
  return GeodeticCoords(
    latitude: mallAnchor.latitude,
    longitude: mallAnchor.longitude,
    height: userCoords.height,
  );
}

/// Calculates accurate 3D spatial distance in meters incorporating 2D surface distance,
/// Earth level WGS-84 height, and floor elevation difference.
double calculateAccurate3DDistance(
  GeodeticCoords userCoords,
  GeodeticCoords targetLocation, {
  int userFloorNumber = 1,
  int targetFloorNumber = 1,
  double heightPerFloorMeters = 4.5,
}) {
  final d2d = haversineDistance(userCoords, targetLocation);
  final heightDiff = (targetLocation.height - userCoords.height).abs();

  final verticalDistM = heightDiff > 0.05
      ? heightDiff
      : (targetFloorNumber - userFloorNumber).abs() * heightPerFloorMeters;

  return sqrt(d2d * d2d + verticalDistM * verticalDistM);
}

/// Calculates distance of a place/POI from the Earth ground floor (main entrance level) of a particular mall
double calculateDistanceFromEarthGround(
  GeodeticCoords targetLocation, {
  int targetFloorNumber = 1,
  double groundElevationMeters = 45.0,
  GeodeticCoords? groundAnchorCoords,
  double heightPerFloorMeters = 4.5,
}) {
  final baseCoords = groundAnchorCoords ??
      GeodeticCoords(
        latitude: targetLocation.latitude,
        longitude: targetLocation.longitude,
        height: groundElevationMeters,
      );

  final d2d = haversineDistance(baseCoords, targetLocation);
  final heightDiff = (targetLocation.height - groundElevationMeters).abs();

  final verticalDistM = heightDiff > 0.05
      ? heightDiff
      : ((targetFloorNumber - 1) * heightPerFloorMeters).toDouble();

  return sqrt(d2d * d2d + verticalDistM * verticalDistM);
}

/// Calculates AR Card Vertical Placement (Pixel_Y_Offset) over camera viewport
/// Section 5 Formula:
/// Pixel_Y_Offset = Viewport_Center_Y + (Focal_Length * (Δh / Horizontal_Haversine_Distance))
double calculateARYOffset(
  GeodeticCoords user,
  GeodeticCoords target,
  double viewportCenterY, {
  double focalLength = 800.0,
}) {
  final horizontalDist = max(haversineDistance(user, target), 0.5);
  final deltaHeight = target.height - user.height;

  return viewportCenterY + focalLength * (deltaHeight / horizontalDist);
}
