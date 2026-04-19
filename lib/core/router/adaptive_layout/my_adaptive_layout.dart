import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/adaptive_layout/shell_route_action.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/router/go_router/routing_config_notifier.dart';
import 'package:hiddify/core/widget/noda_chrome.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({
    super.key,
    required this.navigationShell,
    required this.isMobileBreakpoint,
  });

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
          child: isMobileBreakpoint
              ? navigationShell
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: Breakpoint(context).isDesktop() ? 320 : 96,
                        child: NodaPanel(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          radius: 32,
                          color: const Color(0xFF0B1629),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -64,
                                left: -56,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFF3D9BFF).withValues(alpha: 0.14),
                                          const Color(0xFF3D9BFF).withValues(alpha: 0.04),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -48,
                                right: -40,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 156,
                                    height: 156,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFF49C6FF).withValues(alpha: 0.08),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              FocusScope(
                                node: navScopeNode,
                                child: NavigationRail(
                                  extended: Breakpoint(context).isDesktop(),
                                  destinations: _navRailDests(_actions(t, isMobileBreakpoint)),
                                  selectedIndex: navigationShell.currentIndex,
                                  onDestinationSelected: (index) => _onTap(context, index),
                                  trailing: Breakpoint(context).isDesktop()
                                      ? const Expanded(
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: SizedBox(width: 236, child: SideBarStatsOverview()),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 320.ms).slideX(begin: -.05, end: 0).scaleXY(begin: .985, end: 1),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NodaPanel(
                          padding: EdgeInsets.zero,
                          radius: 32,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: navigationShell,
                          ),
                        ),
                      ).animate().fadeIn(duration: 320.ms, delay: 50.ms).slideX(begin: .03, end: 0),
                    ],
                  ),
                ),
        ),
        bottomNavigationBar: isMobileBreakpoint
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: NodaPanel(
                    radius: 24,
                    padding: const EdgeInsets.all(4),
                    color: const Color(0xFF0B1629),
                    child: FocusScope(
                      node: navScopeNode,
                      child: NavigationBar(
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

  List<NavigationRailDestination> _navRailDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationRailDestination(icon: Icon(e.icon), label: Text(e.title))).toList();
}
