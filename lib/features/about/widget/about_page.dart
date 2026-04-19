import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/core/widget/app_logo.dart';
import 'package:hiddify/core/widget/noda_chrome.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hiddify/features/app_update/notifier/app_update_state.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AboutPage extends HookConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final appInfo = ref.watch(appInfoProvider).requireValue;
    final appUpdate = ref.watch(appUpdateNotifierProvider);

    ref.listen(appUpdateNotifierProvider, (_, next) async {
      if (!context.mounted) return;
      switch (next) {
        case AppUpdateStateAvailable(:final versionInfo) || AppUpdateStateIgnored(:final versionInfo):
          return await ref
              .read(dialogNotifierProvider.notifier)
              .showNewVersion(currentVersion: appInfo.presentVersion, newVersion: versionInfo, canIgnore: false);
        case AppUpdateStateError(:final error):
          return CustomToast.error(t.presentShortError(error)).show(context);
        case AppUpdateStateNotAvailable():
          return CustomToast.success(t.pages.about.notAvailableMsg).show(context);
      }
    });

    final conditionalTiles = <Widget>[
      if (appInfo.release.allowCustomUpdateChecker)
        ListTile(
          title: Text(t.pages.about.checkForUpdate),
          trailing: switch (appUpdate) {
            AppUpdateStateChecking() => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
            _ => const Icon(FluentIcons.arrow_sync_24_regular),
          },
          onTap: () async {
            await ref.read(appUpdateNotifierProvider.notifier).check();
          },
        ),
      if (PlatformUtils.isDesktop)
        ListTile(
          title: Text(t.pages.about.openWorkingDir),
          trailing: const Icon(FluentIcons.open_folder_24_regular),
          onTap: () async {
            final path = ref.watch(appDirectoriesProvider).requireValue.workingDir.uri;
            await UriUtils.tryLaunch(path);
          },
        ),
    ];

    final legalTiles = <Widget>[
      ListTile(
        title: Text(t.pages.about.sourceCode),
        trailing: const Icon(FluentIcons.open_24_regular),
        onTap: () async {
          await UriUtils.tryLaunch(Uri.parse(Constants.githubUrl));
        },
      ),
      ListTile(
        title: Text(t.pages.about.telegramChannel),
        trailing: const Icon(FluentIcons.open_24_regular),
        onTap: () async {
          await UriUtils.tryLaunch(Uri.parse(Constants.telegramChannelUrl));
        },
      ),
      ListTile(
        title: Text(t.pages.about.termsAndConditions),
        trailing: const Icon(FluentIcons.open_24_regular),
        onTap: () async {
          await UriUtils.tryLaunch(Uri.parse(Constants.termsAndConditionsUrl));
        },
      ),
      ListTile(
        title: Text(t.pages.about.privacyPolicy),
        trailing: const Icon(FluentIcons.open_24_regular),
        onTap: () async {
          await UriUtils.tryLaunch(Uri.parse(Constants.privacyPolicyUrl));
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.about.title),
        actions: [
          PopupMenuButton(
            icon: Icon(AdaptiveIcon(context).more),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: Text(t.common.addToClipboard),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: appInfo.format()));
                  },
                ),
              ];
            },
          ),
          const Gap(8),
        ],
      ),
      body: AppShellBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                NodaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppLogo(width: 58, height: 58),
                          const Gap(16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.common.appTitle, style: Theme.of(context).textTheme.headlineMedium),
                                const Gap(4),
                                Text("${t.common.version} ${appInfo.presentVersion}", style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(18),
                      Text(
                        t.noda.about.summary,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 320.ms).slideY(begin: .05, end: 0),
                if (conditionalTiles.isNotEmpty) ...[
                  const Gap(16),
                  NodaPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Column(children: conditionalTiles),
                  ).animate().fadeIn(duration: 320.ms, delay: 80.ms).slideY(begin: .05, end: 0),
                ],
                const Gap(16),
                NodaPanel(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(children: legalTiles),
                ).animate().fadeIn(duration: 320.ms, delay: 140.ms).slideY(begin: .05, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
