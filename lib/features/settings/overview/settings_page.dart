import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/widget/noda_chrome.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum ConfigOptionSection {
  warp,
  fragment;

  static final _warpKey = GlobalKey(debugLabel: "warp-section-key");
  static final _fragmentKey = GlobalKey(debugLabel: "fragment-section-key");

  GlobalKey get key => switch (this) {
    ConfigOptionSection.warp => _warpKey,
    ConfigOptionSection.fragment => _fragmentKey,
  };
}

class SettingsPage extends HookConsumerWidget {
  SettingsPage({super.key, String? section})
    : section = section != null ? ConfigOptionSection.values.byName(section) : null;

  final ConfigOptionSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // final scrollController = useScrollController();

    // useMemoized(
    //   () {
    //     if (section != null) {
    //       WidgetsBinding.instance.addPostFrameCallback(
    //         (_) {
    //           final box = section!.key.currentContext?.findRenderObject() as RenderBox?;

    //           final offset = box?.localToGlobal(Offset.zero);
    //           if (offset == null) return;
    //           final height = scrollController.offset + offset.dy - MediaQueryData.fromView(View.of(context)).padding.top - kToolbarHeight;
    //           scrollController.animateTo(
    //             height,
    //             duration: const Duration(milliseconds: 500),
    //             curve: Curves.decelerate,
    //           );
    //         },
    //       );
    //     }
    //   },
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.title),
        actions: const [Gap(8)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = Breakpoint(context).isDesktop() ? 26.0 : 14.0;
          final isDesktop = Breakpoint(context).isDesktop();
          final isApple = PlatformUtils.isMacOS || PlatformUtils.isIOS;
          final cardWidth = isDesktop ? (isApple ? 340.0 : 360.0) : double.infinity;

          return ListView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 22),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: NodaPanel(
                  padding: EdgeInsets.fromLTRB(isApple ? 24 : 28, isApple ? 24 : 28, isApple ? 24 : 28, 24),
                  radius: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.pages.settings.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Gap(10),
                      Text(
                        t.noda.settings.summary,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(22),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: SettingsSection(
                              title: t.pages.settings.general.title,
                              subtitle: t.noda.settings.generalSubtitle,
                              icon: Icons.layers_rounded,
                              namedLocation: context.namedLocation('general'),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: SettingsSection(
                              title: t.pages.settings.routing.title,
                              subtitle: t.noda.settings.routingSubtitle,
                              icon: Icons.route_rounded,
                              namedLocation: context.namedLocation('routeOptions'),
                            ),
                          ),
                          if (Breakpoint(context).isMobile() || isDesktop)
                            SizedBox(
                              width: cardWidth,
                              child: SettingsSection(
                                title: t.pages.about.title,
                                subtitle: t.noda.settings.aboutSubtitle,
                                icon: Icons.info_rounded,
                                namedLocation: context.namedLocation('about'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 280.ms).slideY(begin: .03, end: 0),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SettingsSection extends HookConsumerWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.namedLocation,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String namedLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return NodaPanel(
      padding: EdgeInsets.zero,
      radius: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.go(namedLocation),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: theme.colorScheme.primary.withValues(alpha: 0.16),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.32)),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const Gap(4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
