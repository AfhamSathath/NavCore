import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = true),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.gamepad2, color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(
                  'Move Controls',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.gamepad2, color: Color(0xFF38BDF8), size: 12),
              const SizedBox(width: 4),
              Text(
                'D-PAD',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => setState(() => _isExpanded = false),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF334155), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF38BDF8),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

