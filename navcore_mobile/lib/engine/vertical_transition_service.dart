import 'route_service.dart';

enum VerticalTransitionStage {
  approaching,
  atTransition,
  inTransition,
  completed,
}

class TransitionStateUpdate {
  final VerticalTransitionStage stage;
  final WaypointType transitionType;
  final int targetFloor;
  final String instructionTitle;
  final String instructionSubtitle;

  const TransitionStateUpdate({
    required this.stage,
    required this.transitionType,
    required this.targetFloor,
    required this.instructionTitle,
    required this.instructionSubtitle,
  });
}

/// NexNav VerticalTransitionService: Manages multi-floor Elevator, Escalator & Stairs transitions
class VerticalTransitionService {
  TransitionStateUpdate evaluateTransitionStep({
    required double distanceToTransitionMeters,
    required WaypointType transitionType,
    required int currentFloor,
    required int targetFloor,
  }) {
    final String typeName = (transitionType == WaypointType.escalator)
        ? 'Escalator'
        : (transitionType == WaypointType.stairs ? 'Stairs' : 'Elevator');

    if (distanceToTransitionMeters > 15.0) {
      return TransitionStateUpdate(
        stage: VerticalTransitionStage.approaching,
        transitionType: transitionType,
        targetFloor: targetFloor,
        instructionTitle: 'Continue to $typeName',
        instructionSubtitle:
            '$typeName Ahead • ${distanceToTransitionMeters.round()} m',
      );
    } else if (distanceToTransitionMeters > 4.0) {
      return TransitionStateUpdate(
        stage: VerticalTransitionStage.atTransition,
        transitionType: transitionType,
        targetFloor: targetFloor,
        instructionTitle:
            '$typeName Ahead (${distanceToTransitionMeters.round()} m)',
        instructionSubtitle: 'Prepare to change floors',
      );
    } else if (distanceToTransitionMeters > 1.0) {
      final String actionStr = (transitionType == WaypointType.escalator)
          ? 'Take Escalator to Level $targetFloor'
          : (transitionType == WaypointType.stairs
                ? 'Use Stairs to Level $targetFloor'
                : 'Enter Elevator & Select Floor $targetFloor');

      return TransitionStateUpdate(
        stage: VerticalTransitionStage.inTransition,
        transitionType: transitionType,
        targetFloor: targetFloor,
        instructionTitle: actionStr,
        instructionSubtitle: 'Floor Transition in Progress...',
      );
    } else {
      return TransitionStateUpdate(
        stage: VerticalTransitionStage.completed,
        transitionType: transitionType,
        targetFloor: targetFloor,
        instructionTitle: 'Floor $targetFloor Navigation Activated',
        instructionSubtitle: 'Arrived at Floor $targetFloor',
      );
    }
  }
}
