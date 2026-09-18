import 'dart:math' as math;
import 'ecef_engine.dart';
import 'bearing_engine.dart';
import 'route_service.dart';

class OffRouteCheckResult {
  final bool isOffRoute;
  final bool isWrongDirection;
  final double deviationMeters;
  final String statusMessage;

  const OffRouteCheckResult({
    required this.isOffRoute,
    required this.isWrongDirection,
    required this.deviationMeters,
    required this.statusMessage,
  });
}

/// NavCore OffRouteService: Monitors corridor boundaries and user walking vector
class OffRouteService {
  final double corridorThresholdMeters = 6.0; // Max allowed distance from route segment
  final double wrongDirectionThresholdDeg = 135.0; // Walking angle away from target

  OffRouteCheckResult evaluateRouteCompliance({
    required GeodeticCoords userCoords,
    required double userHeading,
    required RoutePath activeRoute,
    required int currentWaypointIndex,
  }) {
    if (activeRoute.waypoints.isEmpty) {
      return const OffRouteCheckResult(
        isOffRoute: false,
        isWrongDirection: false,
        deviationMeters: 0.0,
        statusMessage: 'On Route',
      );
    }

    final targetWaypoint = activeRoute.waypoints[
      math.min(currentWaypointIndex, activeRoute.waypoints.length - 1)
    ];

    final distToTarget = calculateAccurate3DDistance(
      userCoords,
      targetWaypoint.coords,
      targetFloorNumber: targetWaypoint.floorNumber,
    );
    final targetBearing = calculateBearingAngle(userCoords, targetWaypoint.coords);

    // Compute relative angle between user heading and target bearing
    double headingDiff = (targetBearing - userHeading).abs();
    while (headingDiff > 180) {
      headingDiff = (360 - headingDiff).abs();
    }

    // Check wrong direction (walking away from destination)
    bool wrongDir = headingDiff > wrongDirectionThresholdDeg;

    // Check off route corridor deviation
    bool offRoute = distToTarget > 35.0 && headingDiff > 90.0;

    String message = 'On Route';
    if (wrongDir) {
      message = 'Wrong Direction! Turn Around';
    } else if (offRoute) {
      message = "You're off route. Recalculating...";
    }

    return OffRouteCheckResult(
      isOffRoute: offRoute,
      isWrongDirection: wrongDir,
      deviationMeters: distToTarget,
      statusMessage: message,
    );
  }
}
