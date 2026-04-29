import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/adaptive_layout/shell_route_action.dart';
import 'package:hiddify/core/router/go_router/routing_config_notifier.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/core/widget/noda_chrome.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({super.key, required this.navigationShell, required this.isMobileBreakpoint});

  final StatefulNavigationShell navigationShell;
  final bool isMobileBreakpoint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final primaryFocusHash = useState<int?>(null);
    final navScopeNode = useFocusScopeNode();

    useEffect(() {
      bool handler(KeyEvent event) {
        final arrows = isMobileBreakpoint ? KeyboardConst.verticalArrows : KeyboardConst.horizontalArrows;
        if (!arrows.contains(event.logicalKey)) return false;
        if (event is KeyDownEvent) {
          primaryFocusHash.value = FocusManager.instance.primaryFocus.hashCode;
        } else if (primaryFocusHash.value == FocusManager.instance.primaryFocus.hashCode) {
          if (branchesScope.values.any((node) => node.hasFocus)) {
            navScopeNode.requestFocus();
          } else if (navScopeNode.hasFocus) {
            branchesScope[getNameOfBranch(isMobileBreakpoint, navigationShell.currentIndex)]?.requestFocus();
          }
        }
        return true;
      }

      HardwareKeyboard.instance.addHandler(handler);
      return () => HardwareKeyboard.instance.removeHandler(handler);
    }, [isMobileBreakpoint, navigationShell.currentIndex]);

    return Material(
      child: Scaffold(
        body: AppShellBackground(
          showMap: true,
          child: isMobileBreakpoint || navigationShell.currentIndex == 0
              ? navigationShell
              : Row(
                  children: [
                    Container(
                      width: 84,
                      decoration: BoxDecoration(
                        color: context.nodaSurface,
                        border: Border(right: BorderSide(color: context.nodaBorder)),
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Text(
                              'noda.',
                              style: GoogleFonts.cookie(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                                color: context.nodaText,
                                shadows: [Shadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 10)],
                              ),
                            ),
                            const SizedBox(height: 46),
                            Expanded(
                              child: FocusScope(
                                node: navScopeNode,
                                child: NavigationRailTheme(
                                  data: NavigationRailThemeData(
                                    backgroundColor: Colors.transparent,
                                    indicatorColor: Colors.transparent,
                                    selectedIconTheme: IconThemeData(color: context.nodaNeon, size: 18),
                                    unselectedIconTheme: IconThemeData(color: context.nodaMuted, size: 18),
                                    labelType: NavigationRailLabelType.none,
                                  ),
                                  child: NavigationRail(
                                    minWidth: 80,
                                    groupAlignment: -1,
                                    destinations: _navRailDests(_actions(t, isMobileBreakpoint)),
                                    selectedIndex: navigationShell.currentIndex,
                                    onDestinationSelected: (index) => _onTap(context, index),
                                    leading: const SizedBox.shrink(),
                                    trailing: Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 24),
                                          child: _RailThemeButton(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 320.ms).slideX(begin: -.05, end: 0).scaleXY(begin: .985, end: 1),
                    Expanded(
                      child: navigationShell,
                    ).animate().fadeIn(duration: 320.ms, delay: 50.ms).slideX(begin: .03, end: 0),
                  ],
                ),
        ),
        bottomNavigationBar: isMobileBreakpoint
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.nodaSurface.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.nodaBorder),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10))],
                    ),
                    child: FocusScope(
                      node: navScopeNode,
                      child: NavigationBar(
                        backgroundColor: Colors.transparent,
                        indicatorColor: context.nodaNeon.withValues(alpha: .22),
                        selectedIndex: navigationShell.currentIndex <= 1 ? navigationShell.currentIndex : 0,
                        destinations: _navDests(_actions(t, isMobileBreakpoint)),
                        onDestinationSelected: (index) => _onTap(context, index),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  List<ShellRouteAction> _actions(Translations t, bool isMobileBreakpoint) => [
    ShellRouteAction(Icons.power_settings_new_rounded, t.pages.home.title),
    ShellRouteAction(Icons.settings_rounded, t.pages.settings.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.info_rounded, t.pages.about.title),
  ];

  List<NavigationDestination> _navDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationDestination(icon: Icon(e.icon), label: e.title)).toList();

  List<NavigationRailDestination> _navRailDests(List<ShellRouteAction> actions) => actions
      .map(
        (e) => NavigationRailDestination(
          icon: _RailIcon(icon: e.icon, active: false),
          selectedIcon: _RailIcon(icon: e.icon, active: true),
          label: Text(e.title),
        ),
      )
      .toList();
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 180.ms,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? context.nodaSurfaceSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: active
            ? Border.all(color: context.nodaNeon.withValues(alpha: 0.6))
            : Border.all(color: Colors.transparent),
        boxShadow: active
            ? [
                BoxShadow(color: context.nodaNeon.withValues(alpha: 0.15), blurRadius: 15, blurStyle: BlurStyle.inner),
                BoxShadow(color: context.nodaNeon.withValues(alpha: 0.4), blurRadius: 15),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: active ? context.nodaNeon : Colors.grey.shade500,
        shadows: active && Theme.of(context).brightness == Brightness.dark
            ? [Shadow(color: context.nodaNeon.withValues(alpha: 0.8), blurRadius: 5)]
            : [],
      ),
    );
  }
}

class _RailThemeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.grey.shade500),
      onPressed: () {
        final currentTheme = ref.read(themePreferencesProvider);
        ref
            .read(themePreferencesProvider.notifier)
            .changeThemeMode(currentTheme == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark);
      },
    );
  }
}
