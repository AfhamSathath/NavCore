import 'dart:convert';
import '../engine/ecef_engine.dart';
import '../engine/floor_tracker.dart';
import 'destinations.dart';

class BuildingConfig {
  final String buildingId;
  final String name;
  final String city;
  final GeodeticCoords centerAnchor;
  final List<FloorLevelConfig> floors;
  final List<DestinationPOI> pois;
  final List<ReferenceMarker> markers;

  const BuildingConfig({
    required this.buildingId,
    required this.name,
    required this.city,
    required this.centerAnchor,
    required this.floors,
    required this.pois,
    required this.markers,
  });
}

class ReferenceMarker {
  final String markerId;
  final String name;
  final int floorNumber;
  final GeodeticCoords position;
  final double physicalWidthMeters;
  final double physicalHeightMeters;
  final String qrCodeData;

  const ReferenceMarker({
    required this.markerId,
    required this.name,
    required this.floorNumber,
    required this.position,
    required this.physicalWidthMeters,
    required this.physicalHeightMeters,
    required this.qrCodeData,
  });
}

class BuildingDataService {
  BuildingConfig? _cachedConfig;

  Future<BuildingConfig> loadBuildingConfig({
    String buildingId = 'mall-one-galle-face',
  }) async {
    if (_cachedConfig != null && _cachedConfig!.buildingId == buildingId) {
      return _cachedConfig!;
    }

    // Default high-precision indoor building configuration
    _cachedConfig = BuildingConfig(
      buildingId: buildingId,
      name: 'One Galle Face Mall & Tower',
      city: 'Colombo',
      centerAnchor: const GeodeticCoords(
        latitude: 6.927079,
        longitude: 79.845612,
        height: 10.0,
      ),
      floors: const [
        FloorLevelConfig(
          floorId: 'flr-01',
          floorNumber: 1,
          name: 'Ground Floor & Ceylon Atrium',
          relativeVectorMeters: 0.0,
          absoluteHeightMeters: 45.0,
          bandMinMeters: 43.0,
          bandMaxMeters: 47.5,
          storesCount: 14,
        ),
        FloorLevelConfig(
          floorId: 'flr-02',
          floorNumber: 2,
          name: 'Level 2 - Fashion & Designer Apparel',
          relativeVectorMeters: 5.0,
          absoluteHeightMeters: 50.0,
          bandMinMeters: 47.5,
          bandMaxMeters: 52.5,
          storesCount: 18,
        ),
        FloorLevelConfig(
          floorId: 'flr-03',
          floorNumber: 3,
          name: 'Level 3 - Tech & Electronics Hub',
          relativeVectorMeters: 10.0,
          absoluteHeightMeters: 55.0,
          bandMinMeters: 52.5,
          bandMaxMeters: 57.5,
          storesCount: 12,
        ),
        FloorLevelConfig(
          floorId: 'flr-04',
          floorNumber: 4,
          name: 'Level 4 - Ceylon Gems & Gold Jewelry',
          relativeVectorMeters: 15.0,
          absoluteHeightMeters: 60.0,
          bandMinMeters: 57.5,
          bandMaxMeters: 62.5,
          storesCount: 16,
        ),
        FloorLevelConfig(
          floorId: 'flr-05',
          floorNumber: 5,
          name: 'Level 5 - Food Studio & Ceylon Dining',
          relativeVectorMeters: 20.0,
          absoluteHeightMeters: 65.0,
          bandMinMeters: 62.5,
          bandMaxMeters: 67.5,
          storesCount: 22,
        ),
        FloorLevelConfig(
          floorId: 'flr-06',
          floorNumber: 6,
          name: 'Level 6 - Scope IMAX Cinema & Entertainment',
          relativeVectorMeters: 25.0,
          absoluteHeightMeters: 70.0,
          bandMinMeters: 67.5,
          bandMaxMeters: 72.5,
          storesCount: 8,
        ),
        FloorLevelConfig(
          floorId: 'flr-07',
          floorNumber: 7,
          name: 'Level 7 - Tech Innovation & Enterprise',
          relativeVectorMeters: 30.0,
          absoluteHeightMeters: 75.0,
          bandMinMeters: 72.5,
          bandMaxMeters: 77.5,
          storesCount: 10,
        ),
        FloorLevelConfig(
          floorId: 'flr-08',
          floorNumber: 8,
          name: 'Level 8 - Priority Banking & Corporate',
          relativeVectorMeters: 35.0,
          absoluteHeightMeters: 80.0,
          bandMinMeters: 77.5,
          bandMaxMeters: 82.5,
          storesCount: 10,
        ),
        FloorLevelConfig(
          floorId: 'flr-09',
          floorNumber: 9,
          name: 'Level 9 - VIP Gemology & Ocean Suites',
          relativeVectorMeters: 40.0,
          absoluteHeightMeters: 85.0,
          bandMinMeters: 82.5,
          bandMaxMeters: 87.5,
          storesCount: 6,
        ),
        FloorLevelConfig(
          floorId: 'flr-10',
          floorNumber: 10,
          name: 'Level 10 - Sunset Sky Lounge & Helipad',
          relativeVectorMeters: 45.0,
          absoluteHeightMeters: 90.0,
          bandMinMeters: 87.5,
          bandMaxMeters: 95.0,
          storesCount: 4,
        ),
      ],
      pois: mockDestinations,
      markers: [
        const ReferenceMarker(
          markerId: 'REF-ENTRANCE-G1',
          name: 'Main Grand Entrance Gate 1',
          floorNumber: 1,
          position: GeodeticCoords(
            latitude: 6.927079,
            longitude: 79.845612,
            height: 10.0,
          ),
          physicalWidthMeters: 0.25,
          physicalHeightMeters: 0.25,
          qrCodeData: 'NexNav:REF-ENTRANCE-G1:6.927079:79.845612:10.0',
        ),
        const ReferenceMarker(
          markerId: 'REF-NORTH-ELEVATOR',
          name: 'North Tower Elevator Hall',
          floorNumber: 2,
          position: GeodeticCoords(
            latitude: 6.927150,
            longitude: 79.845700,
            height: 14.5,
          ),
          physicalWidthMeters: 0.25,
          physicalHeightMeters: 0.25,
          qrCodeData: 'NexNav:REF-NORTH-ELEVATOR:6.927150:79.845700:14.5',
        ),
      ],
    );

    return _cachedConfig!;
  }

  /// Exports building configuration to standalone JSON format for offline storage
  String exportConfigToJson(BuildingConfig config) {
    return jsonEncode({
      'buildingId': config.buildingId,
      'name': config.name,
      'city': config.city,
      'poiCount': config.pois.length,
      'markerCount': config.markers.length,
    });
  }
}
