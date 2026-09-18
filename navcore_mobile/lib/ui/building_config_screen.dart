import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/floor_tracker.dart';

class BuildingConfigScreen extends StatelessWidget {
  final BuildingElevationProfile profile;

  const BuildingConfigScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Building Geodetic Elevation Config',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Base Anchor Height: ${profile.entranceBaseAnchorHeight}m WGS84 | Gap: ${profile.floorGapMeters}m',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'MAPPED GEODETIC ELEVATION BANDS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          ...profile.floors.map((floor) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      'F${floor.floorNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                  title: Text(floor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    'Band: ${floor.bandMinMeters.toStringAsFixed(1)}m – ${floor.bandMaxMeters.toStringAsFixed(1)}m',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    '${floor.absoluteHeightMeters.toStringAsFixed(1)}m',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
