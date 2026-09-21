import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/floor_tracker.dart';
import '../engine/ecef_engine.dart';
import '../data/destinations.dart';
import '../data/parking_service.dart';
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
  FloorLevelConfig? _overrideFloor;
  final ParkingService _parkingService = ParkingService();

  FloorLevelConfig get displayFloor => _overrideFloor ?? widget.currentFloor;

  @override
  void initState() {
    super.initState();
    _parkingService.addListener(_onParkingStateChanged);
  }

  @override
  void didUpdateWidget(FloorPlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentFloor.floorNumber != oldWidget.currentFloor.floorNumber) {
      _overrideFloor = widget.currentFloor;
    }
  }

  @override
  void dispose() {
    _parkingService.removeListener(_onParkingStateChanged);
    super.dispose();
  }

  void _onParkingStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isParkingFloor = displayFloor.floorNumber < 0;
    final currentFloorPOIs = isParkingFloor
        ? <DestinationPOI>[]
        : widget.destinations
            .where((poi) => poi.floorNumber == displayFloor.floorNumber)
            .toList();

    final String floorId = displayFloor.floorNumber == -1
        ? 'B1'
        : (displayFloor.floorNumber == -2 ? 'B2' : 'B1');

    final List<ParkingSlot> floorSlots = isParkingFloor
        ? _parkingService.fetchFloorMap(floorId)
        : <ParkingSlot>[];

    final MyVehicleLocation? myVehicle = _parkingService.currentVehicleLocation;
    final int freeSlotsCount = floorSlots
        .where((s) => s.status == ParkingSlotStatus.free)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.layers, color: Color(0xFF2563EB), size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Floor Map',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!isParkingFloor)
            InkWell(
              onTap: () => _showFloorDirectoryModal(context, currentFloorPOIs),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.store, color: Color(0xFF2563EB), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${currentFloorPOIs.length} Shops',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            InkWell(
              onTap: () {
                if (myVehicle != null) {
                  final parkedSlot = floorSlots.firstWhere(
                    (s) => s.id == myVehicle.slotId,
                    orElse: () => ParkingSlot(
                      id: myVehicle.slotId,
                      floorId: myVehicle.floorId,
                      section: 'A',
                      slotNumber: 1,
                      status: ParkingSlotStatus.occupied,
                      location: myVehicle.location,
                      gridRow: 0,
                      gridCol: 0,
                      sensorId: '',
                    ),
                  );
                  _showParkingSlotModal(context, parkedSlot, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tap any parking slot on the map to park your vehicle or navigate!'),
                      backgroundColor: Color(0xFF2563EB),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: myVehicle != null ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: myVehicle != null ? const Color(0xFF86EFAC) : const Color(0xFF334155),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      myVehicle != null ? LucideIcons.car : LucideIcons.parkingCircle,
                      color: myVehicle != null ? Colors.white : const Color(0xFF38BDF8),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      myVehicle != null
                          ? 'My Car: ${myVehicle.slotId}'
                          : '$freeSlotsCount/24 Free',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: myVehicle != null ? Colors.white : const Color(0xFF38BDF8),
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
                final isSelected = floor.floorNumber == displayFloor.floorNumber;
                final isParkedFloor = myVehicle != null &&
                    ((floor.floorNumber == -1 && myVehicle.floorId.contains('B1')) ||
                        (floor.floorNumber == -2 && myVehicle.floorId.contains('B2')));

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPOI = null;
                      _overrideFloor = floor;
                    });
                    widget.onSelectFloor(floor);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : (isParkedFloor ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: isParkedFloor && !isSelected
                          ? Border.all(color: const Color(0xFF22C55E), width: 1.5)
                          : null,
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
                        if (isParkedFloor && !isSelected) ...[
                          const Icon(LucideIcons.car, size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          floor.floorNumber < 0
                              ? 'B${floor.floorNumber}'
                              : 'F${floor.floorNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : (isParkedFloor ? const Color(0xFF15803D) : const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Banner Notification if Parked on another floor
          if (myVehicle != null && !isParkingFloor)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFDCFCE7),
              child: Row(
                children: [
                  const Icon(LucideIcons.car, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your vehicle is parked at ${myVehicle.slotId} (${myVehicle.floorName})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final targetFloorNumber = myVehicle.floorId.contains('B2') ? -2 : -1;
                      final targetFloorConfig = widget.buildingProfile.floors.firstWhere(
                        (f) => f.floorNumber == targetFloorNumber,
                        orElse: () => widget.buildingProfile.floors.first,
                      );
                      setState(() {
                        _selectedPOI = null;
                        _overrideFloor = targetFloorConfig;
                      });
                      widget.onSelectFloor(targetFloorConfig);
                    },
                    icon: const Icon(LucideIcons.arrowRight, size: 14, color: Color(0xFF16A34A)),
                    label: Text(
                      'Go to ${myVehicle.floorId}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
            ),

          // Map Canvas + Pins & Clickable Parking Overlays Container
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
                            floorNumber: displayFloor.floorNumber,
                            floorName: displayFloor.name,
                            selectedPOI: _selectedPOI,
                            parkingSlots: floorSlots,
                            myVehicle: myVehicle,
                          ),
                        ),

                        // Render Interactive POI Pins over Non-Parking Floors
                        if (!isParkingFloor)
                          ...currentFloorPOIs.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final poi = entry.value;

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

                        // Render Interactive Clickable Parking Slot Hitbox Overlays on Parking Floors
                        if (isParkingFloor)
                          ..._buildClickableParkingSlotOverlays(
                            width,
                            height,
                            floorId,
                            floorSlots,
                            myVehicle,
                          ),

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

                        // Clean Map Legend Overlay
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isParkingFloor ? LucideIcons.parkingCircle : LucideIcons.compass,
                                  color: isParkingFloor ? const Color(0xFF0284C7) : const Color(0xFF2563EB),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  displayFloor.floorNumber < 0
                                      ? 'B${displayFloor.floorNumber}'
                                      : displayFloor.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Dynamic D-Pad Controls
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

  /// Builds 24 interactive hitboxes placed exactly over every parking stall canvas box on B1/B2
  List<Widget> _buildClickableParkingSlotOverlays(
    double width,
    double height,
    String floorId,
    List<ParkingSlot> slots,
    MyVehicleLocation? myVehicle,
  ) {
    const double roomTopPadding = 52.0;
    final double availableHeight = height - roomTopPadding - 32.0;
    final double slotH = availableHeight * 0.135;
    final double gapY = (availableHeight - (slotH * 6)) / 5;
    final double slotW = (width * 0.34 - 18) / 2;

    final List<Widget> widgets = [];

    // Left Wing: Zone A (Slots A-01 to A-12)
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 2; col++) {
        final int num = row * 2 + col + 1;
        final String numStr = num < 10 ? '0$num' : '$num';
        final String code = '$floorId-A-$numStr';
        final double slotX = 20.0 + col * (slotW + 3);
        final double slotY = roomTopPadding + row * (slotH + gapY);

        final slotObj = slots.firstWhere(
          (s) => s.id == code,
          orElse: () => ParkingSlot(
            id: code,
            floorId: floorId,
            section: 'A',
            slotNumber: num,
            status: ParkingSlotStatus.free,
            location: widget.userCoords,
            gridRow: row,
            gridCol: col,
            isEVCharging: num == 1 || num == 2,
            isHandicapAccessible: num == 3 || num == 4,
            sensorId: 'IOT-$code',
          ),
        );

        final bool isMyCar = myVehicle != null && myVehicle.slotId == code && myVehicle.status == 'parked';

        widgets.add(
          Positioned(
            left: slotX,
            top: slotY,
            width: slotW,
            height: slotH,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                splashColor: isMyCar
                    ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.3),
                onTap: () => _showParkingSlotModal(context, slotObj, isMyCar),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: isMyCar
                        ? Border.all(color: const Color(0xFF22C55E), width: 2.5)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );

        if (isMyCar) {
          widgets.add(
            Positioned(
              left: (slotX + slotW / 2 - 38).clamp(8.0, width - 85.0),
              top: (slotY - 14).clamp(6.0, height - 30.0),
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x9922C55E),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🚗', style: TextStyle(fontSize: 9)),
                      const SizedBox(width: 3),
                      Text(
                        'MY CAR',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // Right Wing: Zone B (Slots B-01 to B-12)
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 2; col++) {
        final int num = row * 2 + col + 1;
        final String numStr = num < 10 ? '0$num' : '$num';
        final String code = '$floorId-B-$numStr';
        final double slotX = width * 0.65 + col * (slotW + 3);
        final double slotY = roomTopPadding + row * (slotH + gapY);

        final slotObj = slots.firstWhere(
          (s) => s.id == code,
          orElse: () => ParkingSlot(
            id: code,
            floorId: floorId,
            section: 'B',
            slotNumber: num,
            status: ParkingSlotStatus.free,
            location: widget.userCoords,
            gridRow: row,
            gridCol: col,
            sensorId: 'IOT-$code',
          ),
        );

        final bool isMyCar = myVehicle != null && myVehicle.slotId == code && myVehicle.status == 'parked';

        widgets.add(
          Positioned(
            left: slotX,
            top: slotY,
            width: slotW,
            height: slotH,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                splashColor: isMyCar
                    ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.3),
                onTap: () => _showParkingSlotModal(context, slotObj, isMyCar),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: isMyCar
                        ? Border.all(color: const Color(0xFF22C55E), width: 2.5)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );

        if (isMyCar) {
          widgets.add(
            Positioned(
              left: (slotX + slotW / 2 - 38).clamp(8.0, width - 85.0),
              top: (slotY - 14).clamp(6.0, height - 30.0),
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x9922C55E),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🚗', style: TextStyle(fontSize: 9)),
                      const SizedBox(width: 3),
                      Text(
                        'MY CAR',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return widgets;
  }

  /// Interactive Modal Bottom Sheet for Parking Stall (Functions Before & After Parking)
  void _showParkingSlotModal(BuildContext context, ParkingSlot slot, bool isMyCar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Header Row: Slot Name + Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMyCar ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isMyCar ? LucideIcons.car : LucideIcons.parkingCircle,
                    color: isMyCar ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Parking Stall ${slot.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${displayFloor.name} • Zone ${slot.section}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMyCar
                        ? const Color(0xFFDCFCE7)
                        : (slot.status == ParkingSlotStatus.free
                            ? const Color(0xFFF0FDF4)
                            : (slot.status == ParkingSlotStatus.occupied
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFFFFBEB))),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMyCar
                          ? const Color(0xFF86EFAC)
                          : (slot.status == ParkingSlotStatus.free
                              ? const Color(0xFFBBF7D0)
                              : (slot.status == ParkingSlotStatus.occupied
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFFDE68A))),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMyCar) ...[
                        const Text('🚗 ', style: TextStyle(fontSize: 10)),
                      ],
                      Text(
                        isMyCar
                            ? 'PARKED'
                            : (slot.status == ParkingSlotStatus.free
                                ? 'AVAILABLE'
                                : (slot.status == ParkingSlotStatus.occupied
                                    ? 'OCCUPIED'
                                    : 'RESERVED')),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isMyCar
                              ? const Color(0xFF15803D)
                              : (slot.status == ParkingSlotStatus.free
                                  ? const Color(0xFF16A34A)
                                  : (slot.status == ParkingSlotStatus.occupied
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFD97706))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Features chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (slot.isEVCharging)
                  _buildFeatureChip(LucideIcons.zap, '⚡ 120kW EV Charging Station', const Color(0xFF16A34A)),
                if (slot.isHandicapAccessible)
                  _buildFeatureChip(LucideIcons.accessibility, '♿ Handicap Accessible Bay', const Color(0xFF2563EB)),
                _buildFeatureChip(LucideIcons.radio, '🛰️ Live IoT Sensor Active', const Color(0xFF64748B)),
              ],
            ),
            const SizedBox(height: 20),

            // Info Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stall ID', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slot.id,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Assigned Vehicle', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isMyCar
                              ? 'WP CAB-8821 (My Vehicle)'
                              : (slot.status == ParkingSlotStatus.free
                                  ? 'Unassigned'
                                  : 'Occupied by another vehicle'),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isMyCar
                                ? const Color(0xFF16A34A)
                                : (slot.status == ParkingSlotStatus.free
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFDC2626)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SUITABLE FUNCTIONS BEFORE & AFTER PARKING
            if (!isMyCar && slot.status != ParkingSlotStatus.free) ...[
              // OCCUPIED RESTRICTION WARNING BOX
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldAlert, color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PARKING RESTRICTED',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFDC2626),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stall ${slot.id} is occupied by another vehicle. Parking is restricted.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.navigation, color: Color(0xFF2563EB), size: 20),
                  label: Text(
                    'NAVIGATE TO THIS SLOT (AR VIEW)',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onSelectDestination != null) {
                      widget.onSelectDestination!(slot.toDestinationPOI());
                    }
                  },
                ),
              ),
            ] else if (!isMyCar) ...[
              // FREE SLOT: PARK MY VEHICLE HERE
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.car, color: Colors.white, size: 20),
                  label: Text(
                    'PARK MY VEHICLE HERE',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    try {
                      await _parkingService.saveVehicleLocation(
                        MyVehicleLocation(
                          userId: _parkingService.currentUserId,
                          slotId: slot.id,
                          floorId: slot.floorId,
                          floorName: displayFloor.name,
                          location: slot.location,
                          timestamp: DateTime.now(),
                        ),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(LucideIcons.checkCircle, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Vehicle successfully parked at Stall ${slot.id}!')),
                              ],
                            ),
                            backgroundColor: const Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        setState(() {});
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(LucideIcons.alertTriangle, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
                              ],
                            ),
                            backgroundColor: const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              // 2. NAVIGATE TO THIS SLOT (BEFORE PARKED FUNCTION)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.navigation, color: Color(0xFF2563EB), size: 20),
                  label: Text(
                    'NAVIGATE TO THIS SLOT (AR VIEW)',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onSelectDestination != null) {
                      widget.onSelectDestination!(slot.toDestinationPOI());
                    }
                  },
                ),
              ),
            ] else ...[
              // 1. NAVIGATE TO MY PARKED VEHICLE (AFTER PARKED FUNCTION)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.compass, color: Colors.white, size: 20),
                  label: Text(
                    'NAVIGATE TO MY PARKED VEHICLE',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onSelectDestination != null) {
                      widget.onSelectDestination!(slot.toDestinationPOI());
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              // 2. UNPARK VEHICLE / REMOVE SPOT (AFTER PARKED FUNCTION)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.logOut, color: Colors.white, size: 20),
                  label: Text(
                    'UNPARK VEHICLE / REMOVE SPOT',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    await _parkingService.clearVehicleLocation();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(LucideIcons.info, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Vehicle unparked from Stall ${slot.id}.')),
                            ],
                          ),
                          backgroundColor: const Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color),
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
                      'Floor Directory (${displayFloor.name})',
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
  final List<ParkingSlot> parkingSlots;
  final MyVehicleLocation? myVehicle;

  ArchitecturalFloorPainter({
    required this.floorNumber,
    required this.floorName,
    this.selectedPOI,
    this.parkingSlots = const [],
    this.myVehicle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isBasement = floorNumber < 0;
    final bool isParkingFloor = isBasement;

    final bgPaint = Paint()..color = isParkingFloor ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final outerBorderPaint = Paint()
      ..color = isParkingFloor ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final wallFillPaint = Paint()..color = isParkingFloor ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    // 1. Draw Outer Building Boundary Wall
    final outerRect = RRect.fromLTRBR(16, 16, size.width - 16, size.height - 16, const Radius.circular(24));
    canvas.drawRRect(outerRect, wallFillPaint);
    canvas.drawRRect(outerRect, outerBorderPaint);

    // 2. Draw Central Driveway / Walking Corridor
    final corridorPaint = Paint()..color = isParkingFloor ? const Color(0xFF334155) : Colors.white;
    const roomTopPadding = 56.0;
    final corridorRect = RRect.fromLTRBR(size.width * 0.38, roomTopPadding, size.width * 0.62, size.height - 24, const Radius.circular(16));
    canvas.drawRRect(corridorRect, corridorPaint);

    final corridorBorderPaint = Paint()
      ..color = isParkingFloor ? const Color(0xFF00E5FF) : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(corridorRect, corridorBorderPaint);

    // 3. Draw Room / Parking Stall Blocks
    final roomColors = isParkingFloor
        ? [
            const Color(0xFF1E293B),
            const Color(0xFF1E293B),
            const Color(0xFF1E293B),
            const Color(0xFF1E293B),
          ]
        : [
            const Color(0xFFEFF6FF),
            const Color(0xFFFDF2F8),
            const Color(0xFFFEF3C7),
            const Color(0xFFF0FDF4),
          ];

    final roomBorderPaint = Paint()
      ..color = isParkingFloor ? const Color(0xFF475569) : const Color(0xFF94A3B8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final availableHeight = size.height - roomTopPadding - 24.0;
    final roomH = availableHeight * 0.28;
    final gapY = (availableHeight - (roomH * 3)) / 2;

    // 3. Draw Floor Content: Parking Plan (Basement) vs Retail Plan (Ground & Upper Floors)
    if (isParkingFloor) {
      _paintBasementParkingPlan(canvas, size, roomTopPadding, availableHeight, roomH, gapY);
    } else {
      _paintRetailPlan(canvas, size, roomTopPadding, availableHeight, roomH, gapY, roomColors, roomBorderPaint);
    }

    // 4. Draw Escalators & Elevator Hub
    final facilityPaint = Paint()..color = isParkingFloor ? const Color(0xFF0284C7) : const Color(0xFFE0F2FE);
    final elevRect = Rect.fromLTWH(size.width * 0.38, 22, size.width * 0.24, 26);
    canvas.drawRRect(RRect.fromRectAndRadius(elevRect, const Radius.circular(8)), facilityPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(elevRect, const Radius.circular(8)), outerBorderPaint);

    final String hubText = floorNumber == 1
        ? 'MAIN ENTRANCE LOBBY & RECEPTION'
        : (isBasement ? 'PARKING ELEVATOR & STAIRS' : 'MALL ELEVATOR & LOBBY');

    final elevPainter = TextPainter(
      text: TextSpan(
        text: hubText,
        style: TextStyle(
          color: isParkingFloor ? Colors.white : const Color(0xFF0369A1),
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    elevPainter.layout();
    elevPainter.paint(canvas, Offset(elevRect.left + (elevRect.width - elevPainter.width) / 2, elevRect.top + 7));
  }

  void _drawSingleParkingStall(
    Canvas canvas,
    Rect slotRect,
    String slotCode, {
    bool isEV = false,
    bool isHandicap = false,
    ParkingSlotStatus status = ParkingSlotStatus.free,
    bool isMyCar = false,
  }) {
    Color fillPaintColor = const Color(0xFF1E293B);
    Color borderPaintColor = isEV ? const Color(0xFF22C55E) : (isHandicap ? const Color(0xFF3B82F6) : const Color(0xFF475569));

    if (isMyCar) {
      fillPaintColor = const Color(0xFF047857);
      borderPaintColor = const Color(0xFF4ADE80);

      // Distinct Glowing Outer Halo for User's Parked Car
      final glowRect = slotRect.inflate(3);
      final glowPaint = Paint()
        ..color = const Color(0xFF22C55E).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawRRect(RRect.fromRectAndRadius(glowRect, const Radius.circular(8)), glowPaint);
    } else if (status == ParkingSlotStatus.occupied) {
      fillPaintColor = const Color(0xFF334155);
      borderPaintColor = const Color(0xFF64748B);
    } else if (status == ParkingSlotStatus.reserved) {
      fillPaintColor = const Color(0xFF1E293B);
      borderPaintColor = const Color(0xFFF59E0B);
    }

    final fillPaint = Paint()..color = fillPaintColor;
    final borderPaint = Paint()
      ..color = borderPaintColor
      ..strokeWidth = isMyCar ? 2.5 : 1.2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(slotRect, const Radius.circular(6));
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, borderPaint);

    if (isMyCar) {
      _drawText(canvas, slotCode, Offset(slotRect.left + 3, slotRect.top + 4), Colors.white, fontSize: 7.0);
      _drawText(canvas, 'PARKED', Offset(slotRect.left + 3, slotRect.top + 16), const Color(0xFF4ADE80), fontSize: 6.5);
      return;
    }

    String tag = '';
    Color tagColor = const Color(0xFF38BDF8);
    if (isEV) {
      tag = '⚡';
      tagColor = const Color(0xFF4ADE80);
    } else if (isHandicap) {
      tag = '♿';
      tagColor = const Color(0xFF60A5FA);
    }

    _drawText(canvas, '$slotCode $tag', Offset(slotRect.left + 3, slotRect.top + 4), tagColor, fontSize: 7.0);

    final String statusLabel = status == ParkingSlotStatus.free ? 'FREE' : (status == ParkingSlotStatus.occupied ? 'OCCUPIED' : 'RESERVED');
    final Color statusColor = status == ParkingSlotStatus.free ? const Color(0xFF22C55E) : (status == ParkingSlotStatus.occupied ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
    _drawText(canvas, statusLabel, Offset(slotRect.left + 3, slotRect.top + 16), statusColor, fontSize: 6.5);
  }

  void _paintBasementParkingPlan(
    Canvas canvas,
    Size size,
    double topPadding,
    double availHeight,
    double rH,
    double gY,
  ) {
    const double roomTopPadding = 52.0;
    final double availableHeight = size.height - roomTopPadding - 32.0;
    final double slotH = availableHeight * 0.135;
    final double gapY = (availableHeight - (slotH * 6)) / 5;

    final dashPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Driving Corridor Arrows & Center Line
    final double midX = size.width * 0.50;
    for (double y = roomTopPadding + 8; y < size.height - 35; y += 22) {
      canvas.drawLine(Offset(midX, y), Offset(midX, y + 10), dashPaint);
    }

    const String laneText = '▲ DRIVING LANE (ONE-WAY) ▲';

    final textPainter = TextPainter(
      text: const TextSpan(
        text: laneText,
        style: TextStyle(color: Color(0xFFFBBF24), fontSize: 7.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(midX - textPainter.width / 2, roomTopPadding + 8));

    final double slotW = (size.width * 0.34 - 18) / 2;
    final String prefix = floorNumber == -1 ? 'B1' : (floorNumber == -2 ? 'B2' : 'B');

    // Left Wing: PARKING ZONE A (All 12 Slots: A-01 to A-12)
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 2; col++) {
        final int num = row * 2 + col + 1;
        final String numStr = num < 10 ? '0$num' : '$num';
        final String code = '$prefix-A-$numStr';
        final double slotX = 20.0 + col * (slotW + 3);
        final double slotY = roomTopPadding + row * (slotH + gapY);
        final Rect slotRect = Rect.fromLTWH(slotX, slotY, slotW, slotH);

        final bool isEV = num == 1 || num == 2;
        final bool isHandicap = num == 3 || num == 4;

        final slotObj = parkingSlots.firstWhere(
          (s) => s.id == code,
          orElse: () => ParkingSlot(
            id: code,
            floorId: prefix,
            section: 'A',
            slotNumber: num,
            status: ParkingSlotStatus.free,
            location: const GeodeticCoords(latitude: 0, longitude: 0, height: 0),
            gridRow: row,
            gridCol: col,
            sensorId: 'IOT-$code',
          ),
        );

        final bool isMyCar = myVehicle != null && myVehicle!.slotId == code && myVehicle!.status == 'parked';

        _drawSingleParkingStall(
          canvas,
          slotRect,
          code,
          isEV: isEV,
          isHandicap: isHandicap,
          status: slotObj.status,
          isMyCar: isMyCar,
        );
      }
    }

    // Right Wing: PARKING ZONE B (All 12 Slots: B-01 to B-12)
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 2; col++) {
        final int num = row * 2 + col + 1;
        final String numStr = num < 10 ? '0$num' : '$num';
        final String code = '$prefix-B-$numStr';
        final double slotX = size.width * 0.65 + col * (slotW + 3);
        final double slotY = roomTopPadding + row * (slotH + gapY);
        final Rect slotRect = Rect.fromLTWH(slotX, slotY, slotW, slotH);

        final slotObj = parkingSlots.firstWhere(
          (s) => s.id == code,
          orElse: () => ParkingSlot(
            id: code,
            floorId: prefix,
            section: 'B',
            slotNumber: num,
            status: ParkingSlotStatus.free,
            location: const GeodeticCoords(latitude: 0, longitude: 0, height: 0),
            gridRow: row,
            gridCol: col,
            sensorId: 'IOT-$code',
          ),
        );

        final bool isMyCar = myVehicle != null && myVehicle!.slotId == code && myVehicle!.status == 'parked';

        _drawSingleParkingStall(
          canvas,
          slotRect,
          code,
          status: slotObj.status,
          isMyCar: isMyCar,
        );
      }
    }

    // Vehicle Ramp / Gate at Bottom Corridor
    const String gateText = '▼ EXIT / ENTRY RAMP';
    final rampRect = Rect.fromLTWH(size.width * 0.34, size.height - 44, size.width * 0.32, 26);
    final rampPaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawRRect(RRect.fromRectAndRadius(rampRect, const Radius.circular(8)), rampPaint);
    _drawText(canvas, gateText, Offset(rampRect.left + 8, rampRect.top + 7), Colors.white, fontSize: 7.5);
  }

  void _paintRetailPlan(
    Canvas canvas,
    Size size,
    double roomTopPadding,
    double availableHeight,
    double roomH,
    double gapY,
    List<Color> roomColors,
    Paint roomBorderPaint,
  ) {
    final roomBoxes = [
      Rect.fromLTWH(24, roomTopPadding, size.width * 0.32, roomH),
      Rect.fromLTWH(24, roomTopPadding + roomH + gapY, size.width * 0.32, roomH),
      Rect.fromLTWH(24, roomTopPadding + (roomH + gapY) * 2, size.width * 0.32, roomH),
      Rect.fromLTWH(size.width * 0.66, roomTopPadding, size.width * 0.30, roomH),
      Rect.fromLTWH(size.width * 0.66, roomTopPadding + roomH + gapY, size.width * 0.30, roomH),
      Rect.fromLTWH(size.width * 0.66, roomTopPadding + (roomH + gapY) * 2, size.width * 0.30, roomH),
    ];

    for (int i = 0; i < roomBoxes.length; i++) {
      final rect = roomBoxes[i];
      final fillPaint = Paint()..color = roomColors[i % roomColors.length];
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), fillPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), roomBorderPaint);

      final roomCode = '#${floorNumber}0${i + 1}';
      _drawText(canvas, roomCode, Offset(rect.left + 8, rect.top + 8), const Color(0xFF94A3B8));
    }

    // Dedicated Basement Parking Access Zone at Bottom Corridor for Ground/Upper Floors
    final parkingAccessRect = Rect.fromLTWH(size.width * 0.38, size.height - 48, size.width * 0.24, 28);
    final parkingAccessPaint = Paint()..color = const Color(0xFFDBEAFE);
    final parkingAccessBorder = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(RRect.fromRectAndRadius(parkingAccessRect, const Radius.circular(8)), parkingAccessPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(parkingAccessRect, const Radius.circular(8)), parkingAccessBorder);
    _drawText(canvas, '▼ PARKING RAMP (B1/B2)', Offset(parkingAccessRect.left + 6, parkingAccessRect.top + 8), const Color(0xFF1E40AF), fontSize: 7);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, {double fontSize = 10}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
