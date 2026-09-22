import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/destinations.dart';
import '../data/parking_service.dart';
import '../engine/ecef_engine.dart';
import '../engine/floor_tracker.dart';
import '../engine/bearing_engine.dart';
import 'shop_details_screen.dart';
import 'widgets/shop_image_widget.dart';

class HomeScreen extends StatefulWidget {
  final GeodeticCoords userCoords;
  final BuildingElevationProfile buildingProfile;
  final List<DestinationPOI> destinations;
  final VoidCallback onOpenARView;
  final VoidCallback onOpenFloorMap;
  final VoidCallback onOpenMallExplorer;
  final ValueChanged<DestinationPOI> onSelectDestination;

  const HomeScreen({
    super.key,
    required this.userCoords,
    required this.buildingProfile,
    required this.destinations,
    required this.onOpenARView,
    required this.onOpenFloorMap,
    required this.onOpenMallExplorer,
    required this.onSelectDestination,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'ALL';
  int? _selectedFloorNumber; // null = All Floors
  String _searchQuery = '';
  bool _onlyOpenNow = false;
  String _sortBy = 'distance'; // 'distance', 'rating', 'name'
  final TextEditingController _searchController = TextEditingController();

  final ParkingService _parkingService = ParkingService();

  @override
  void initState() {
    super.initState();
    _parkingService.addListener(_onParkingChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _parkingService.removeListener(_onParkingChanged);
    super.dispose();
  }

  void _onParkingChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = 'ALL';
      _selectedFloorNumber = null;
      _searchQuery = '';
      _searchController.clear();
      _onlyOpenNow = false;
      _sortBy = 'distance';
    });
  }

  final List<Map<String, dynamic>> _categories = [
    {'label': 'ALL', 'icon': LucideIcons.layoutGrid},
    {'label': 'FOOD & DRINK', 'icon': LucideIcons.utensils},
    {'label': 'TECH & ELECTRONICS', 'icon': LucideIcons.smartphone},
    {'label': 'RETAIL & FASHION', 'icon': LucideIcons.shoppingBag},
    {'label': 'ENTERTAINMENT', 'icon': LucideIcons.gamepad2},
    {'label': 'SERVICES', 'icon': LucideIcons.shieldCheck},
  ];

