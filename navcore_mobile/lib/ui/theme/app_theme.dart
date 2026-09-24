import 'package:flutter/material.dart';

/// Global notifier for developer / technical telemetry mode.
/// By default, Developer Mode is OFF for a clean, human-friendly user experience.
class DeveloperModeNotifier extends ValueNotifier<bool> {
  DeveloperModeNotifier._() : super(false);
  static final DeveloperModeNotifier instance = DeveloperModeNotifier._();

  bool get isDeveloperMode => value;

  void toggle() {
    value = !value;
  }

  void setDeveloperMode(bool enabled) {
    value = enabled;
  }
}

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color primaryBorder = Color(0xFFBFDBFE);

  static const Color accent = Color(0xFF10B981); // Emerald Green
  static const Color accentLight = Color(0xFFECFDF5);

  // Surface colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardSurface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
