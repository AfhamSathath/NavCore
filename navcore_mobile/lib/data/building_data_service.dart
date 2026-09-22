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
          floorId: 'flr-b1',
          floorNumber: -1,
          name: 'B1 (Basement 1 Parking)',
          relativeVectorMeters: -5.0,
          absoluteHeightMeters: 40.0,
          bandMinMeters: 0.0,
          bandMaxMeters: 42.5,
          storesCount: 5,
        ),
        FloorLevelConfig(
          floorId: 'flr-01',
          floorNumber: 1,
          name: 'Ground Floor & Ceylon Atrium',
          relativeVectorMeters: 0.0,
          absoluteHeightMeters: 45.0,
          bandMinMeters: 42.5,
          bandMaxMeters: 47.5,
          storesCount: 5,
        ),
        FloorLevelConfig(
          floorId: 'flr-02',
          floorNumber: 2,
          name: 'Level 2 - Fashion & Designer Apparel',
          relativeVectorMeters: 5.0,
          absoluteHeightMeters: 50.0,
          bandMinMeters: 47.5,
          bandMaxMeters: 52.5,
          storesCount: 5,
        ),
        FloorLevelConfig(
          floorId: 'flr-03',
          floorNumber: 3,
          name: 'Level 3 - Tech & Electronics Hub',
          relativeVectorMeters: 10.0,
          absoluteHeightMeters: 55.0,
          bandMinMeters: 52.5,
          bandMaxMeters: 57.5,
          storesCount: 5,
        ),
        FloorLevelConfig(
          floorId: 'flr-04',
          floorNumber: 4,
          name: 'Level 4 - Food Studio & Ceylon Dining',
          relativeVectorMeters: 15.0,
          absoluteHeightMeters: 60.0,
          bandMinMeters: 57.5,
          bandMaxMeters: 200.0,
          storesCount: 5,
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
