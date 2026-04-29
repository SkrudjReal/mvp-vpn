import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
import 'package:hiddify/features/settings/widget/noda_settings_components.dart';

class GeneralPage extends HookConsumerWidget {
  const GeneralPage({super.key});
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
                  title: t.pages.settings.general.title,
                  onBack: () => context.pop(),
                ),
                SettingsPremiumCard(
                  child: Column(
                    children: [
                      const LocalePrefTile(),
                      Divider(height: 1, color: context.nodaBorder, indent: 24, endIndent: 24),
                      const ThemeModePrefTile(),
                      Divider(height: 1, color: context.nodaBorder, indent: 24, endIndent: 24),
                      const EnableAnalyticsPrefTile(),
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
