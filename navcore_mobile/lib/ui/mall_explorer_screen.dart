import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/mall_database_service.dart';
import '../engine/ecef_engine.dart';
import '../engine/bearing_engine.dart';

class MallExplorerScreen extends StatefulWidget {
  final MallDatabaseService mallService;
  final GeodeticCoords? userCoords;
  final Function(String mallId) onSelectActiveMall;

  const MallExplorerScreen({
    super.key,
    required this.mallService,
    required this.userCoords,
    required this.onSelectActiveMall,
  });

  @override
  State<MallExplorerScreen> createState() => _MallExplorerScreenState();
}

class _MallExplorerScreenState extends State<MallExplorerScreen> {
  List<MallMetadata> _malls = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _loadMalls();
  }

  Future<void> _loadMalls() async {
    setState(() => _isLoading = true);
    final list = await widget.mallService.getMallsList();
    setState(() {
      _malls = list;
      _isLoading = false;
    });
  }

  Future<void> _autoDetectAndDownloadNearestMall() async {
    if (widget.userCoords == null) return;
    setState(() => _isLoading = true);

    final nearest = widget.mallService.findNearestMall(widget.userCoords!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPS Auto-Detecting... Found ${nearest.name}'),
          backgroundColor: const Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await widget.mallService.autoDownloadAndActivateNearestMall(
      widget.userCoords!,
      onProgress: (p) {
        if (mounted) {
          setState(() {
            _downloadProgress[nearest.id] = p;
          });
        }
      },
    );

    _downloadProgress.remove(nearest.id);
    await _loadMalls();
    widget.onSelectActiveMall(nearest.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-downloaded & Activated map for ${nearest.name}!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startDownload(MallMetadata mall) async {
    setState(() {
      _downloadProgress[mall.id] = 0.05;
    });

    await widget.mallService.downloadMallPackage(mall.id, (progress) {
      setState(() {
        _downloadProgress[mall.id] = progress;
      });
    });

    setState(() {
      _downloadProgress.remove(mall.id);
    });

    await _loadMalls();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${mall.name} map downloaded successfully!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _activateMall(MallMetadata mall) async {
    await widget.mallService.setActiveMall(mall.id);
    await _loadMalls();
    widget.onSelectActiveMall(mall.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activated ${mall.name} map for real navigation.'),
          backgroundColor: const Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _malls.where((m) {
      final q = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(q) ||
          m.city.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q);
    }).toList();

    if (widget.userCoords != null) {
      filtered.sort((a, b) {
        final distA = haversineDistance(
          widget.userCoords!,
          GeodeticCoords(
            latitude: a.latitude,
            longitude: a.longitude,
            height: widget.userCoords!.height,
          ),
        );
        final distB = haversineDistance(
          widget.userCoords!,
          GeodeticCoords(
            latitude: b.latitude,
            longitude: b.longitude,
            height: widget.userCoords!.height,
          ),
        );
        return distA.compareTo(distB);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(LucideIcons.store, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Text(
              'Mall Map Database',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search malls, cities, or categories...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.database, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          Text(
                            '${_malls.length} Mall Maps',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(LucideIcons.navigation, size: 12),
                          label: const Text(
                            'Auto-Detect Map',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _autoDetectAndDownloadNearestMall,
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          onPressed: _loadMalls,
                          tooltip: 'Refresh Mall Catalog',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Mall List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.map, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              'No mall map found for "$_searchQuery"',
                              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final mall = filtered[index];
                          final isDownloading = _downloadProgress.containsKey(mall.id);
                          final progress = _downloadProgress[mall.id] ?? 0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: mall.isActive
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                                width: mall.isActive ? 2 : 1,
                              ),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: mall.isActive
                                              ? const Color(0xFFDBEAFE)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          LucideIcons.building2,
                                          color: mall.isActive
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    mall.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  mall.rating,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFD97706),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${mall.city}, ${mall.country} • ${mall.category}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Specs Badges & Real Distance
                                  () {
                                    double? distKm;
                                    if (widget.userCoords != null) {
                                      final meters = haversineDistance(
                                        widget.userCoords!,
                                        GeodeticCoords(
                                          latitude: mall.latitude,
                                          longitude: mall.longitude,
                                          height: widget.userCoords!.height,
                                        ),
                                      );
                                      distKm = meters / 1000.0;
                                    }

                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (distKm != null)
                                          _buildBadge(
                                            LucideIcons.navigation,
                                            distKm < 1.0
                                                ? '${(distKm * 1000).toInt()} m away'
                                                : '${distKm.toStringAsFixed(1)} km away',
                                          ),
                                        _buildBadge(LucideIcons.layers, '${mall.floorCount} Floors'),
                                        _buildBadge(LucideIcons.hardDrive, '${mall.packageSizeBytesMB} MB'),
                                        if (mall.isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFF86EFAC)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(LucideIcons.checkCircle2, size: 12, color: Color(0xFF15803D)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'ACTIVE MAP',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF15803D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    );
                                  }(),

                                  if (isDownloading) ...[
                                    const SizedBox(height: 12),
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      color: const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Downloading Map Package... ${(progress * 100).toInt()}%',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        if (mall.isDownloaded) ...[
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: mall.isActive
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFF2563EB),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: mall.isActive ? null : () => _activateMall(mall),
                                              icon: Icon(
                                                mall.isActive ? LucideIcons.checkCircle : LucideIcons.navigation,
                                                size: 16,
                                              ),
                                              label: Text(
                                                mall.isActive ? 'Map Loaded' : 'Use Map For Navigation',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ] else ...[
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF2563EB),
                                                side: const BorderSide(color: Color(0xFF2563EB)),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () => _startDownload(mall),
                                              icon: const Icon(LucideIcons.downloadCloud, size: 16),
                                              label: Text(
                                                'Download Mall Map (${mall.packageSizeBytesMB} MB)',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