  Widget _buildSortDropdown() {
    return PopupMenuButton<String>(
      initialValue: _sortBy,
      onSelected: (String val) {
        setState(() {
          _sortBy = val;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _sortBy != 'distance' ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _sortBy != 'distance'
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.arrowUpDown,
              size: 14,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 5),
            Text(
              _sortBy == 'rating'
                  ? 'Top Rated'
                  : _sortBy == 'name'
                  ? 'Name A-Z'
                  : 'Nearest',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'distance',
          child: Row(
            children: [
              Icon(LucideIcons.mapPin, size: 15, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Nearest Distance', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'rating',
          child: Row(
            children: [
              Icon(LucideIcons.star, size: 15, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text('Highest Rating', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'name',
          child: Row(
            children: const [
              Icon(LucideIcons.arrowUpDown, size: 15, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text('Alphabetical (A-Z)', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloorDropdown(FloorLevelConfig currentFloor) {
    final isMyFloorSelected = _selectedFloorNumber == currentFloor.floorNumber;
    final isAllFloorsSelected = _selectedFloorNumber == null;

    String floorLabelText = 'All Floors';
    if (isMyFloorSelected) {
      floorLabelText = currentFloor.floorNumber < 0
          ? 'My Floor (B${currentFloor.floorNumber.abs()})'
          : 'My Floor (F${currentFloor.floorNumber})';
    } else if (_selectedFloorNumber != null) {
      floorLabelText = _selectedFloorNumber! < 0
          ? 'Floor B${_selectedFloorNumber!.abs()}'
          : 'Floor F$_selectedFloorNumber';
    }

    return PopupMenuButton<int?>(
      initialValue: _selectedFloorNumber,
      onSelected: (int? value) {
        setState(() {
          _selectedFloorNumber = value;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMyFloorSelected
              ? const Color(0xFFECFDF5)
              : isAllFloorsSelected
              ? Colors.white
              : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMyFloorSelected
                ? const Color(0xFFA7F3D0)
                : isAllFloorsSelected
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    isMyFloorSelected
                        ? LucideIcons.mapPin
                        : isAllFloorsSelected
                        ? LucideIcons.layers
                        : LucideIcons.building,
                    size: 15,
                    color: isMyFloorSelected
                        ? const Color(0xFF059669)
                        : isAllFloorsSelected
                        ? const Color(0xFF64748B)
                        : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      floorLabelText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isMyFloorSelected
                            ? const Color(0xFF065F46)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronDown,
              size: 15,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int?>>[
        PopupMenuItem<int?>(
          value: null,
          child: Row(
            children: [
              Icon(
                LucideIcons.layers,
                size: 16,
                color: _selectedFloorNumber == null
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              const Text(
                'All Floors',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              if (_selectedFloorNumber == null) ...[
                const Spacer(),
                const Icon(
                  LucideIcons.check,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int?>(
          value: currentFloor.floorNumber,
          child: Row(
            children: [
              const Icon(
                LucideIcons.mapPin,
                size: 16,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 10),
              Text(
                currentFloor.floorNumber < 0
                    ? 'My Floor (B${currentFloor.floorNumber.abs()})'
                    : 'My Floor (F${currentFloor.floorNumber})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF065F46),
                ),
              ),
              if (_selectedFloorNumber == currentFloor.floorNumber) ...[
                const Spacer(),
                const Icon(
                  LucideIcons.check,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...widget.buildingProfile.floors.map((floor) {
          final String floorLabel = floor.floorNumber < 0
              ? 'Floor B${floor.floorNumber.abs()}'
              : 'Floor F${floor.floorNumber}';
          final isSelected = _selectedFloorNumber == floor.floorNumber;
          return PopupMenuItem<int?>(
            value: floor.floorNumber,
            child: Row(
              children: [
                Icon(
                  LucideIcons.building,
                  size: 16,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Text(
                  '$floorLabel (${floor.storesCount} stores)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(
                    LucideIcons.check,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final currentCategoryItem = _categories.firstWhere(
      (cat) => cat['label'] == _selectedCategory,
      orElse: () => _categories.first,
    );

    return PopupMenuButton<String>(
      initialValue: _selectedCategory,
      onSelected: (String value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _selectedCategory != 'ALL'
              ? const Color(0xFFEFF6FF)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedCategory != 'ALL'
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    currentCategoryItem['icon'] as IconData,
                    size: 15,
                    color: _selectedCategory != 'ALL'
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      _selectedCategory == 'ALL'
                          ? 'All Categories'
                          : _selectedCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _selectedCategory != 'ALL'
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronDown,
              size: 15,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => _categories.map((cat) {
        final isSelected = _selectedCategory == cat['label'];
        final String labelText = cat['label'] == 'ALL'
            ? 'All Categories'
            : cat['label'];
        return PopupMenuItem<String>(
          value: cat['label'],
          child: Row(
            children: [
              Icon(
                cat['icon'] as IconData,
                size: 16,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Text(
                labelText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(
                  LucideIcons.check,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveFiltersRow() {
    final bool hasActiveFilters =
        _selectedCategory != 'ALL' ||
        _selectedFloorNumber != null ||
        _searchQuery.isNotEmpty ||
        _onlyOpenNow ||
        _sortBy != 'distance';

    if (!hasActiveFilters) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Active:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            _buildFilterChip('Search: "$_searchQuery"', () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            }),
          if (_selectedCategory != 'ALL')
            _buildFilterChip(_selectedCategory, () {
              setState(() => _selectedCategory = 'ALL');
            }),
          if (_selectedFloorNumber != null)
            _buildFilterChip(
              _selectedFloorNumber! < 0
                  ? 'Floor B${_selectedFloorNumber!.abs()}'
                  : 'Floor F$_selectedFloorNumber',
              () => setState(() => _selectedFloorNumber = null),
            ),
          if (_onlyOpenNow)
            _buildFilterChip('Open Now', () {
              setState(() => _onlyOpenNow = false);
            }),
          if (_sortBy != 'distance')
            _buildFilterChip(
              _sortBy == 'rating' ? 'Top Rated' : 'Sort A-Z',
              () => setState(() => _sortBy = 'distance'),
            ),
          GestureDetector(
            onTap: _clearAllFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              LucideIcons.x,
              size: 13,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMallAnchor = widget.destinations.isNotEmpty
        ? widget.destinations.first.location
        : entranceAnchor;
    final effectiveCoords = getEffectiveUserCoords(
      widget.userCoords,
      activeMallAnchor,
    );
    final currentFloor = resolveFloorByHeight(
      widget.userCoords.height,
      widget.buildingProfile,
    );

    final filteredPOIs = widget.destinations.where((poi) {
      final matchesCategory =
          _selectedCategory == 'ALL' ||
          poi.category.toUpperCase() == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          poi.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          poi.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          poi.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFloor =
          _selectedFloorNumber == null ||
          poi.floorNumber == _selectedFloorNumber;
      final matchesOpen =
          !_onlyOpenNow || poi.openStatus.toUpperCase().contains('OPEN');
      return matchesCategory && matchesSearch && matchesFloor && matchesOpen;
    }).toList();

    filteredPOIs.sort((a, b) {
      if (_sortBy == 'rating') {
        return b.rating.compareTo(a.rating);
      } else if (_sortBy == 'name') {
        return a.name.compareTo(b.name);
      } else {
        final distA = calculateAccurate3DDistance(
          effectiveCoords,
          a.location,
          userFloorNumber: currentFloor.floorNumber,
          targetFloorNumber: a.floorNumber,
        );
        final distB = calculateAccurate3DDistance(
          effectiveCoords,
          b.location,
          userFloorNumber: currentFloor.floorNumber,
          targetFloorNumber: b.floorNumber,
        );
        return distA.compareTo(distB);
      }
    });

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
                          child: const Icon(
                            LucideIcons.compass,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NexNav AR',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Indoor Positioning Active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.downloadCloud,
                            color: Color(0xFF2563EB),
                          ),
                          onPressed: widget.onOpenMallExplorer,
                          tooltip: 'Cloud Mall Database',
                        ),
                      ],
                    ),

                    if (_parkingService.hasParkedVehicle)
                      _buildParkedVehicleHomeCard(
                        _parkingService.currentVehicleLocation!,
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
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x441E40AF),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 1. Mall Interior Background Photo
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/mall_bg.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF1E40AF),
                                      Color(0xFF3B82F6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                        ),
                      ),

                      // 2. Realistic Neutral Glassmorphism Dark Overlay (Preserves True Photo Colors & Lighting)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(
                                  0xCC090D16,
                                ), // 80% dark slate top vignette for header badges
                                const Color(
                                  0x33090D16,
                                ), // 20% transparent mid region for REAL photo colors
                                const Color(
                                  0xB3090D16,
                                ), // 70% dark slate bottom vignette for button contrast
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 3. Card Content & Action Controls
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.building2,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'ACTIVE MALL MAP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFDE047,
                                      ).withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '4.9',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        LucideIcons.star,
                                        color: Color(0xFFFDE047),
                                        size: 13,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.buildingProfile.name,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                height: 1.25,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${widget.buildingProfile.floors.length} Floors Available',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 2,
                                        offset: Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF0F172A),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 3,
                                      shadowColor: Colors.black38,
                                    ),
                                    onPressed: widget.onOpenARView,
                                    icon: const Icon(
                                      LucideIcons.camera,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Open AR Camera',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        width: 1.2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: widget.onOpenFloorMap,
                                    icon: const Icon(
                                      LucideIcons.layers,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Floor Map',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
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
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search shops, food court, brands...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
            ),

            // Destinations & Stores Section Header with Selection Dropdowns & Filter Controls
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Destinations & Stores',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ),
                                ),
                                child: Text(
                                  '${filteredPOIs.length}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Open Now Toggle Pill
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _onlyOpenNow = !_onlyOpenNow;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _onlyOpenNow
                                  ? const Color(0xFFDCFCE7)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _onlyOpenNow
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 12,
                                  color: _onlyOpenNow
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Open',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _onlyOpenNow
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildSortDropdown(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Dropdowns Bar (Floor & Category)
                    Row(
                      children: [
                        Expanded(child: _buildFloorDropdown(currentFloor)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildCategoryDropdown()),
                      ],
                    ),
                    _buildActiveFiltersRow(),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            if (filteredPOIs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          LucideIcons.store,
                          size: 36,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No stores match your filters',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try resetting search, selecting "All Floors", or another category',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _clearAllFilters,
                          icon: const Icon(LucideIcons.refreshCw, size: 14),
                          label: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Shops List with Rich Images & Cards
            if (filteredPOIs.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
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
                      child: InkWell(
                        onTap: () => _showShopDetails(shop),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // 1. Shop Thumbnail Image with Rating Badge Overlay
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: ShopImage(
                                        imagePathOrUrl: shop.effectiveImageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.68,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${shop.rating}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(
                                            LucideIcons.star,
                                            color: Color(0xFFFDE047),
                                            size: 11,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              // 2. Shop Details Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              shop.category.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF475569),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            shop.openStatus,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF16A34A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  shop.floorNumber ==
                                                      currentFloor.floorNumber
                                                  ? const Color(0xFFECFDF5)
                                                  : const Color(0xFFEFF6FF),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color:
                                                    shop.floorNumber ==
                                                        currentFloor.floorNumber
                                                    ? const Color(0xFFA7F3D0)
                                                    : const Color(0xFFDBEAFE),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (shop.floorNumber ==
                                                    currentFloor
                                                        .floorNumber) ...[
                                                  const Icon(
                                                    LucideIcons.mapPin,
                                                    size: 9.5,
                                                    color: Color(0xFF059669),
                                                  ),
                                                  const SizedBox(width: 2.5),
                                                ],
                                                Flexible(
                                                  child: Text(
                                                    shop.floorNumber ==
                                                            currentFloor
                                                                .floorNumber
                                                        ? (shop.floorNumber < 0
                                                              ? 'THIS FLOOR • B${shop.floorNumber.abs()}'
                                                              : 'THIS FLOOR • F${shop.floorNumber}')
                                                        : shop.floorNumber < 0
                                                        ? 'B${shop.floorNumber.abs()} BASEMENT'
                                                        : 'F${shop.floorNumber}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          shop.floorNumber ==
                                                              currentFloor
                                                                  .floorNumber
                                                          ? const Color(
                                                              0xFF047857,
                                                            )
                                                          : const Color(
                                                              0xFF1D4ED8,
                                                            ),
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            '${dist.toStringAsFixed(0)}m away',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 3. Right Action Symbol / Button (Open Details)
                              InkWell(
                                onTap: () => _showShopDetails(shop),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFDBEAFE),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.chevronRight,
                                      color: Color(0xFF2563EB),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: filteredPOIs.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParkedVehicleHomeCard(MyVehicleLocation vehicle) {
    final String floorDisplay =
        vehicle.floorName.toLowerCase().contains('parking')
        ? vehicle.floorName
        : '${vehicle.floorName} Parking';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3310B981),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Realistic 3D Isometric Parking Lot Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/parked_car_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF0F172A)),
            ),
          ),

          // 2. Translucent Glassmorphism Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0x990A0F1D), // 60% opacity dark slate top-left
                    const Color(0x440A0F1D), // 27% opacity center
                    const Color(
                      0x88042F2E,
                    ), // 53% opacity subtle emerald glow bottom right
                  ],
                ),
              ),
            ),
          ),

          // 3. Card Content Overlay
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY PARKED VEHICLE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF34D399),
                              letterSpacing: 1.1,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stall ${vehicle.slotId}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            floorDisplay,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4410B981),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'PARKED',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          LucideIcons.compass,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Find My Car (AR)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          elevation: 2,
                          shadowColor: const Color(0x4410B981),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final int floorNum = vehicle.floorId.contains('B2')
                              ? -2
                              : -1;
                          final poi = DestinationPOI(
                            id: vehicle.slotId,
                            name: 'My Parked Car (${vehicle.slotId})',
                            category: 'PARKING',
                            floorNumber: floorNum,
                            rating: 5.0,
                            location: vehicle.location,
                            description: 'Your saved vehicle location',
                            openStatus: '24/7',
                          );
                          widget.onSelectDestination(poi);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          LucideIcons.layers,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Floor Map',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.3),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: widget.onOpenFloorMap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
