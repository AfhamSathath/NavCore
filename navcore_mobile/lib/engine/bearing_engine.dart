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
/// Uses user GPS when within valid proximity, or anchors to the Earth ground floor entrance anchor.
GeodeticCoords getEffectiveUserCoords(GeodeticCoords userCoords, GeodeticCoords mallAnchor) {
  final latDiff = (userCoords.latitude - mallAnchor.latitude).abs();
  final lonDiff = (userCoords.longitude - mallAnchor.longitude).abs();

  if (userCoords.latitude != 0.0 &&
      userCoords.longitude != 0.0 &&
      latDiff < 0.05 &&
      lonDiff < 0.05) {
    return userCoords;
  }

  return GeodeticCoords(
    latitude: mallAnchor.latitude,
    longitude: mallAnchor.longitude,
    height: mallAnchor.height,
  );
}

/// Calculates accurate 3D spatial distance in meters incorporating WGS-84 ECEF
/// Cartesian Euclidean geometry and floor elevation differences relative to Earth ground floor.
double calculateAccurate3DDistance(
  GeodeticCoords userCoords,
  GeodeticCoords targetLocation, {
  int userFloorNumber = 1,
  int targetFloorNumber = 1,
  double heightPerFloorMeters = 4.5,
}) {
  final userEffectiveHeight = userCoords.height + (userFloorNumber - 1) * heightPerFloorMeters;
  final targetEffectiveHeight = targetLocation.height + (targetFloorNumber - 1) * heightPerFloorMeters;

  final userPoint = GeodeticCoords(
    latitude: userCoords.latitude,
    longitude: userCoords.longitude,
    height: userEffectiveHeight,
  );

  final targetPoint = GeodeticCoords(
    latitude: targetLocation.latitude,
    longitude: targetLocation.longitude,
    height: targetEffectiveHeight,
  );

  final p1 = geodeticToECEF(userPoint);
  final p2 = geodeticToECEF(targetPoint);

  return ecefDistance(p1, p2);
}

/// Calculates precise 3D geometric distance of a place/POI from the Earth ground floor (Floor 1 Entrance level)
/// using WGS-84 ECEF 3D Cartesian Euclidean coordinate geometry.
double calculateDistanceFromEarthGround(
  GeodeticCoords targetLocation, {
  int targetFloorNumber = 1,
  double groundElevationMeters = 45.0,
  GeodeticCoords? groundAnchorCoords,
  double heightPerFloorMeters = 4.5,
}) {
  final groundAnchor = groundAnchorCoords ??
      GeodeticCoords(
        latitude: targetLocation.latitude,
        longitude: targetLocation.longitude,
        height: groundElevationMeters,
      );

  final groundBasePoint = GeodeticCoords(
    latitude: groundAnchor.latitude,
    longitude: groundAnchor.longitude,
    height: groundElevationMeters,
  );

  final targetElevatedHeight = groundElevationMeters + (targetFloorNumber - 1) * heightPerFloorMeters;
  final targetPoint = GeodeticCoords(
    latitude: targetLocation.latitude,
    longitude: targetLocation.longitude,
    height: targetElevatedHeight,
  );

  final pGround = geodeticToECEF(groundBasePoint);
  final pTarget = geodeticToECEF(targetPoint);

  return ecefDistance(pGround, pTarget);
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
