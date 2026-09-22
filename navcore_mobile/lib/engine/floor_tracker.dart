/// NexNav Geodetic Elevation Engine & Floor Level Manager in Dart
/// Implements Section 4 of NexNav Technical Spec
library;

class FloorLevelConfig {
  final String floorId;
  final int floorNumber;
  final String name;
  final double relativeVectorMeters;
  final double absoluteHeightMeters;
  final double bandMinMeters;
  final double bandMaxMeters;
  final int storesCount;

  const FloorLevelConfig({
    required this.floorId,
    required this.floorNumber,
    required this.name,
    required this.relativeVectorMeters,
    required this.absoluteHeightMeters,
    required this.bandMinMeters,
    required this.bandMaxMeters,
    required this.storesCount,
  });
}

class BuildingElevationProfile {
  final String buildingId;
  final String name;
  final double entranceBaseAnchorHeight;
  final double floorGapMeters;
  final List<FloorLevelConfig> floors;

  const BuildingElevationProfile({
    required this.buildingId,
    required this.name,
    required this.entranceBaseAnchorHeight,
    required this.floorGapMeters,
    required this.floors,
  });
}

/// Default Reference Building Specification (One Galle Face Mall)
/// Section 4 Spec Data Model
final defaultBuildingProfile = BuildingElevationProfile(
  buildingId: 'mall-one-galle-face',
  name: 'One Galle Face Mall & Tower',
  entranceBaseAnchorHeight: 45.0,
  floorGapMeters: 5.0,
  floors: const [
    FloorLevelConfig(
      floorId: 'fl-b1',
      floorNumber: -1,
      name: 'B1 (Basement 1 Parking)',
      relativeVectorMeters: -5.0,
      absoluteHeightMeters: 40.0,
      bandMinMeters: 0.0,
      bandMaxMeters: 42.5,
      storesCount: 5,
    ),
    FloorLevelConfig(
      floorId: 'fl-1',
      floorNumber: 1,
      name: '1st (Ground / Main Entrance)',
      relativeVectorMeters: 0.0,
      absoluteHeightMeters: 45.0,
      bandMinMeters: 42.5,
      bandMaxMeters: 47.5,
      storesCount: 5,
    ),
    FloorLevelConfig(
      floorId: 'fl-2',
      floorNumber: 2,
      name: '2nd (Fashion & Retail Hall)',
      relativeVectorMeters: 5.0,
      absoluteHeightMeters: 50.0,
      bandMinMeters: 47.5,
      bandMaxMeters: 52.5,
      storesCount: 5,
    ),
    FloorLevelConfig(
      floorId: 'fl-3',
      floorNumber: 3,
      name: '3rd (Electronics & Innovation)',
      relativeVectorMeters: 10.0,
      absoluteHeightMeters: 55.0,
      bandMinMeters: 52.5,
      bandMaxMeters: 57.5,
      storesCount: 5,
    ),
    FloorLevelConfig(
      floorId: 'fl-4',
      floorNumber: 4,
      name: '4th (Food Court & Dining)',
      relativeVectorMeters: 15.0,
      absoluteHeightMeters: 60.0,
      bandMinMeters: 57.5,
      bandMaxMeters: 200.0,
      storesCount: 5,
    ),
  ],
);

/// Automatically computes floor level matching absolute height
FloorLevelConfig resolveFloorByHeight(
  double currentHeightMeters, [
  BuildingElevationProfile? profile,
]) {
  final targetProfile = profile ?? defaultBuildingProfile;

  for (final floor in targetProfile.floors) {
    if (currentHeightMeters >= floor.bandMinMeters &&
        currentHeightMeters < floor.bandMaxMeters) {
      return floor;
    }
  }

  // Safe fallback to Ground Floor (floorNumber == 1) for outdoor / uncalibrated altitude
  return targetProfile.floors.firstWhere(
    (f) => f.floorNumber == 1,
    orElse: () => targetProfile.floors.first,
  );
}
