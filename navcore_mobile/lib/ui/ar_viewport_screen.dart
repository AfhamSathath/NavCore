import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';

import '../engine/ecef_engine.dart';
import '../engine/bearing_engine.dart';
import '../engine/floor_tracker.dart';
import '../data/destinations.dart';
import 'shop_details_screen.dart';
import '../engine/ar_sensor_engine.dart';
import '../engine/sensor_fusion_service.dart';
import '../engine/route_service.dart';
import '../engine/off_route_service.dart';
import '../engine/vertical_transition_service.dart';
import '../data/building_data_service.dart';
import 'theme/app_theme.dart';

enum ARFloorFilterMode { autoTilt, currentFloorOnly, allFloors }

class ARViewportScreen extends StatefulWidget {
  final GeodeticCoords userCoords;
  final FloorLevelConfig currentFloor;
  final List<DestinationPOI> destinations;
  final bool isCalibrated;
  final double compassHeadingDegrees;
  final double phonePitchDegrees;
  final PitchTiltDirection tiltDirection;
  final VoidCallback onScanMarkerClick;
  final ValueChanged<DestinationPOI> onSelectDestination;
  final DestinationPOI? targetDestination;
  final VoidCallback? onBackClicked;
  final VoidCallback? onOpenMapsClicked;

  const ARViewportScreen({
    super.key,
    required this.userCoords,
    required this.currentFloor,
    required this.destinations,
    required this.isCalibrated,
    this.compassHeadingDegrees = 0.0,
    this.phonePitchDegrees = 0.0,
    this.tiltDirection = PitchTiltDirection.level,
    required this.onScanMarkerClick,
    required this.onSelectDestination,
    this.targetDestination,
    this.onBackClicked,
    this.onOpenMapsClicked,
  });

  @override
  State<ARViewportScreen> createState() => _ARViewportScreenState();
}

class _ARViewportScreenState extends State<ARViewportScreen> {
  final String _searchQuery = '';
  String _selectedCategory = 'All';
  final ARFloorFilterMode _floorFilterMode = ARFloorFilterMode.autoTilt;
  bool _isNavigatingActive = false;
  bool _isFavorite = false;
  bool _showGeometricTelemetryModal = false;

  final SensorFusionService _sensorFusion = SensorFusionService();
  final RouteService _routeService = RouteService();
  final OffRouteService _offRouteService = OffRouteService();
  final VerticalTransitionService _transitionService =
      VerticalTransitionService();
  final BuildingDataService _buildingDataService = BuildingDataService();

  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  DestinationPOI? _selectedPOI;
  RoutePath? _activeRoute;

  String get turnActionStr {
    if (_activeRoute == null || _activeRoute!.waypoints.isEmpty) {
      return 'Head straight';
    }
    final nextWp = _activeRoute!.waypoints.first;
    if (nextWp.instruction.isNotEmpty) {
      return nextWp.instruction;
    }
    return 'Follow AR path';
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
    _buildingDataService.loadBuildingConfig();
    final activeAnchor = widget.destinations.isNotEmpty
        ? widget.destinations.first.location
        : entranceAnchor;
    final effectiveUser = getEffectiveUserCoords(
      widget.userCoords,
      activeAnchor,
    );

    if (widget.targetDestination != null) {
      _selectedPOI = widget.targetDestination;
      _isNavigatingActive = true;
      _activeRoute = _routeService.calculateRoute(
        buildingId: 'mall-01',
        userCoords: effectiveUser,
        currentFloor: widget.currentFloor.floorNumber,
        destination: _selectedPOI!,
      );
    } else {
      _selectedPOI = null;
      _isNavigatingActive = false;
      _activeRoute = null;
    }
  }

