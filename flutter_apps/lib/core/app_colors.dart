import 'package:flutter/material.dart';

/// Centralized color palette for the Inventory Audit Pro app.
/// Redesigned with a clean, light 2019-style Gojek-inspired visual language.
class AppColors {
  AppColors._();

  // Background & Surface
  static const Color background = Color(0xFFFAFAFA);
  static const Color backgroundLight = Color(0xFFF3F4F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF9FAFB);
  static const Color surfaceBright = Color(0xFFF3F4F6);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFF9FAFB);

  // Overlay / border
  static const Color glassWhite = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0xFFE5E7EB);
  static const Color glassBorderLight = Color(0xFFF3F4F6);
  static const Color glassOverlay = Color(0x05000000);

  // Primary (Gojek Green)
  static const Color primary = Color(0xFF00AA13);
  static const Color primaryLight = Color(0xFF00C21B);
  static const Color primaryDark = Color(0xFF00880E);
  static const Color primaryGlow = Color(0x1A00AA13);
  static const Color primaryMuted = Color(0x0D00AA13);

  // Secondary (Forest Green)
  static const Color secondary = Color(0xFF0F8040);
  static const Color secondaryLight = Color(0xFF1B9E53);
  static const Color secondaryDark = Color(0xFF0A5C2D);

  // Text
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1A10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1AF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1AEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0x1A3B82F6);

  // Gradients (Flattened to solid colors for 2019 style consistency)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAFAFA), Color(0xFFFAFAFA)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00AA13), Color(0xFF00AA13)],
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF00AA13), Color(0xFF00AA13)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
  );

  // Dividers
  static const Color divider = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFF3F4F6);

  // Bottom nav
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navActive = Color(0xFF00AA13);
  static const Color navInactive = Color(0xFF6B7280);

  // Shadows (Soft, simple 2019-style shadows)
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> primaryGlowShadow = [
    BoxShadow(
      color: Color(0x1400AA13),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
