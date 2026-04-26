import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/widget/noda_chrome.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
import 'package:hiddify/features/settings/widget/noda_settings_components.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Scaffold(
      backgroundColor: context.nodaBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(24),
                      Text(
                        t.pages.settings.title,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: context.nodaText,
                        ),
                      ).animate().fadeIn(duration: 320.ms).slideY(begin: .05, end: 0),
                      const Gap(8),
                      Text(
                        t.noda.settings.summary,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.nodaMuted,
                        ),
                      ).animate().fadeIn(duration: 320.ms, delay: 50.ms).slideY(begin: .05, end: 0),
                      const Gap(32),
                      
                      Column(
                        children: [
                          SettingsMenuCard(
                            title: t.pages.settings.general.title,
                            description: t.noda.settings.generalSubtitle,
                            icon: Icons.layers_rounded,
                            onClick: () => context.go(context.namedLocation('general')),
                          ),
                          const Gap(16),
                          SettingsMenuCard(
                            title: t.pages.settings.routing.title,
                            description: t.noda.settings.routingSubtitle,
                            icon: Icons.route_rounded,
                            onClick: () => context.go(context.namedLocation('routeOptions')),
                          ),
                          const Gap(16),
                          if (Breakpoint(context).isMobile() || Breakpoint(context).isDesktop())
                            SettingsMenuCard(
                              title: t.pages.about.title,
                              description: t.noda.settings.aboutSubtitle,
                              icon: Icons.info_rounded,
                              onClick: () => context.go(context.namedLocation('about')),
                            ),
                        ],
                      ).animate().fadeIn(duration: 320.ms, delay: 100.ms).slideY(begin: .05, end: 0),
                      
                      const Gap(40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