  @override
  void didUpdateWidget(covariant ARViewportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetDestination != oldWidget.targetDestination) {
      final activeAnchor = widget.destinations.isNotEmpty
          ? widget.destinations.first.location
          : entranceAnchor;
      final effectiveUser = getEffectiveUserCoords(
        widget.userCoords,
        activeAnchor,
      );

      setState(() {
        if (widget.targetDestination != null) {
          _selectedPOI = widget.targetDestination;
          _isNavigatingActive = true;
          _activeRoute = _routeService.calculateRoute(
            buildingId: 'mall-01',
            userCoords: effectiveUser,
            currentFloor: widget.currentFloor.floorNumber,
            destination: _selectedPOI!,
          );
        } else {
          _selectedPOI = null;
          _isNavigatingActive = false;
          _activeRoute = null;
        }
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await controller.initialize();
        if (mounted) {
          setState(() {
            _cameraController = controller;
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera init exception: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _showPoiDetailsModal(DestinationPOI poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShopDetailsScreen(
        destination: poi,
        userCoords: widget.userCoords,
        onStartARNavigation: () {
          Navigator.pop(context);
          setState(() {
            _selectedPOI = poi;
            _isNavigatingActive = true;
          });
          widget.onSelectDestination(poi);
        },
      ),
    );
  }

  bool _matchesCategory(DestinationPOI poi, String selectedCat) {
    if (selectedCat == 'All' || selectedCat == 'ALL') return true;
    final catUpper = poi.category.toUpperCase();
    if (selectedCat == 'Food' || selectedCat == 'FOOD & DRINK') {
      return catUpper.contains('FOOD');
    }
    if (selectedCat == 'Tech' || selectedCat == 'TECH & ELECTRONICS') {
      return catUpper.contains('TECH');
    }
    if (selectedCat == 'Fashion' || selectedCat == 'RETAIL & FASHION') {
      return catUpper.contains('FASHION') || catUpper.contains('RETAIL');
    }
    if (selectedCat == 'Luxury' || selectedCat == 'LUXURY & JEWELRY') {
      return catUpper.contains('LUXURY') || catUpper.contains('BEAUTY');
    }
    if (selectedCat == 'Services' || selectedCat == 'SERVICES') {
      return catUpper.contains('SERVICES');
    }
    if (selectedCat == 'Parking' || selectedCat == 'PARKING') {
      return catUpper.contains('PARK');
    }
    return catUpper.contains(selectedCat.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    // Real-world dynamic mall anchor fallback (anchors user position to active Sri Lanka mall)
    final activeMallAnchor = widget.destinations.isNotEmpty
        ? widget.destinations.first.location
        : entranceAnchor;

    final effectiveUserCoords = getEffectiveUserCoords(
      widget.userCoords,
      activeMallAnchor,
    );

    // Process fused spatial pose via SensorFusionService for smooth, jitter-free compass heading & pose
    final fusedPose = _sensorFusion.updateFusion(
      rawHeading: widget.compassHeadingDegrees,
      rawPitch: widget.phonePitchDegrees,
      rawRoll: 0.0,
      accelX: 0.0,
      accelY: 0.0,
      accelZ: 9.81,
      gyroX: 0.0,
      gyroY: 0.0,
      gyroZ: 0.0,
      gpsCoords: effectiveUserCoords,
    );

    // Resolves target floor dynamically based on continuous mobile camera pitch tilt across Floors 1-10
    int activeTargetFloorNumber = widget.currentFloor.floorNumber;
    if (_floorFilterMode == ARFloorFilterMode.autoTilt) {
      final pitch = widget.phonePitchDegrees;
      if (pitch > 40.0) {
        activeTargetFloorNumber = 10;
      } else if (pitch > 33.0) {
        activeTargetFloorNumber = 9;
      } else if (pitch > 26.0) {
        activeTargetFloorNumber = 8;
      } else if (pitch > 20.0) {
        activeTargetFloorNumber = 7;
      } else if (pitch > 14.0) {
        activeTargetFloorNumber = 6;
      } else if (pitch > 9.0) {
        activeTargetFloorNumber = 5;
      } else if (pitch > 4.0) {
        activeTargetFloorNumber = 4;
      } else if (pitch > -2.0) {
        activeTargetFloorNumber = 3;
      } else if (pitch > -8.0) {
        activeTargetFloorNumber = 2;
      } else {
        activeTargetFloorNumber = 1;
      }
    }

    final filteredPOIs = widget.destinations.where((poi) {
      final matchesSearch =
          poi.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          poi.category.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFloor = true;
      if (_floorFilterMode == ARFloorFilterMode.currentFloorOnly) {
        matchesFloor = (poi.floorNumber == widget.currentFloor.floorNumber);
      }

      // Hide basement parking from shop discovery unless Parking category is explicitly chosen, user is on basement floor, or POI is user's target destination
      final isSelectedTarget =
          _selectedPOI != null && poi.id == _selectedPOI!.id;
      final isParkingCategory =
          _selectedCategory == 'Parking' || _selectedCategory == 'PARKING';
      if (!isSelectedTarget &&
          !isParkingCategory &&
          widget.currentFloor.floorNumber > 0) {
        if (poi.floorNumber < 0 ||
            poi.category.toUpperCase().contains('PARK')) {
          return false;
        }
      }

      return matchesSearch &&
          matchesFloor &&
          _matchesCategory(poi, _selectedCategory);
    }).toList();

    final activePOI = _isNavigatingActive ? _selectedPOI : null;

    // Compute navigation angle & distance to active target destination
    double activeBearing = 0.0;
    double activeRelAngle = 0.0;
    int activeDistM = 0;

    if (activePOI != null) {
      activeDistM = calculateAccurate3DDistance(
        effectiveUserCoords,
        activePOI.location,
        userFloorNumber: widget.currentFloor.floorNumber,
        targetFloorNumber: activePOI.floorNumber,
      ).round();
      activeBearing = calculateBearingAngle(
        effectiveUserCoords,
        activePOI.location,
      );
      activeRelAngle = activeBearing - fusedPose.headingDegrees;
      while (activeRelAngle > 180) {
        activeRelAngle -= 360;
      }
      while (activeRelAngle < -180) {
        activeRelAngle += 360;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Camera Pitch Motion Compensation:
    final pitchOffsetPx = (widget.phonePitchDegrees * (screenHeight / 40.0))
        .clamp(-250.0, 250.0);

    // Multi-Floor Spatial Collision Avoidance Layout Pass for Ambient Floating Cards
    const double topSafeLimit = 185.0;
    final double bottomSafeLimit = math.max(
      screenHeight - 230.0,
      topSafeLimit + 80.0,
    );
    final List<Map<String, dynamic>> positionedCards = [];

    for (int i = 0; i < filteredPOIs.length; i++) {
      final poi = filteredPOIs[i];
      int distM = calculateAccurate3DDistance(
        effectiveUserCoords,
        poi.location,
        userFloorNumber: widget.currentFloor.floorNumber,
        targetFloorNumber: poi.floorNumber,
      ).round();
      final bearing = calculateBearingAngle(effectiveUserCoords, poi.location);
      final directionStr = _getCardinalDirection(bearing);

      double relAngle = (bearing - fusedPose.headingDegrees);
      while (relAngle > 180) {
        relAngle -= 360;
      }
      while (relAngle < -180) {
        relAngle += 360;
      }

      // Accurate Optical Perspective Camera Projection (65° Horizontal FOV)
      final double hFovRad = (65.0 * math.pi) / 180.0;
      final double focalPx = (screenWidth / 2.0) / math.tan(hFovRad / 2.0);
      final double relAngleRad = (relAngle * math.pi) / 180.0;
      final double normX =
          math.tan(relAngleRad.clamp(-1.2, 1.2)) *
          (focalPx / (screenWidth * 0.5));
      double posX = (screenWidth / 2 - 92.5) + (normX * (screenWidth * 0.46));

      // Physically Realistic 3D AR Perspective & Pitch Mapping:
      // Distance Depth Offset: Farther places (higher distM) sit higher up towards the horizon.
      final double distHorizonOffset = (distM.clamp(5, 300) - 15.0) * 1.8;

      // Dynamic Camera Pitch Offset: Tilting UP (+ pitch) shifts horizon down, bringing far/upper places into view.
      final double pitchShiftPx = widget.phonePitchDegrees * 5.5;

      double posY;
      if (_floorFilterMode == ARFloorFilterMode.allFloors) {
        // Multi-floor spatial projection combining floor level + distance horizon + camera pitch tilt
        final double floorLevel = poi.floorNumber.toDouble().clamp(-2.0, 10.0);
        posY =
            (screenHeight * 0.50) -
            ((floorLevel - 1.0) * 28.0) -
            distHorizonOffset +
            pitchShiftPx;
      } else {
        // Single floor / Auto-tilt mode
        final double floorDelta = (poi.floorNumber - activeTargetFloorNumber)
            .toDouble();
        posY =
            (screenHeight * 0.50) -
            (floorDelta * 40.0) -
            distHorizonOffset +
            pitchShiftPx;
      }

      // Distance & Pitch Distance Sensitivity Opacity:
      double cardOpacity = 1.0;
      bool isPitchFocused = true;
      if (_floorFilterMode == ARFloorFilterMode.autoTilt) {
        isPitchFocused = (poi.floorNumber == activeTargetFloorNumber);
        final floorDelta = (poi.floorNumber - activeTargetFloorNumber).abs();
        if (floorDelta == 0) {
          cardOpacity = 1.0;
        } else if (floorDelta == 1) {
          cardOpacity = 0.75;
        } else {
          cardOpacity = 0.35;
        }
      } else if (_floorFilterMode == ARFloorFilterMode.allFloors) {
        // Distance-based fade for extreme far places unless camera is tilted up to view horizon
        if (distM > 100 && widget.phonePitchDegrees < 10.0) {
          cardOpacity = 0.60;
        } else {
          cardOpacity = 1.0;
        }
        isPitchFocused = true;
      }

      // Dynamic 3D Distance Scale Factor (Close = Larger 1.25x, Far = Smaller 0.65x):
      final double distanceScaleFactor = (1.20 - ((distM - 5.0) * 0.007)).clamp(
        0.65,
        1.25,
      );

      final spatialMetrics = calculateRealWorldSpatialMetrics(
        userCoords: effectiveUserCoords,
        targetCoords: poi.location,
        userFloorNumber: widget.currentFloor.floorNumber,
        targetFloorNumber: poi.floorNumber,
        floorWidthMeters: widget.currentFloor.floorWidthMeters,
        floorLengthMeters: widget.currentFloor.floorLengthMeters,
        ceilingHeightMeters: widget.currentFloor.ceilingHeightMeters,
      );

      positionedCards.add({
        'poi': poi,
        'distM': distM,
        'bearing': bearing,
        'directionStr': directionStr,
        'relAngle': relAngle,
        'posX': posX.clamp(12.0, screenWidth - 190.0),
        'posY': posY.clamp(topSafeLimit, bottomSafeLimit),
        'cardOpacity': cardOpacity,
        'isPitchFocused': isPitchFocused,
        'distanceScale': distanceScaleFactor,
        'spatialMetrics': spatialMetrics,
      });
    }

    // Multi-pass 2D Spatial Anti-Overlap Engine: Stacks & staggers cards cleanly without ANY overlap
    const double cardW = 185.0;
    const double cardH = 56.0;

    for (int pass = 0; pass < 4; pass++) {
      for (int i = 0; i < positionedCards.length; i++) {
        for (int j = 0; j < i; j++) {
          final p1 = positionedCards[i];
          final p2 = positionedCards[j];

          double x1 = p1['posX'] as double;
          double y1 = p1['posY'] as double;
          final double x2 = p2['posX'] as double;
          final double y2 = p2['posY'] as double;

          final double dx = (x1 - x2).abs();
          final double dy = (y1 - y2).abs();

          if (dx < cardW && dy < cardH) {
            final poi1 = p1['poi'] as DestinationPOI;
            final poi2 = p2['poi'] as DestinationPOI;

            if (poi1.floorNumber < poi2.floorNumber) {
              y1 = (y1 + (cardH - dy + 6.0)).clamp(
                topSafeLimit,
                bottomSafeLimit,
              );
            } else if (poi1.floorNumber > poi2.floorNumber) {
              y1 = (y1 - (cardH - dy + 6.0)).clamp(
                topSafeLimit,
                bottomSafeLimit,
              );
            } else {
              // Same floor: Stagger horizontally & vertically
              if (y1 <= y2) {
                y1 = (y2 - cardH - 6.0).clamp(topSafeLimit, bottomSafeLimit);
                if (y1 <= topSafeLimit + 2.0) {
                  x1 = (x2 + (i % 2 == 0 ? 110.0 : -110.0)).clamp(
                    12.0,
                    screenWidth - 190.0,
                  );
                  y1 = (y2 + cardH + 6.0).clamp(topSafeLimit, bottomSafeLimit);
                }
              } else {
                y1 = (y2 + cardH + 6.0).clamp(topSafeLimit, bottomSafeLimit);
              }
            }
            p1['posX'] = x1;
            p1['posY'] = y1;
          }
        }
      }
    }

    // Dynamic 3D AR Target Badge Screen Offset based on activeRelAngle & Pitch
    final normTargetX = (activeRelAngle / 30.0).clamp(-1.2, 1.2);
    final targetBadgePosX =
        (screenWidth / 2) + (normTargetX * (screenWidth * 0.35));
    final targetBadgePosY = ((screenHeight * 0.22) + (pitchOffsetPx * 0.5))
        .clamp(100.0, 240.0);

    // Sort positioned cards by distance and floor (farther dist first -> renders behind closer places)
    positionedCards.sort((a, b) {
      final poiA = a['poi'] as DestinationPOI;
      final poiB = b['poi'] as DestinationPOI;
      final isSameFloorA = poiA.floorNumber == widget.currentFloor.floorNumber;
      final isSameFloorB = poiB.floorNumber == widget.currentFloor.floorNumber;
      if (isSameFloorA != isSameFloorB) return isSameFloorA ? 1 : -1;

      final focusA = (a['isPitchFocused'] as bool) ? 1 : 0;
      final focusB = (b['isPitchFocused'] as bool) ? 1 : 0;
      if (focusA != focusB) return focusA.compareTo(focusB);

      // Farther places draw first (background), closer places draw last (foreground z-index)
      return (b['distM'] as int).compareTo(a['distM'] as int);
    });

    // Filter cards to visible camera FOV (relAngle.abs() <= 85°), and allow up to 35 places so all places display
    final double fovLimit = _floorFilterMode == ARFloorFilterMode.allFloors
        ? 90.0
        : 75.0;
    List<Map<String, dynamic>> visibleCardsInFOV = positionedCards
        .where((data) {
          final relAngle = (data['relAngle'] as double);
          return relAngle.abs() <= fovLimit;
        })
        .take(35)
        .toList();

    if (visibleCardsInFOV.isEmpty &&
        !_isNavigatingActive &&
        positionedCards.isNotEmpty) {
      visibleCardsInFOV = positionedCards.take(12).toList();
    }

    // Determine nearest store orientation for out-of-view spatial alert guidance
    double nearestRelAngle = 0.0;
    DestinationPOI? nearestPOI;
    if (positionedCards.isNotEmpty) {
      final sortedByDist = List<Map<String, dynamic>>.from(positionedCards)
        ..sort((a, b) {
          final pA = a['poi'] as DestinationPOI;
          final pB = b['poi'] as DestinationPOI;
          final groundA = pA.floorNumber > 0 ? 0 : 1;
          final groundB = pB.floorNumber > 0 ? 0 : 1;
          if (groundA != groundB) return groundA.compareTo(groundB);
          return (a['distM'] as int).compareTo(b['distM'] as int);
        });
      nearestRelAngle = sortedByDist.first['relAngle'] as double;
      nearestPOI = sortedByDist.first['poi'] as DestinationPOI;
    }

    final bool isPitchExtreme =
        widget.phonePitchDegrees < -25.0 || widget.phonePitchDegrees > 55.0;
    final bool isNoKnownPlacesInView =
        !_isNavigatingActive && visibleCardsInFOV.isEmpty;

    // Evaluate off-route compliance if active route is available
    if (_activeRoute != null && activePOI != null) {
      final compliance = _offRouteService.evaluateRouteCompliance(
        userCoords: fusedPose.position,
        userHeading: fusedPose.headingDegrees,
        activeRoute: _activeRoute!,
        currentWaypointIndex: 0,
      );
      if (compliance.isOffRoute || compliance.isWrongDirection) {
        // Trigger recalculated route
        _activeRoute = _routeService.calculateRoute(
          buildingId: 'mall-01',
          userCoords: fusedPose.position,
          currentFloor: widget.currentFloor.floorNumber,
          destination: activePOI,
        );
      }
    }

    final activeSpatialMetrics = activePOI != null
        ? calculateRealWorldSpatialMetrics(
            userCoords: fusedPose.position,
            targetCoords: activePOI.location,
            userFloorNumber: widget.currentFloor.floorNumber,
            targetFloorNumber: activePOI.floorNumber,
            floorWidthMeters: widget.currentFloor.floorWidthMeters,
            floorLengthMeters: widget.currentFloor.floorLengthMeters,
            ceilingHeightMeters: widget.currentFloor.ceilingHeightMeters,
          )
        : null;

    int cleanDistM = activeDistM;

    // Guidance text generation based on floor relation, vertical transitions, and turn action
    String guidanceText =
        '$turnActionStr • Walk $cleanDistM m to ${activePOI?.name ?? ''}';
    if (activePOI != null &&
        activePOI.floorNumber != widget.currentFloor.floorNumber) {
      final transitionType =
          activePOI.floorNumber > widget.currentFloor.floorNumber
          ? WaypointType.escalator
          : WaypointType.elevator;

      final transitionUpdate = _transitionService.evaluateTransitionStep(
        distanceToTransitionMeters: activeDistM.toDouble(),
        transitionType: transitionType,
        currentFloor: widget.currentFloor.floorNumber,
        targetFloor: activePOI.floorNumber,
      );
      guidanceText =
          '${transitionUpdate.instructionTitle} • ${transitionUpdate.instructionSubtitle}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        children: [
          // 1. Live Camera Feed / Viewport
          Positioned.fill(
            child:
                _isCameraInitialized &&
                    _cameraController != null &&
                    _cameraController!.value.isInitialized
                ? ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: screenWidth,
                        height:
                            screenWidth *
                            (_cameraController!.value.aspectRatio > 1.0
                                ? _cameraController!.value.aspectRatio
                                : 1 / _cameraController!.value.aspectRatio),
                        child: RepaintBoundary(
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF070F26),
                              Color(0xFF0F172A),
                              Color(0xFF030712),
                            ],
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: Size.infinite,
                        painter: ARViewfinderPainter(),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                color: Color(0xFF38BDF8),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aligning AR Camera Viewport',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Point your camera towards stores or walkways',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // 2. Ground AR Navigation Pathway (3D Perspective Chevrons on Camera Floor)
          if (activePOI != null && _isNavigatingActive)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: ARGroundPathwayPainter(
                    relativeAngleDegrees: activeRelAngle,
                    distanceMeters: activeDistM,
                    phonePitchDegrees: widget.phonePitchDegrees,
                    isParkedVehicle:
                        activePOI.category.toUpperCase().contains('PARK') ||
                        activePOI.name.toUpperCase().contains('CAR') ||
                        activePOI.name.toUpperCase().contains('PARKED'),
                  ),
                ),
              ),
            ),

          // 3. Floating 3D AR Distance Badge & Target Header (Active Navigation Mode - Visible when facing target)
          if (activePOI != null && _isNavigatingActive) ...[
            Builder(
              builder: (context) {
                final isParkedCar =
                    activePOI.category.toUpperCase().contains('PARK') ||
                    activePOI.name.toUpperCase().contains('CAR') ||
                    activePOI.name.toUpperCase().contains('PARKED');
                return Positioned(
                  left: (targetBadgePosX - 120).clamp(
                    16.0,
                    screenWidth - 256.0,
                  ),
                  top: targetBadgePosY,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing 3D AR Distance Box
                      Container(
                        width: 240,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isParkedCar
                                ? [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ]
                                : [
                                    const Color(0xFF00E5FF),
                                    const Color(0xFF00B0FF),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isParkedCar
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF00E5FF))
                                      .withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isParkedCar
                                      ? LucideIcons.car
                                      : LucideIcons.target,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    activePOI.name.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeSpatialMetrics?.euclidean3DDistanceMeters.toStringAsFixed(0) ?? activeDistM} M (3D)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: DeveloperModeNotifier.instance,
                              builder: (context, isDev, child) {
                                if (!isDev) {
                                  return Text(
                                    activePOI.floorNumber < 0 ? "Basement B${activePOI.floorNumber.abs()}" : "Floor ${activePOI.floorNumber}",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.95),
                                    ),
                                  );
                                }
                                return Column(
                                  children: [
                                    const SizedBox(height: 3),
                                    Text(
                                      '2D: ${activeSpatialMetrics?.horizontalHaversineDistMeters.toStringAsFixed(0) ?? activeDistM}m • Δh: ${activeSpatialMetrics != null && activeSpatialMetrics.elevationDeltaMeters >= 0 ? "+" : ""}${activeSpatialMetrics?.elevationDeltaMeters.toStringAsFixed(1) ?? "0.0"}m',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withValues(alpha: 0.95),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${activePOI.floorNumber < 0 ? "B${activePOI.floorNumber.abs()}" : "FLOOR ${activePOI.floorNumber}"} (${widget.currentFloor.floorWidthMeters.toStringAsFixed(0)}×${widget.currentFloor.floorLengthMeters.toStringAsFixed(0)}m)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Glowing Direction Chevrons (▲) rising to marker
                      Column(
                        children: List.generate(3, (idx) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              LucideIcons.chevronUp,
                              color:
                                  (isParkedCar
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF00E5FF))
                                      .withValues(alpha: 1.0 - (idx * 0.25)),
                              size: 20 - (idx * 2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          // 4. Ambient Floating AR Place Cards (rendered only when within camera horizontal FOV)
          if (!_isNavigatingActive)
            Positioned.fill(
              child: Stack(
                children: visibleCardsInFOV.map((data) {
                  final poi = data['poi'] as DestinationPOI;
                  final distM = data['distM'] as int;
                  final directionStr = data['directionStr'] as String;
                  final posX = data['posX'] as double;
                  final posY = data['posY'] as double;
                  final cardOpacity = (data['cardOpacity'] as double? ?? 1.0);
                  final isPitchFocused =
                      (data['isPitchFocused'] as bool? ?? true);
                  final cardScale = (data['distanceScale'] as double? ?? 1.0);

                  final isSelected = activePOI?.id == poi.id;

                  final cardMetrics =
                      data['spatialMetrics'] as RealWorldSpatialMetrics?;
                  final int dist3D =
                      cardMetrics?.euclidean3DDistanceMeters.round() ?? distM;

                  String floorRelationStr;
                  final String floorLabel = poi.floorNumber < 0
                      ? 'B${poi.floorNumber.abs()}'
                      : 'FLOOR ${poi.floorNumber}';
                  if (poi.floorNumber == widget.currentFloor.floorNumber) {
                    floorRelationStr = '$floorLabel • SAME FLOOR';
                  } else if (poi.floorNumber >
                      widget.currentFloor.floorNumber) {
                    floorRelationStr = '$floorLabel • ▲ UP';
                  } else {
                    floorRelationStr = '$floorLabel • ▼ DOWN';
                  }

                  return Positioned(
                    left: posX,
                    top: posY,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: cardOpacity,
                      child: Transform.scale(
                        scale: cardScale,
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPOI = poi;
                                  _isNavigatingActive = true;
                                });
                                widget.onSelectDestination(poi);
                              },
                              child: Container(
                                width: 195,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xEE090D16),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : (isPitchFocused
                                              ? const Color(0xFF38BDF8)
                                              : const Color(0xFF1E293B)),
                                    width: isSelected
                                        ? 2.0
                                        : (isPitchFocused ? 1.5 : 1.0),
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      const BoxShadow(
                                        color: Color(0x6610B981),
                                        blurRadius: 14,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            poi.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                LucideIcons.star,
                                                size: 10,
                                                color: Color(0xFFF59E0B),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${poi.rating} ★ • 3D: $dist3D m',
                                                style: const TextStyle(
                                                  color: Color(0xFFCBD5E1),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '$floorRelationStr • ${(widget.currentFloor.floorAreaSqMeters / 1000).toStringAsFixed(1)}k m²',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? const Color(0xFF34D399)
                                                  : (poi.floorNumber !=
                                                            widget
                                                                .currentFloor
                                                                .floorNumber
                                                        ? const Color(
                                                            0xFFF59E0B,
                                                          )
                                                        : const Color(
                                                            0xFF38BDF8,
                                                          )),
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Transform.rotate(
                                            angle:
                                                (data['relAngle'] as double) *
                                                (math.pi / 180.0),
                                            child: Icon(
                                              LucideIcons.navigation,
                                              size: 13,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF00E5FF),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            directionStr,
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            CustomPaint(
                              size: const Size(2, 20),
                              painter: DottedLinePainter(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : Colors.white,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // 4b. Real-World AR Spatial Alert Banners & Off-Screen Edge Direction Pointers
          // Case A: Camera Tilted Too Low or High (Pitch Alert)
          if (isPitchExtreme)
            Positioned(
              top: screenHeight * 0.38,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xEE1E1B4B),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF6366F1),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x666366F1), blurRadius: 18),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.phonePitchDegrees < -25.0
                            ? LucideIcons.arrowUp
                            : LucideIcons.arrowDown,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CAMERA TILTED ${widget.phonePitchDegrees < -25.0 ? "DOWNWARDS" : "UPWARDS"}',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Level phone upright to view real-world indoor floor AR overlays.',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFA5B4FC),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Case B: Ambient Discovery Mode - Known Places Not Visible in Camera FOV
          if (isNoKnownPlacesInView && !isPitchExtreme)
            Positioned(
              top: screenHeight * 0.36,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFA0F172A),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFF59E0B),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x55F59E0B), blurRadius: 20),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.compass,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NO KNOWN PLACES IN CAMERA VIEW',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                positionedCards.isNotEmpty
                                    ? 'Turn phone ${nearestRelAngle < 0 ? "LEFT ◀" : "RIGHT ▶"} (${nearestRelAngle.abs().toStringAsFixed(0)}°) to view ${nearestPOI?.name ?? "store"} (${nearestPOI?.category ?? ""} • ${nearestPOI != null && nearestPOI.floorNumber < 0 ? "B${nearestPOI.floorNumber.abs()}" : "Floor ${nearestPOI?.floorNumber ?? 1}"} • ${nearestPOI?.rating ?? 4.8}★)'
                                    : 'No stores on Floor ${activeTargetFloorNumber < 0 ? "B${activeTargetFloorNumber.abs()}" : activeTargetFloorNumber} matching filter.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFFFCD34D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (positionedCards.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              nearestRelAngle < 0
                                  ? LucideIcons.arrowLeft
                                  : LucideIcons.arrowRight,
                              color: const Color(0xFF38BDF8),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${positionedCards.length} STORES ON FLOORS 1-10 LOCATED ${nearestRelAngle < 0 ? "TO YOUR LEFT ◀" : "TO YOUR RIGHT ▶"} (${nearestPOI?.name.toUpperCase() ?? ""})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF38BDF8),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // 5. Top Controls & Navigation Guidance HUD Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Bar Actions (Back + Geometry Metrics Toggle)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          if (widget.onBackClicked != null)
                            GestureDetector(
                              onTap: widget.onBackClicked,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xDD0D1B2A),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.chevronLeft,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ValueListenableBuilder<bool>(
                            valueListenable: DeveloperModeNotifier.instance,
                            builder: (context, isDevMode, child) {
                              if (!isDevMode) return const SizedBox.shrink();
                              return Row(
                                children: [
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showGeometricTelemetryModal =
                                            !_showGeometricTelemetryModal;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _showGeometricTelemetryModal
                                            ? const Color(0xFF0284C7)
                                            : const Color(0xEE0F172A),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _showGeometricTelemetryModal
                                              ? const Color(0xFF38BDF8)
                                              : const Color(0xFF334155),
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x440284C7),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            LucideIcons.ruler,
                                            color: Color(0xFF38BDF8),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'FLOOR REAL DISTANCE & GEOMETRY',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            _showGeometricTelemetryModal
                                                ? LucideIcons.chevronUp
                                                : LucideIcons.chevronDown,
                                            color: Colors.white70,
                                            size: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Top Navigation Guidance Banner (STEP 1/3 + Red EXIT Button)
                    if (activePOI != null && _isNavigatingActive)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 14,
                          right: 14,
                          top: 4,
                          bottom: 6,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xEE032830),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF00E5FF,
                                    ).withValues(alpha: 0.6),
                                    width: 1.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x4400E5FF),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          /* const Text(
                                            '',
                                            style: TextStyle(
                                              color: Color(0xFF00E5FF),
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            // ), */
                                          // ),
                                          Text(
                                            guidanceText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Red EXIT Button
                            GestureDetector(
                              onTap: () => setState(() {
                                _isNavigatingActive = false;
                                _selectedPOI = null;
                                _activeRoute = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.x,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'EXIT',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Top Category Filter Chips Bar (when not navigating)
                    if (!_isNavigatingActive)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 14,
                          right: 14,
                          bottom: 6,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCategoryPill(
                                'All',
                                '${filteredPOIs.length}',
                                LucideIcons.globe,
                              ),
                              const SizedBox(width: 6),
                              _buildCategoryPill(
                                'Fashion',
                                'Apparel',
                                LucideIcons.shoppingBag,
                              ),
                              const SizedBox(width: 6),
                              _buildCategoryPill(
                                'Food',
                                'Dining',
                                LucideIcons.utensils,
                              ),
                              const SizedBox(width: 6),
                              _buildCategoryPill(
                                'Tech',
                                'Gadgets',
                                LucideIcons.laptop,
                              ),
                              const SizedBox(width: 6),
                              _buildCategoryPill(
                                'Luxury',
                                'Boutique',
                                LucideIcons.sparkles,
                              ),
                              const SizedBox(width: 6),
                              _buildCategoryPill(
                                'Services',
                                'Info',
                                LucideIcons.headphones,
                              ),
                              const SizedBox(width: 6),
                              _buildCategoryPill(
                                'Parking',
                                'Slots',
                                LucideIcons.parkingCircle,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 6. Active Navigation Mode Drawer & Controls
          Positioned(
            left: 12,
            right: 12,
            bottom: 6,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active Place Navigation Sheet ("SELECTED: [STORE NAME]")
                  if (activePOI != null && _isNavigatingActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFC0B132B),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF1E293B),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Row 1: Header + Store Name + Favourite
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00E5FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                activePOI.category.toUpperCase().contains(
                                          'PARK',
                                        ) ||
                                        activePOI.name.toUpperCase().contains(
                                          'CAR',
                                        ) ||
                                        activePOI.name.toUpperCase().contains(
                                          'PARKED',
                                        )
                                    ? '● PARKED CAR:'
                                    : '● SELECTED:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color:
                                      activePOI.category.toUpperCase().contains(
                                            'PARK',
                                          ) ||
                                          activePOI.name.toUpperCase().contains(
                                            'CAR',
                                          ) ||
                                          activePOI.name.toUpperCase().contains(
                                            'PARKED',
                                          )
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF00E5FF),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  activePOI.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _isFavorite = !_isFavorite),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.heart,
                                        size: 11,
                                        color: _isFavorite
                                            ? const Color(0xFFEF4444)
                                            : Colors.white70,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Fav',
                                        style: TextStyle(
                                          color: _isFavorite
                                              ? const Color(0xFFEF4444)
                                              : Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Row 2: Specs & Primary Action Button
                          Row(
                            children: [
                              // Left side specs
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.star,
                                      size: 11,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${activePOI.rating}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      LucideIcons.ruler,
                                      size: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '3D: ${activeSpatialMetrics?.euclidean3DDistanceMeters.toStringAsFixed(0) ?? activeDistM}m',
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () =>
                                          _showPoiDetailsModal(activePOI),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF334155),
                                          ),
                                        ),
                                        child: const Text(
                                          'INFO',
                                          style: TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Right side: Real-World AR Wayfinding Toggle Button
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isNavigatingActive = !_isNavigatingActive;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: _isNavigatingActive
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF00E5FF),
                                              Color(0xFF00B0FF),
                                            ],
                                          )
                                        : const LinearGradient(
                                            colors: [
                                              Color(0xFF2563EB),
                                              Color(0xFF1D4ED8),
                                            ],
                                          ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_isNavigatingActive
                                                    ? const Color(0xFF00E5FF)
                                                    : const Color(0xFF2563EB))
                                                .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isNavigatingActive
                                            ? LucideIcons.navigation2
                                            : LucideIcons.compass,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isNavigatingActive
                                            ? 'NAVIGATING'
                                            : 'START AR NAV',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Progress Line
                          Container(
                            height: 2.5,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(1.25),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.35,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF),
                                  borderRadius: BorderRadius.circular(1.25),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 7. Real-World Geometric Calculations & AR Floor Size Data Panel
          if (_showGeometricTelemetryModal)
            _buildGeometricTelemetryOverlay(
              activeSpatialMetrics,
              geodeticToECEF(effectiveUserCoords),
            ),
        ],
      ),
    );
  }

  Widget _buildGeometricTelemetryOverlay(
    RealWorldSpatialMetrics? activeMetrics,
    ECEFCoords userECEF,
  ) {
    final floor = widget.currentFloor;
    final metrics =
        activeMetrics ??
        RealWorldSpatialMetrics(
          horizontalHaversineDistMeters: 0.0,
          elevationDeltaMeters: 0.0,
          euclidean3DDistanceMeters: 0.0,
          distanceFromGroundMeters: (floor.floorNumber - 1).abs() * 4.5,
          estimatedWalkTimeSeconds: 0.0,
          floorWidthMeters: floor.floorWidthMeters,
          floorLengthMeters: floor.floorLengthMeters,
          floorAreaSqMeters: floor.floorAreaSqMeters,
          ceilingHeightMeters: floor.ceilingHeightMeters,
        );

    return Positioned(
      top: 90,
      left: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFA090D16),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x660284C7), blurRadius: 18),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.binary,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'REAL-WORLD AR GEOMETRY & FLOOR METRICS',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _showGeometricTelemetryModal = false),
                  child: const Icon(
                    LucideIcons.x,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 10),

            // Section 1: Real Floor Size & Bounds
            Text(
              'REAL FLOOR SIZE & BOUNDS (FLOOR ${floor.floorNumber})',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF38BDF8),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildMetricMiniCard(
                    'FLOOR DIMENSIONS',
                    '${floor.floorWidthMeters.toStringAsFixed(0)}m × ${floor.floorLengthMeters.toStringAsFixed(0)}m',
                    LucideIcons.maximize2,
                    const Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricMiniCard(
                    'SURFACE AREA',
                    '${floor.floorAreaSqMeters.toStringAsFixed(0)} m²',
                    LucideIcons.box,
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildMetricMiniCard(
                    'CEILING CLEARANCE',
                    '${floor.ceilingHeightMeters.toStringAsFixed(1)} m',
                    LucideIcons.arrowUpFromLine,
                    const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricMiniCard(
                    'GROUND ELEVATION',
                    '${floor.absoluteHeightMeters.toStringAsFixed(1)}m AMSL',
                    LucideIcons.layers,
                    const Color(0xFFA855F7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              'REAL-WORLD DISTANCE CALCULATIONS (ECEF & HAVERSINE 3D)',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF38BDF8),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                children: [
                  _buildMathRow(
                    '2D Horizontal Planar Dist (d_2D):',
                    '${metrics.horizontalHaversineDistMeters.toStringAsFixed(2)} m',
                  ),
                  const SizedBox(height: 4),
                  _buildMathRow(
                    'Vertical Elevation Delta (Δh):',
                    '${metrics.elevationDeltaMeters >= 0 ? "+" : ""}${metrics.elevationDeltaMeters.toStringAsFixed(2)} m',
                  ),
                  const SizedBox(height: 4),
                  _buildMathRow(
                    '3D Euclidean Distance (d_3D):',
                    '${metrics.euclidean3DDistanceMeters.toStringAsFixed(2)} m',
                    isHighlight: true,
                  ),
                  const SizedBox(height: 4),
                  _buildMathRow(
                    'Ground Reference Delta:',
                    '${metrics.distanceFromGroundMeters.toStringAsFixed(1)} m from Floor 1 Ground',
                  ),
                  const SizedBox(height: 4),
                  _buildMathRow(
                    'Est. Real Walk Pace:',
                    '${(metrics.estimatedWalkTimeSeconds / 60).toStringAsFixed(1)} min (${metrics.estimatedWalkTimeSeconds.toStringAsFixed(0)}s @ 1.4m/s)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'ECEF Spatial Vector: X=${userECEF.x.toStringAsFixed(0)}m, Y=${userECEF.y.toStringAsFixed(0)}m, Z=${userECEF.z.toStringAsFixed(0)}m',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricMiniCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMathRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isHighlight
                ? const Color(0xFF38BDF8)
                : const Color(0xFFCBD5E1),
            fontSize: 9.5,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: isHighlight ? const Color(0xFF34D399) : Colors.white,
            fontSize: 10.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill(String title, String count, IconData icon) {
    bool isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : const Color(0xDD0D1B2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF14B8A6)
                : const Color(0xFF1E293B),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              '$title • $count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCardinalDirection(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'N';
    if (deg >= 22.5 && deg < 67.5) return 'NE';
    if (deg >= 67.5 && deg < 112.5) return 'E';
    if (deg >= 112.5 && deg < 157.5) return 'SE';
    if (deg >= 157.5 && deg < 202.5) return 'S';
    if (deg >= 202.5 && deg < 247.5) return 'SW';
    if (deg >= 247.5 && deg < 292.5) return 'W';
    return 'NW';
  }
}

class ARGroundPathwayPainter extends CustomPainter {
  final double relativeAngleDegrees;
  final int distanceMeters;
  final double phonePitchDegrees;
  final bool isParkedVehicle;

  ARGroundPathwayPainter({
    required this.relativeAngleDegrees,
    required this.distanceMeters,
    this.phonePitchDegrees = 0.0,
    this.isParkedVehicle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pitchShift = (phonePitchDegrees * 3.0).clamp(-120.0, 120.0);
    final centerBottom = Offset(size.width / 2, size.height - 110);

    final normX = (relativeAngleDegrees / 45.0).clamp(-1.0, 1.0);
    final targetTop = Offset(
      (size.width / 2) + (normX * (size.width * 0.35)),
      (size.height * 0.52) + pitchShift,
    );

    final primaryColor = isParkedVehicle
        ? const Color(0xFF10B981)
        : const Color(0xFF00E5FF);

    // 1. Sleek Laser Guide Beam with smooth gradient alpha fade
    final guideShader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        primaryColor.withValues(alpha: 0.65),
        isParkedVehicle
            ? const Color(0xFF34D399).withValues(alpha: 0.40)
            : const Color(0xFF10B981).withValues(alpha: 0.40),
        primaryColor.withValues(alpha: 0.15),
      ],
    ).createShader(Rect.fromPoints(centerBottom, targetTop));

    final guidePaint = Paint()
      ..shader = guideShader
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(centerBottom.dx, centerBottom.dy)
      ..lineTo(targetTop.dx, targetTop.dy);

    canvas.drawPath(path, guidePaint);

    // 2. Destination Ground Target Landing Ring
    final targetRingPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final targetRingGlow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawOval(
      Rect.fromCenter(center: targetTop, width: 32, height: 14),
      targetRingGlow,
    );
    canvas.drawOval(
      Rect.fromCenter(center: targetTop, width: 32, height: 14),
      targetRingPaint,
    );

    // 3. Modern Sleek Slender AR HUD Chevrons
    const int numChevrons = 5;
    for (int i = 1; i <= numChevrons; i++) {
      double t = i / (numChevrons + 1);
      double cx = centerBottom.dx + (targetTop.dx - centerBottom.dx) * t;
      double cy = centerBottom.dy + (targetTop.dy - centerBottom.dy) * t;

      // Perspective scaling: refined small scale (0.35 near horizon to 0.70 near user)
      double scale = 0.35 + (1.0 - t) * 0.35;
      double alpha = (1.0 - (t * 0.65)).clamp(0.20, 0.95);

      canvas.save();
      canvas.translate(cx, cy);

      // Rotate matching relative turn direction
      final arrowAngle = (relativeAngleDegrees * (math.pi / 180.0)).clamp(
        -0.8,
        0.8,
      );
      canvas.rotate(arrowAngle);

      // Aerodynamic Slender Chevron Path
      final chevronPath = Path()
        ..moveTo(-10 * scale, 6 * scale)
        ..lineTo(0, -6 * scale)
        ..lineTo(10 * scale, 6 * scale)
        ..lineTo(7 * scale, 6 * scale)
        ..lineTo(0, -2.5 * scale)
        ..lineTo(-7 * scale, 6 * scale)
        ..close();

      // Outer cyan neon glow
      final glowPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: alpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      // Primary gradient filled sleek chevron
      final fillPaint = Paint()
        ..color = Color.lerp(
          const Color(0xFF00E5FF),
          const Color(0xFF10B981),
          t,
        )!.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawPath(chevronPath, glowPaint);
      canvas.drawPath(chevronPath, fillPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ARGroundPathwayPainter oldDelegate) {
    return oldDelegate.relativeAngleDegrees != relativeAngleDegrees ||
        oldDelegate.distanceMeters != distanceMeters ||
        oldDelegate.phonePitchDegrees != phonePitchDegrees ||
        oldDelegate.isParkedVehicle != isParkedVehicle;
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, math.min(startY + dashHeight, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ARViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.20)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Horizon reticle
    canvas.drawLine(Offset(cx - 30, cy), Offset(cx + 30, cy), paint);
    canvas.drawLine(Offset(cx, cy - 30), Offset(cx, cy + 30), paint);
    canvas.drawCircle(Offset(cx, cy), 18, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
