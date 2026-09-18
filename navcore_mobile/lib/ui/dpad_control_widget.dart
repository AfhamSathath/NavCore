import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// High-performance D-Pad simulation control for testing 2D Map & AR indoor navigation workflows
class DpadControlWidget extends StatefulWidget {
  final Function(double deltaLat, double deltaLon) onSimulateMove;
  final double stepSize;

  const DpadControlWidget({
    super.key,
    required this.onSimulateMove,
    this.stepSize = 0.00004,
  });

  @override
  State<DpadControlWidget> createState() => _DpadControlWidgetState();
}

class _DpadControlWidgetState extends State<DpadControlWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return InkWell(
        onTap: () => setState(() => _isExpanded = true),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332563EB),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.gamepad2, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Move Controls',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'D-Pad',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 20),
              InkWell(
                onTap: () => setState(() => _isExpanded = false),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(LucideIcons.x, size: 14, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // UP BUTTON (North)
          _buildDpadBtn(
            icon: LucideIcons.arrowUp,
            tooltip: 'Move North',
            onTap: () => widget.onSimulateMove(widget.stepSize, 0),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // LEFT BUTTON (West)
              _buildDpadBtn(
                icon: LucideIcons.arrowLeft,
                tooltip: 'Move West',
                onTap: () => widget.onSimulateMove(0, -widget.stepSize),
              ),
              const SizedBox(width: 6),
              // RIGHT BUTTON (East)
              _buildDpadBtn(
                icon: LucideIcons.arrowRight,
                tooltip: 'Move East',
                onTap: () => widget.onSimulateMove(0, widget.stepSize),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // DOWN BUTTON (South)
          _buildDpadBtn(
            icon: LucideIcons.arrowDown,
            tooltip: 'Move South',
            onTap: () => widget.onSimulateMove(-widget.stepSize, 0),
          ),
        ],
      ),
    );
  }

  Widget _buildDpadBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x332563EB),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

