import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/floor_tracker.dart';
import '../engine/ecef_engine.dart';
import '../data/destinations.dart';
import 'shop_details_screen.dart';
import 'dpad_control_widget.dart';

class FloorPlanScreen extends StatefulWidget {
  final BuildingElevationProfile buildingProfile;
  final FloorLevelConfig currentFloor;
  final ValueChanged<FloorLevelConfig> onSelectFloor;
  final GeodeticCoords userCoords;
  final List<DestinationPOI> destinations;
  final Function(double, double) onSimulateMove;
  final Function(DestinationPOI)? onSelectDestination;

  const FloorPlanScreen({
    super.key,
    required this.buildingProfile,
    required this.currentFloor,
    required this.onSelectFloor,
    required this.userCoords,
    required this.destinations,
    required this.onSimulateMove,
    this.onSelectDestination,
  });

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  DestinationPOI? _selectedPOI;

  @override
  Widget build(BuildContext context) {
    final currentFloorPOIs = widget.destinations
        .where((poi) => poi.floorNumber == widget.currentFloor.floorNumber)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const Icon(LucideIcons.layers, color: Color(0xFF2563EB), size: 20),
            const SizedBox(width: 8),
            Text(
              '2D Spatial Floor Map',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () => _showFloorDirectoryModal(context, currentFloorPOIs),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.store, color: Color(0xFF2563EB), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${currentFloorPOIs.length} Shops & Services',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Floor Level Selector Bar
          Container(
            height: 52,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.buildingProfile.floors.length,
              itemBuilder: (context, idx) {
                final floor = widget.buildingProfile.floors[idx];
                final isSelected = floor.floorNumber == widget.currentFloor.floorNumber;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPOI = null);
                    widget.onSelectFloor(floor);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'F${floor.floorNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${floor.absoluteHeightMeters.toStringAsFixed(0)}m)',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Map Canvas + Pins Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    return Stack(
                      children: [
                        // Architectural Custom Floor Canvas
                        CustomPaint(
                          size: Size(width, height),
                          painter: ArchitecturalFloorPainter(
                            floorNumber: widget.currentFloor.floorNumber,
                            floorName: widget.currentFloor.name,
                            selectedPOI: _selectedPOI,
                          ),
                        ),

                        // Render Interactive POI Pins over Floor Plan
                        ...currentFloorPOIs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final poi = entry.value;

                          // Compute 2D Canvas Position for POI
                          final pos = _getRoomPositionForIndex(idx, currentFloorPOIs.length, width, height);

                          final isSelected = _selectedPOI?.id == poi.id;

                          return Positioned(
                            left: (pos.dx - 45).clamp(10.0, width - 100.0),
                            top: (pos.dy - 20).clamp(10.0, height - 60.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPOI = poi;
                                });
                                _showStoreDetailsModal(context, poi);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 90,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : const Color(0xFF2563EB),
                                    width: isSelected ? 2 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.4) : Colors.black12,
                                      blurRadius: isSelected ? 8 : 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getCategoryIcon(poi.category),
                                      size: 14,
                                      color: isSelected ? Colors.white : const Color(0xFF2563EB),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      poi.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        // Dynamic User Location Position Calculation on 2D Canvas
                        () {
                          const double centerLat = 6.927079;
                          const double centerLon = 79.845612;
                          const double pixelsPerDegLat = 800000.0;
                          const double pixelsPerDegLon = 800000.0;

                          final double deltaLat = widget.userCoords.latitude - centerLat;
                          final double deltaLon = widget.userCoords.longitude - centerLon;

                          final double rawUserX = (width / 2) + (deltaLon * pixelsPerDegLon);
                          final double rawUserY = (height / 2) - (deltaLat * pixelsPerDegLat);

                          final double userX = rawUserX.clamp(20.0, width - 20.0);
                          final double userY = rawUserY.clamp(20.0, height - 20.0);

                          return Positioned(
                            left: userX - 14,
                            top: userY - 14,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black26, blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }(),

                        // Map Legend Overlay (Top Left - Cleanly placed above room blocks)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.compass, color: Color(0xFF2563EB), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  widget.currentFloor.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Interactive Collapsible D-Pad Simulation Controls Overlay (Bottom Right)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: DpadControlWidget(
                            onSimulateMove: widget.onSimulateMove,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFloorDirectoryModal(BuildContext context, List<DestinationPOI> pois) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.store, color: Color(0xFF2563EB), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Floor Directory (${widget.currentFloor.name})',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pois.length} Locations',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pois.isEmpty
                  ? Center(
                      child: Text(
                        'No shops or services listed on this floor.',
                        style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: pois.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final poi = pois[idx];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getCategoryIcon(poi.category),
                                  color: const Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      poi.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      '${poi.category} • ${poi.rating} ★',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() => _selectedPOI = poi);
                                  _showStoreDetailsModal(context, poi);
                                },
                                child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreDetailsModal(BuildContext context, DestinationPOI poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShopDetailsScreen(
        destination: poi,
        userCoords: widget.userCoords,
        onStartARNavigation: () {
          Navigator.pop(context);
          if (widget.onSelectDestination != null) {
            widget.onSelectDestination!(poi);
          }
        },
      ),
    );
  }

  Offset _getRoomPositionForIndex(int index, int total, double width, double height) {
    const roomTopPadding = 56.0;
    final availableHeight = height - roomTopPadding - 24.0;
    final roomH = availableHeight * 0.28;
    final gapY = (availableHeight - (roomH * 3)) / 2;

    final r1Y = roomTopPadding + roomH / 2;
    final r2Y = roomTopPadding + roomH + gapY + roomH / 2;
    final r3Y = roomTopPadding + (roomH + gapY) * 2 + roomH / 2;

    final slots = [
      Offset(width * 0.20, r1Y),
      Offset(width * 0.81, r1Y),
      Offset(width * 0.20, r2Y),
      Offset(width * 0.81, r2Y),
      Offset(width * 0.20, r3Y),
      Offset(width * 0.81, r3Y),
      Offset(width * 0.50, 42),
      Offset(width * 0.50, height - 20),
    ];
    return slots[index % slots.length];
  }

  IconData _getCategoryIcon(String cat) {
    if (cat.contains('FOOD')) return LucideIcons.utensils;
    if (cat.contains('TECH')) return LucideIcons.laptop;
    if (cat.contains('FASHION') || cat.contains('RETAIL')) return LucideIcons.shoppingBag;
    if (cat.contains('LUXURY') || cat.contains('BEAUTY')) return LucideIcons.sparkles;
    if (cat.contains('ENTERTAINMENT')) return LucideIcons.film;
    return LucideIcons.mapPin;
  }
}

class ArchitecturalFloorPainter extends CustomPainter {
  final int floorNumber;
  final String floorName;
  final DestinationPOI? selectedPOI;

  ArchitecturalFloorPainter({
    required this.floorNumber,
    required this.floorName,
    this.selectedPOI,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final outerBorderPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final wallFillPaint = Paint()..color = const Color(0xFFE2E8F0);

    // 1. Draw Outer Building Boundary Wall
    final outerRect = RRect.fromLTRBR(16, 16, size.width - 16, size.height - 16, const Radius.circular(24));
    canvas.drawRRect(outerRect, wallFillPaint);
    canvas.drawRRect(outerRect, outerBorderPaint);

    // 2. Draw Central Walking Corridor & Atrium
    final corridorPaint = Paint()..color = Colors.white;
    const roomTopPadding = 56.0;
    final corridorRect = RRect.fromLTRBR(size.width * 0.38, roomTopPadding, size.width * 0.62, size.height - 24, const Radius.circular(16));
    canvas.drawRRect(corridorRect, corridorPaint);

    final corridorBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(corridorRect, corridorBorderPaint);

    // 3. Draw Room Blocks (Left & Right Wings) - Top Padding 56.0 preserves clear space for Top-Left Legend Badge
    final roomColors = [
      const Color(0xFFEFF6FF), // Soft Blue
      const Color(0xFFFDF2F8), // Soft Pink
      const Color(0xFFFEF3C7), // Soft Amber
      const Color(0xFFF0FDF4), // Soft Green
    ];

    final roomBorderPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final availableHeight = size.height - roomTopPadding - 24.0;
    final roomH = availableHeight * 0.28;
    final gapY = (availableHeight - (roomH * 3)) / 2;

    final roomBoxes = [
      // Left Wing Rooms
      Rect.fromLTWH(24, roomTopPadding, size.width * 0.32, roomH),
      Rect.fromLTWH(24, roomTopPadding + roomH + gapY, size.width * 0.32, roomH),
      Rect.fromLTWH(24, roomTopPadding + (roomH + gapY) * 2, size.width * 0.32, roomH),
      // Right Wing Rooms
      Rect.fromLTWH(size.width * 0.66, roomTopPadding, size.width * 0.30, roomH),
      Rect.fromLTWH(size.width * 0.66, roomTopPadding + roomH + gapY, size.width * 0.30, roomH),
      Rect.fromLTWH(size.width * 0.66, roomTopPadding + (roomH + gapY) * 2, size.width * 0.30, roomH),
    ];

    for (int i = 0; i < roomBoxes.length; i++) {
      final rect = roomBoxes[i];
      final fillPaint = Paint()..color = roomColors[i % roomColors.length];
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), fillPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), roomBorderPaint);

      // Draw Room Number Code
      final roomCode = '#${floorNumber}0${i + 1}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: roomCode,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left + 8, rect.top + 8));
    }

    // 4. Draw Escalators & Elevator Hub
    final facilityPaint = Paint()..color = const Color(0xFFE0F2FE);
    final elevRect = Rect.fromLTWH(size.width * 0.42, 22, size.width * 0.16, 26);
    canvas.drawRRect(RRect.fromRectAndRadius(elevRect, const Radius.circular(8)), facilityPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(elevRect, const Radius.circular(8)), roomBorderPaint);

    final elevPainter = TextPainter(
      text: const TextSpan(
        text: 'ELEVATOR',
        style: TextStyle(color: Color(0xFF0369A1), fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    elevPainter.layout();
    elevPainter.paint(canvas, Offset(elevRect.left + 6, elevRect.top + 7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

