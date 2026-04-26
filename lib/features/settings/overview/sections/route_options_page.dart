import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/features/settings/widget/noda_settings_components.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RouteOptionsPage extends HookConsumerWidget {
  const RouteOptionsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return Scaffold(
      backgroundColor: context.nodaBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsHeader(
                  title: t.pages.settings.routing.title,
                  onBack: () => context.pop(),
                ),
                SettingsPremiumCard(
                  child: Column(
                    children: [
                      ChoicePreferenceWidget(
                        selected: ref.watch(ConfigOptions.region),
                        preferences: ref.watch(ConfigOptions.region.notifier),
                        choices: Region.availableCountries,
                        title: t.pages.settings.routing.region,
                        showFlag: true,
                        icon: Icons.place_outlined,
                        presentChoice: (value) => value.present(t),
                      ),
                      Divider(height: 1, color: context.nodaBorder, indent: 24, endIndent: 24),
                      SettingsToggleItem(
                        title: t.pages.settings.routing.blockAds,
                        icon: Icons.block_outlined,
                        enabled: ref.watch(ConfigOptions.blockAds),
                        onChange: () => ref.read(ConfigOptions.blockAds.notifier).update(!ref.read(ConfigOptions.blockAds)),
                      ),
                      Divider(height: 1, color: context.nodaBorder, indent: 24, endIndent: 24),
                      SettingsToggleItem(
                        title: t.pages.settings.routing.bypassLan,
                        icon: Icons.call_split_rounded,
                        enabled: ref.watch(ConfigOptions.bypassLan),
                        onChange: () => ref.read(ConfigOptions.bypassLan.notifier).update(!ref.read(ConfigOptions.bypassLan)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
