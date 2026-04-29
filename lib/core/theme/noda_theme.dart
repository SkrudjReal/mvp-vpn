import 'package:flutter/material.dart';

extension NodaTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Solid Premium Dark Mode
  // Based on new Deep Neon React design spec
  Color get nodaBgDark => const Color(0xFF0A0F1A);
  Color get nodaSurfaceDark => const Color(0xFF070A11);
  Color get nodaSurfaceSoftDark => const Color(0xFF101520);
  Color get nodaBorderDark => Colors.white.withValues(alpha: 0.05);
  Color get nodaMutedDark => const Color(0xFF6B7280);
  Color get nodaTextDark => const Color(0xFFFFFFFF);

  // Solid Premium Light Mode
  // Pure elegant white with soft borders
  Color get nodaBgLight => const Color(0xFFF4F4F5);
  Color get nodaSurfaceLight => const Color(0xFFFFFFFF);
  Color get nodaSurfaceSoftLight => const Color(0xFFF4F4F5);
  Color get nodaBorderLight => const Color(0xFFE4E4E7);
  Color get nodaMutedLight => const Color(0xFF71717A);
  Color get nodaTextLight => const Color(0xFF09090B);

  // Dynamic Getters
  Color get nodaBg => isDark ? nodaBgDark : nodaBgLight;
  Color get nodaSurface => isDark ? nodaSurfaceDark : nodaSurfaceLight;
  Color get nodaSurfaceSoft => isDark ? nodaSurfaceSoftDark : nodaSurfaceSoftLight;
  Color get nodaBorder => isDark ? nodaBorderDark : nodaBorderLight;
  Color get nodaMuted => isDark ? nodaMutedDark : nodaMutedLight;
  Color get nodaText => isDark ? nodaTextDark : nodaTextLight;

  // Accents
  Color get nodaNeon => isDark ? const Color(0xFF00BFFF) : const Color(0xFF00B4D8);
  Color get nodaNeonSoft =>
      isDark ? const Color(0xFF00BFFF).withValues(alpha: 0.15) : const Color(0xFF00B4D8).withValues(alpha: 0.5);
}
