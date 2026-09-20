import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/parking_service.dart';
import '../data/destinations.dart';
import '../engine/ecef_engine.dart';
import '../engine/bearing_engine.dart';

class ParkingScreen extends StatefulWidget {
  final ParkingService parkingService;
  final GeodeticCoords userCoords;
  final VoidCallback onFindMyCarAR;

  const ParkingScreen({
    super.key,
    required this.parkingService,
    required this.userCoords,
    required this.onFindMyCarAR,
  });

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  String _selectedFloorId = 'B1';

  final List<Map<String, String>> _floors = [
    {'id': 'B2', 'name': 'Basement 2 (B2)'},
    {'id': 'B1', 'name': 'Basement 1 (B1)'},
    {'id': 'GF', 'name': 'Ground Floor (GF)'},
  ];

  @override
  void initState() {
    super.initState();
    widget.parkingService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    widget.parkingService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _handleAutoDetectBLE() {
    final slot = widget.parkingService.autoDetectNearestSlot(
      widget.userCoords,
      _selectedFloorId,
    );

    if (slot != null) {
      _showSlotActionDialog(slot, isAutoDetected: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available slot detected via BLE proximity.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSlotActionDialog(ParkingSlot slot, {bool isAutoDetected = false}) {
    final isMyCarHere = widget.parkingService.renderMyVehicleMarker(
      slot.id,
      _selectedFloorId,
    );
    final currentUserId = widget.parkingService.currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMyCarHere
                        ? const Color(0xFFFEF3C7)
                        : (slot.status == ParkingSlotStatus.free
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isMyCarHere
                        ? LucideIcons.car
                        : (slot.status == ParkingSlotStatus.free
                              ? LucideIcons.parkingSquare
                              : LucideIcons.shieldAlert),
                    color: isMyCarHere
                        ? const Color(0xFFD97706)
                        : (slot.status == ParkingSlotStatus.free
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626)),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parking Slot ${slot.id}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isMyCarHere
                          ? 'YOUR PARKED VEHICLE ($currentUserId)'
                          : 'Floor $_selectedFloorId • Section ${slot.section}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isMyCarHere
                            ? const Color(0xFFD97706)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isAutoDetected)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.zap, color: Color(0xFF2563EB), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'BLE/UWB Beacon Proximity Lock: RSSI -58 dBm (Nearest Slot)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Status', slot.status.name.toUpperCase()),
                  _buildDetailRow('Sensor ID', slot.sensorId),
                  _buildDetailRow(
                    'EV Charger',
                    slot.isEVCharging ? 'Available ⚡' : 'No',
                  ),
                  _buildDetailRow(
                    'Accessibility',
                    slot.isHandicapAccessible
                        ? 'Handicap Friendly ♿'
                        : 'Standard',
                  ),
                  _buildDetailRow(
                    'Personal Visibility',
                    isMyCarHere
                        ? 'Private Marker Active (Only You)'
                        : 'Public Shared Occupancy',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isMyCarHere) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  final userVehicle = widget.parkingService.findMyCar(
                    currentUserId,
                  );
                  if (userVehicle != null) {
                    widget.onFindMyCarAR();
                  }
                },
                icon: const Icon(LucideIcons.navigation, color: Colors.white),
                label: const Text(
                  'Find My Car in AR View',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  await widget.parkingService.clearVehicleLocation(
                    userId: currentUserId,
                  );
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Vehicle location cleared for $currentUserId.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(LucideIcons.logOut, color: Color(0xFFDC2626)),
                label: const Text(
                  'Clear Parked Location',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: slot.status == ParkingSlotStatus.occupied
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF16A34A),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: slot.status == ParkingSlotStatus.occupied
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final record = MyVehicleLocation(
                          userId: currentUserId,
                          vehicleId: 'veh-$currentUserId',
                          slotId: slot.id,
                          floorId: _selectedFloorId,
                          floorName: _floors.firstWhere(
                            (f) => f['id'] == _selectedFloorId,
                          )['name']!,
                          location: slot.location,
                          timestamp: DateTime.now(),
                          status: 'parked',
                          licensePlate: currentUserId == 'user-001'
                              ? 'WP CAB-8821'
                              : 'WP KBB-9900',
                        );
                        await widget.parkingService.saveVehicleLocation(record);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Vehicle successfully tagged at ${slot.id} for $currentUserId!',
                            ),
                            backgroundColor: const Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                icon: const Icon(LucideIcons.car, color: Colors.white),
                label: Text(
                  slot.status == ParkingSlotStatus.occupied
                      ? 'Slot Already Occupied'
                      : 'Park My Vehicle Here ($currentUserId)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = widget.parkingService.fetchFloorSlotStatus(_selectedFloorId);
    final stats = widget.parkingService.getSlotAvailability(_selectedFloorId);
    final currentUserId = widget.parkingService.currentUserId;
    final vehicle = widget.parkingService.fetchMyVehicleLocation(currentUserId);
    int distToCarMeters = 0;
    if (vehicle != null) {
      final effectiveUser = getEffectiveUserCoords(widget.userCoords, entranceAnchor);
      distToCarMeters = calculateAccurate3DDistance(
        effectiveUser,
        vehicle.location,
        userFloorNumber: 1,
        targetFloorNumber: vehicle.floorId.contains('B2') ? -2 : -1,
      ).round();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const Icon(
              LucideIcons.parkingCircle,
              color: Color(0xFF2563EB),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Smart Parking System',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.parkingService.isLiveStreamActive
                  ? LucideIcons.radio
                  : LucideIcons.radioReceiver,
              color: widget.parkingService.isLiveStreamActive
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF94A3B8),
            ),
            tooltip: 'Live IoT Sensor Stream',
            onPressed: () {
              widget.parkingService.toggleLiveStream(
                !widget.parkingService.isLiveStreamActive,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User Session / Auth Switcher Header (Testing Privacy Scope)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.userCheck,
                      color: Color(0xFF38BDF8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Session User: ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      currentUserId,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Switch User: ',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final newUser = currentUserId == 'user-001'
                            ? 'user-002'
                            : 'user-001';
                        widget.parkingService.authenticateUser(
                          userId: newUser,
                          token: 'jwt-token-$newUser',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Authenticated as $newUser (Privacy Scope Switched)',
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentUserId == 'user-001'
                              ? 'User B (002)'
                              : 'User A (001)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white,
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

          // Live IoT Sensor Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.parkingService.isLiveStreamActive
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.parkingService.isLiveStreamActive
                          ? 'WebSocket IoT Live Feed: Connected'
                          : 'IoT Feed Paused',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${stats['freeSlots']} Free / ${stats['totalSlots']} Total',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Parked Vehicle Banner (Rendered ONLY if current user has an active parked vehicle)
          if (vehicle != null) ...[
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.car,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Vehicle at ${vehicle.slotId}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${vehicle.floorName} • ${vehicle.licensePlate} • $distToCarMeters m away',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: widget.onFindMyCarAR,
                    icon: const Icon(LucideIcons.navigation, size: 14),
                    label: const Text(
                      'Find AR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Floor Selection Tabs
          Container(
            height: 46,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: _floors.map((fl) {
                final isSelected = fl['id'] == _selectedFloorId;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFloorId = fl['id']!),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        fl['id']!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Legend Bar & BLE Auto Detect Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildLegendItem(const Color(0xFF22C55E), 'Free'),
                    const SizedBox(width: 10),
                    _buildLegendItem(const Color(0xFFEF4444), 'Occupied'),
                    const SizedBox(width: 10),
                    _buildLegendItem(const Color(0xFFF59E0B), 'Your Car'),
                  ],
                ),
                InkWell(
                  onTap: _handleAutoDetectBLE,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          LucideIcons.zap,
                          color: Color(0xFF2563EB),
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'BLE Auto-Lock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Interactive 2D Floor Map Layout Grid
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  // Private vehicle marker rendering check: returns true ONLY for the authenticated user's vehicle
                  final isMyCarHere = widget.parkingService
                      .renderMyVehicleMarker(slot.id, _selectedFloorId);

                  Color slotColor;
                  if (isMyCarHere) {
                    slotColor = const Color(0xFFF59E0B);
                  } else if (slot.status == ParkingSlotStatus.free) {
                    slotColor = const Color(0xFF22C55E);
                  } else if (slot.status == ParkingSlotStatus.occupied) {
                    slotColor = const Color(0xFFEF4444);
                  } else {
                    slotColor = const Color(0xFF6366F1);
                  }

                  return InkWell(
                    onTap: () => _showSlotActionDialog(slot),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: slotColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: slotColor,
                          width: isMyCarHere ? 2.5 : 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isMyCarHere
                                ? LucideIcons.car
                                : (slot.isEVCharging
                                      ? LucideIcons.zap
                                      : (slot.isHandicapAccessible
                                            ? LucideIcons.accessibility
                                            : LucideIcons.parkingSquare)),
                            color: slotColor,
                            size: 18,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            slot.id,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
