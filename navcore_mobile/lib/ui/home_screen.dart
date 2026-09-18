import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/destinations.dart';
import '../data/parking_service.dart';
import '../engine/ecef_engine.dart';
import '../engine/floor_tracker.dart';
import '../engine/bearing_engine.dart';
import 'shop_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final GeodeticCoords userCoords;
  final BuildingElevationProfile buildingProfile;
  final List<DestinationPOI> destinations;
  final ParkingService? parkingService;
  final VoidCallback onOpenARView;
  final VoidCallback onOpenFloorMap;
  final VoidCallback onOpenMallExplorer;
  final VoidCallback? onOpenParking;
  final VoidCallback? onFindMyCarAR;
  final ValueChanged<DestinationPOI> onSelectDestination;

  const HomeScreen({
    super.key,
    required this.userCoords,
    required this.buildingProfile,
    required this.destinations,
    this.parkingService,
    required this.onOpenARView,
    required this.onOpenFloorMap,
    required this.onOpenMallExplorer,
    this.onOpenParking,
    this.onFindMyCarAR,
    required this.onSelectDestination,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'label': 'ALL', 'icon': LucideIcons.layoutGrid},
    {'label': 'FOOD & DRINK', 'icon': LucideIcons.utensils},
    {'label': 'TECH & ELECTRONICS', 'icon': LucideIcons.smartphone},
    {'label': 'RETAIL & FASHION', 'icon': LucideIcons.shoppingBag},
    {'label': 'ENTERTAINMENT', 'icon': LucideIcons.gamepad2},
    {'label': 'SERVICES', 'icon': LucideIcons.shieldCheck},
  ];

  void _showShopDetails(DestinationPOI shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShopDetailsScreen(
        destination: shop,
        userCoords: widget.userCoords,
        onStartARNavigation: () {
          Navigator.pop(context);
          widget.onSelectDestination(shop);
          widget.onOpenARView();
        },
      ),
    );
  }

  void _showLocationFixModal(BuildContext context) {
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
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(LucideIcons.navigation, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live GPS Hardware Status',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'Real Mobile Sensor Pipeline Active',
                      style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLocationDetailRow(
              LucideIcons.mapPin,
              'Current Physical GPS Coords',
              '${widget.userCoords.latitude.toStringAsFixed(6)}°, ${widget.userCoords.longitude.toStringAsFixed(6)}°',
            ),
            const SizedBox(height: 10),
            _buildLocationDetailRow(
              LucideIcons.mountain,
              'Absolute Altitude / Height',
              '${widget.userCoords.height.toStringAsFixed(1)} meters MSL',
            ),
            const SizedBox(height: 10),
            _buildLocationDetailRow(
              LucideIcons.layers,
              'Indoor Spatial Floor Band',
              resolveFloorByHeight(widget.userCoords.height, widget.buildingProfile).name,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMallAnchor = widget.destinations.isNotEmpty
        ? widget.destinations.first.location
        : entranceAnchor;
    final effectiveCoords = getEffectiveUserCoords(widget.userCoords, activeMallAnchor);
    final currentFloor = resolveFloorByHeight(widget.userCoords.height, widget.buildingProfile);

    final filteredPOIs = widget.destinations.where((poi) {
      final matchesCategory = _selectedCategory == 'ALL' ||
          poi.category.toUpperCase() == _selectedCategory;
      final matchesSearch = poi.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          poi.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar & Live Location Display Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(LucideIcons.compass, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NavCore AR',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'GPS Hardware Stream Active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(LucideIcons.downloadCloud, color: Color(0xFF2563EB)),
                          onPressed: widget.onOpenMallExplorer,
                          tooltip: 'Cloud Mall Database',
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // User Current Location Header Card (Real-World App Style - Exact Image Design)
                    GestureDetector(
                      onTap: () => _showLocationFixModal(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Soft Blue Location Pin Container Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                LucideIcons.mapPin,
                                color: Color(0xFF2563EB),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Main Details Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Row 1: Label + Floor Badge
                                  Row(
                                    children: [
                                      Text(
                                        'YOUR CURRENT LOCATION',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF64748B),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBEAFE),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'F${currentFloor.floorNumber}',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF1E40AF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  // Row 2: Building/Mall Title + Right Chevron Arrow
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          haversineDistance(widget.userCoords, activeMallAnchor) <= 500.0
                                              ? widget.buildingProfile.name
                                              : 'Real Physical GPS Position',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        LucideIcons.chevronRight,
                                        color: Color(0xFF64748B),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  // Row 3: Coords + Floor Name Subtitle
                                  Text(
                                    '${widget.userCoords.latitude.toStringAsFixed(4)}°, ${widget.userCoords.longitude.toStringAsFixed(4)}° • ${haversineDistance(widget.userCoords, activeMallAnchor) <= 500.0 ? currentFloor.name : "Live GPS Lock"}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Active Mall Hero Banner Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x332563EB),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.building2, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'ACTIVE MALL MAP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '4.9 ★',
                            style: TextStyle(
                              color: Color(0xFFFDE047),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.buildingProfile.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.buildingProfile.floors.length} Floors • Zero-Hardware Indoor PnP Locked',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1E40AF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: widget.onOpenARView,
                              icon: const Icon(LucideIcons.camera, size: 18),
                              label: const Text(
                                'Open AR Camera',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: widget.onOpenFloorMap,
                              icon: const Icon(LucideIcons.layers, size: 18),
                              label: const Text(
                                'Floor Map',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Smart Parking Status Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.parkingService?.hasParkedVehicle == true
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          widget.parkingService?.hasParkedVehicle == true
                              ? LucideIcons.car
                              : LucideIcons.parkingCircle,
                          color: widget.parkingService?.hasParkedVehicle == true
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.parkingService?.hasParkedVehicle == true
                                  ? 'Vehicle Parked at ${widget.parkingService!.currentVehicleLocation!.slotId}'
                                  : 'Smart Parking Available',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              widget.parkingService?.hasParkedVehicle == true
                                  ? '${widget.parkingService!.currentVehicleLocation!.floorName} • ${widget.parkingService!.currentVehicleLocation!.licensePlate}'
                                  : 'Real-time IoT slot tracking on B2, B1 & GF',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.parkingService?.hasParkedVehicle == true
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: widget.parkingService?.hasParkedVehicle == true
                            ? widget.onFindMyCarAR
                            : widget.onOpenParking,
                        child: Text(
                          widget.parkingService?.hasParkedVehicle == true
                              ? 'Find AR'
                              : 'Map',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search shops, food court, brands...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ),
            ),

            // Categories Filter Horizontal List
            SliverToBoxAdapter(
              child: SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['label'];

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: Row(
                          children: [
                            Icon(
                              cat['icon'],
                              size: 14,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['label'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = cat['label']),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Mall Destinations & Stores',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filteredPOIs.length} Stores',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),



            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Shops List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final shop = filteredPOIs[index];
                    final dist = calculateAccurate3DDistance(
                      effectiveCoords,
                      shop.location,
                      userFloorNumber: currentFloor.floorNumber,
                      targetFloorNumber: shop.floorNumber,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        onTap: () => _showShopDetails(shop),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.store, color: Color(0xFF2563EB), size: 20),
                        ),
                        title: Text(
                          shop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'FLOOR ${shop.floorNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${dist.toStringAsFixed(0)}m away',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: GestureDetector(
                          onTap: () {
                            widget.onSelectDestination(shop);
                            widget.onOpenARView();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.navigation, size: 12, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text(
                                  'AR Nav',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filteredPOIs.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
