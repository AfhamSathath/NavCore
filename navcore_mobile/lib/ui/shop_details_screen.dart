import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/destinations.dart';
import '../engine/ecef_engine.dart';
import '../engine/bearing_engine.dart';
import '../engine/floor_tracker.dart';

class ShopDetailsScreen extends StatelessWidget {
  final DestinationPOI destination;
  final GeodeticCoords userCoords;
  final VoidCallback onStartARNavigation;

  const ShopDetailsScreen({
    super.key,
    required this.destination,
    required this.userCoords,
    required this.onStartARNavigation,
  });

  @override
  Widget build(BuildContext context) {
    final activeAnchor = destination.location;
    final effectiveCoords = getEffectiveUserCoords(userCoords, activeAnchor);
    final userFloor = resolveFloorByHeight(userCoords.height);
    final distanceMeters = calculateAccurate3DDistance(
      effectiveCoords,
      destination.location,
      userFloorNumber: userFloor.floorNumber,
      targetFloorNumber: destination.floorNumber,
    );
    final distanceFromGroundMeters = calculateDistanceFromEarthGround(
      destination.location,
      targetFloorNumber: destination.floorNumber,
      groundElevationMeters: 45.0,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Icon(
                  _getCategoryIcon(destination.category),
                  size: 28,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'FLOOR ${destination.floorNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              destination.openStatus,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Specs Cards (3D Distance, Ground Floor Elevation, Rating)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSpecTile(
                      LucideIcons.mapPin,
                      'Distance',
                      '${distanceMeters.toStringAsFixed(0)} meters',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSpecTile(
                      LucideIcons.layers,
                      'Mall Floor',
                      'Floor ${destination.floorNumber} (${destination.location.height.toStringAsFixed(0)}m)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSpecTile(
                      LucideIcons.mountain,
                      'Ground Distance',
                      '${distanceFromGroundMeters.toStringAsFixed(0)}m from Ground',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSpecTile(
                      LucideIcons.star,
                      'Rating',
                      '${destination.rating} ★★★★★',
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Description
          const Text(
            'About this Store',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            destination.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onStartARNavigation,
              icon: const Icon(LucideIcons.compass, size: 20),
              label: const Text(
                'Start Camera AR Navigation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD & DRINK':
        return LucideIcons.utensils;
      case 'TECH & ELECTRONICS':
        return LucideIcons.smartphone;
      case 'RETAIL & FASHION':
      case 'LUXURY FASHION':
        return LucideIcons.shoppingBag;
      case 'FINE JEWELRY':
        return LucideIcons.watch;
      case 'ENTERTAINMENT':
        return LucideIcons.gamepad2;
      default:
        return LucideIcons.store;
    }
  }
}
