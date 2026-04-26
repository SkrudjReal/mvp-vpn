import 'package:flutter/material.dart';

extension NodaTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Solid Premium Dark Mode
  // Clean deep grey/black background, elevated soft surfaces.
  Color get nodaBgDark => const Color(0xFF09090B);
  Color get nodaSurfaceDark => const Color(0xFF18181B);
  Color get nodaSurfaceSoftDark => const Color(0xFF27272A);
  Color get nodaBorderDark => const Color(0xFF27272A);
  Color get nodaMutedDark => const Color(0xFFA1A1AA);
  Color get nodaTextDark => const Color(0xFFFAFAFA);
  
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

  // Accents (Neon blue remains vibrant)
  Color get nodaNeon => isDark ? const Color(0xFF00E5FF) : const Color(0xFF00B4D8);
  Color get nodaNeonSoft => isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : const Color(0xFF00B4D8).withValues(alpha: 0.5);
}
