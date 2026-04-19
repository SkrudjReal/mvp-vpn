import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/core/widget/noda_chrome.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/features/stats/widget/stats_card.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/number_formatters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final showAllSidebarStatsProvider = PreferencesNotifier.createAutoDispose("show_all_sidebar_stats", false);

class SideBarStatsOverview extends HookConsumerWidget {
  const SideBarStatsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final stats = ref.watch(statsNotifierProvider).asData?.value ?? SystemInfo.create();
    final showAll = ref.watch(showAllSidebarStatsProvider);
    final theme = Theme.of(context);

    return NodaPanel(
      color: const Color(0xFF121B2C),
      radius: 24,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF15233A).withValues(alpha: 0.92),
                  const Color(0xFF0D1526).withValues(alpha: 0.84),
                ],
              ),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.components.stats.traffic,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Gap(2),
                      Text(
                        showAll ? t.components.stats.trafficTotal : t.components.stats.trafficLive,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    ref.read(showAllSidebarStatsProvider.notifier).update(!showAll);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRotation(
                          turns: showAll ? 1 : 0.5,
                          duration: kAnimationDuration,
                          child: const Icon(FluentIcons.chevron_down_16_regular, size: 16),
                        ),
                        const Gap(6),
                        AnimatedText(showAll ? t.common.showLess : t.common.showMore),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),
          AnimatedCrossFade(
            crossFadeState: showAll ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: kAnimationDuration,
            firstChild: StatsCard(
              title: t.components.stats.traffic,
              stats: [
                (
                  label: const Icon(FluentIcons.arrow_download_16_regular),
                  data: Text(stats.downlink.toInt().speed()),
                  semanticLabel: t.components.stats.speed,
                ),
                (
                  label: const Icon(FluentIcons.arrow_bidirectional_up_down_16_regular),
                  data: Text(stats.downlinkTotal.toInt().size()),
                  semanticLabel: t.components.stats.totalTransferred,
                ),
              ],
            ).animate().fadeIn(duration: 220.ms).slideY(begin: .05, end: 0),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatsCard(
                  title: t.components.stats.trafficLive,
                  stats: [
                    (
                      label: const Text("↑", style: TextStyle(color: Colors.green)),
                      data: Text(stats.uplink.toInt().speed()),
                      semanticLabel: t.components.stats.uplink,
                    ),
                    (
                      label: Text("↓", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      data: Text(stats.downlink.toInt().speed()),
                      semanticLabel: t.components.stats.downlink,
                    ),
                  ],
                ).animate().fadeIn(duration: 220.ms).slideY(begin: .04, end: 0),
                const Gap(8),
                StatsCard(
                  title: t.components.stats.trafficTotal,
                  stats: [
                    (
                      label: const Text("↑", style: TextStyle(color: Colors.green)),
                      data: Text(stats.uplinkTotal.toInt().size()),
                      semanticLabel: t.components.stats.uplink,
                    ),
                    (
                      label: Text("↓", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      data: Text(stats.downlinkTotal.toInt().size()),
                      semanticLabel: t.components.stats.downlink,
                    ),
                  ],
                ).animate().fadeIn(duration: 260.ms, delay: 30.ms).slideY(begin: .04, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
