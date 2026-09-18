import 'dart:async';
import '../engine/floor_tracker.dart';
import 'destinations.dart';

/// NavCore Backend API Hook Layer Specification
/// Provides REST / GraphQL abstraction for fetching building floor plans & shop POIs.

class MallApiShopFilter {
  final String buildingId;
  final int floorNumber;
  final double userLatitude;
  final double userLongitude;
  final double radiusMeters;

  const MallApiShopFilter({
    required this.buildingId,
    required this.floorNumber,
    required this.userLatitude,
    required this.userLongitude,
    this.radiusMeters = 500.0,
  });
}

abstract class MallBackendApi {
  Future<BuildingElevationProfile> fetchBuildingProfile(String buildingId);
  Future<List<DestinationPOI>> fetchShopsForFloor(MallApiShopFilter filter);
}

/// Production REST API Implementation with Local Fallback Hook
class RestMallBackendApi implements MallBackendApi {
  final String baseUrl;
  final bool useMockFallback;

  RestMallBackendApi({
    this.baseUrl = 'https://api.navcore.io/v1',
    this.useMockFallback = true,
  });

  @override
  Future<BuildingElevationProfile> fetchBuildingProfile(String buildingId) async {
    if (useMockFallback) {
      await Future.delayed(const Duration(milliseconds: 100));
      return defaultBuildingProfile;
    }
    // Production REST API Hook:
    // final response = await http.get(Uri.parse('$baseUrl/buildings/$buildingId'));
    // return BuildingElevationProfile.fromJson(jsonDecode(response.body));
    return defaultBuildingProfile;
  }

  @override
  Future<List<DestinationPOI>> fetchShopsForFloor(MallApiShopFilter filter) async {
    if (useMockFallback) {
      await Future.delayed(const Duration(milliseconds: 80));
      return mockDestinations
          .where((poi) => poi.floorNumber == filter.floorNumber)
          .toList();
    }
    // Production REST API Hook:
    // final response = await http.get(Uri.parse(
    //   '$baseUrl/shops?buildingId=${filter.buildingId}&floor=${filter.floorNumber}&lat=${filter.userLatitude}&lon=${filter.userLongitude}&radius=${filter.radiusMeters}'
    // ));
    // return (jsonDecode(response.body) as List).map((e) => DestinationPOI.fromJson(e)).toList();
    return mockDestinations
        .where((poi) => poi.floorNumber == filter.floorNumber)
        .toList();
  }
}
