import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  final AppThemeMode mode;
  final String fontFamily;

  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    final ColorScheme scheme = lightColorScheme ?? _lightScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      cardTheme: _cardTheme(scheme),
      appBarTheme: _appBarTheme(scheme),
      navigationRailTheme: _navigationRailTheme(scheme),
      navigationBarTheme: _navigationBarTheme(scheme),
      filledButtonTheme: _filledButtonTheme(scheme),
      floatingActionButtonTheme: _floatingActionButtonTheme(scheme),
      inputDecorationTheme: _inputDecorationTheme(scheme),
      listTileTheme: _listTileTheme(scheme),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: .32)),
      textTheme: _textTheme(ThemeData.light().textTheme, scheme),
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.light},
    );
  }

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    final ColorScheme scheme = darkColorScheme ?? _darkScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      cardTheme: _cardTheme(scheme),
      appBarTheme: _appBarTheme(scheme),
      navigationRailTheme: _navigationRailTheme(scheme),
      navigationBarTheme: _navigationBarTheme(scheme),
      filledButtonTheme: _filledButtonTheme(scheme),
      floatingActionButtonTheme: _floatingActionButtonTheme(scheme),
      inputDecorationTheme: _inputDecorationTheme(scheme),
      listTileTheme: _listTileTheme(scheme),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: .28)),
      textTheme: _textTheme(ThemeData.dark().textTheme, scheme),
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.light},
    );
  }

  CupertinoThemeData cupertinoThemeData(bool sysDark, ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
    final bool isDark = switch (mode) {
      AppThemeMode.system => sysDark,
      AppThemeMode.light => false,
      AppThemeMode.dark => true,
      AppThemeMode.black => true,
    };
    final def = CupertinoThemeData(brightness: isDark ? Brightness.dark : Brightness.light);
    // final def = CupertinoThemeData(brightness: Brightness.dark);

    // return def;
    final defaultMaterialTheme = isDark ? darkTheme(darkColorScheme) : lightTheme(lightColorScheme);
    return MaterialBasedCupertinoThemeData(
      materialTheme: defaultMaterialTheme.copyWith(
        cupertinoOverrideTheme: def.copyWith(
          textTheme: CupertinoTextThemeData(
            textStyle: def.textTheme.textStyle.copyWith(fontFamily: fontFamily),
            actionTextStyle: def.textTheme.actionTextStyle.copyWith(fontFamily: fontFamily),
            navActionTextStyle: def.textTheme.navActionTextStyle.copyWith(fontFamily: fontFamily),
            navTitleTextStyle: def.textTheme.navTitleTextStyle.copyWith(fontFamily: fontFamily),
            navLargeTitleTextStyle: def.textTheme.navLargeTitleTextStyle.copyWith(fontFamily: fontFamily),
            pickerTextStyle: def.textTheme.pickerTextStyle.copyWith(fontFamily: fontFamily),
            dateTimePickerTextStyle: def.textTheme.dateTimePickerTextStyle.copyWith(fontFamily: fontFamily),
            tabLabelTextStyle: def.textTheme.tabLabelTextStyle.copyWith(fontFamily: fontFamily),
          ).copyWith(),
          barBackgroundColor: def.barBackgroundColor,
          scaffoldBackgroundColor: def.scaffoldBackgroundColor,
        ),
      ),
    );
  }

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF5A58F2),
    onPrimary: Colors.white,
    secondary: Color(0xFF1ECCA2),
    onSecondary: Color(0xFF082017),
    tertiary: Color(0xFF88A4FF),
    onTertiary: Color(0xFF07142E),
    error: Color(0xFFCE3A5D),
    onError: Colors.white,
    surface: Color(0xFFF5F7FF),
    onSurface: Color(0xFF12192D),
    surfaceContainer: Color(0xFFEFF2FF),
    surfaceContainerHighest: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFF47506A),
    outline: Color(0xFFCCD3EA),
    outlineVariant: Color(0xFFDCE1F2),
    shadow: Color(0x1A0E1323),
    scrim: Color(0x330A0E1A),
    inverseSurface: Color(0xFF141B31),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFF9898FF),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7A7CFF),
    onPrimary: Color(0xFF0C1020),
    secondary: Color(0xFF27D9AA),
    onSecondary: Color(0xFF062018),
    tertiary: Color(0xFF99B6FF),
    onTertiary: Color(0xFF081126),
    error: Color(0xFFFF6C8B),
    onError: Color(0xFF29030E),
    surface: Color(0xFF0C1120),
    onSurface: Color(0xFFF5F7FF),
    surfaceContainer: Color(0xFF10182C),
    surfaceContainerHighest: Color(0xFF16203A),
    onSurfaceVariant: Color(0xFFB2BEDA),
    outline: Color(0xFF2A365A),
    outlineVariant: Color(0xFF1E2741),
    shadow: Color(0x66000000),
    scrim: Color(0x80000000),
    inverseSurface: Color(0xFFF5F7FF),
    onInverseSurface: Color(0xFF111827),
    inversePrimary: Color(0xFF4F46E5),
  );

  static CardThemeData _cardTheme(ColorScheme scheme) => CardThemeData(
    elevation: 0,
    color: scheme.surfaceContainerHighest.withValues(alpha: scheme.brightness == Brightness.dark ? 0.78 : 0.96),
    shadowColor: scheme.shadow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
    ),
    margin: EdgeInsets.zero,
  );

  static AppBarTheme _appBarTheme(ColorScheme scheme) => AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: scheme.onSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: scheme.onSurface,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
  );

  static NavigationRailThemeData _navigationRailTheme(ColorScheme scheme) => NavigationRailThemeData(
    backgroundColor: Colors.transparent,
    indicatorColor: scheme.primary.withValues(alpha: scheme.brightness == Brightness.dark ? 0.18 : 0.12),
    selectedIconTheme: IconThemeData(color: scheme.primary),
    unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    selectedLabelTextStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
    unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
    useIndicator: true,
  );

  static NavigationBarThemeData _navigationBarTheme(ColorScheme scheme) => NavigationBarThemeData(
    backgroundColor: Colors.transparent,
    indicatorColor: scheme.primary.withValues(alpha: scheme.brightness == Brightness.dark ? 0.20 : 0.14),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return IconThemeData(color: selected ? scheme.primary : scheme.onSurfaceVariant);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return TextStyle(
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      );
    }),
  );

  static FilledButtonThemeData _filledButtonTheme(ColorScheme scheme) => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );

  static FloatingActionButtonThemeData _floatingActionButtonTheme(ColorScheme scheme) => FloatingActionButtonThemeData(
    backgroundColor: scheme.primary,
    foregroundColor: scheme.onPrimary,
    extendedTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  );

  static InputDecorationTheme _inputDecorationTheme(ColorScheme scheme) => InputDecorationTheme(
    filled: true,
    fillColor: scheme.surfaceContainerHighest.withValues(alpha: scheme.brightness == Brightness.dark ? 0.72 : 0.96),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: scheme.primary, width: 1.4),
    ),
  );

  static ListTileThemeData _listTileTheme(ColorScheme scheme) => ListTileThemeData(
    iconColor: scheme.onSurfaceVariant,
    textColor: scheme.onSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) => base.copyWith(
    headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, color: scheme.onSurface),
    headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4, color: scheme.onSurface),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
    bodyLarge: base.bodyLarge?.copyWith(height: 1.35, color: scheme.onSurface),
    bodyMedium: base.bodyMedium?.copyWith(height: 1.35, color: scheme.onSurfaceVariant),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}
