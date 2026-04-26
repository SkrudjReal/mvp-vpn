import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/app_info_entity.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/core/widget/app_logo.dart';
import 'package:hiddify/core/widget/noda_chrome.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
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

    return Scaffold(
      backgroundColor: context.nodaBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WindowHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.pages.about.title,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: context.nodaText,
                        ),
                      ).animate().fadeIn(duration: 320.ms).slideY(begin: .05, end: 0),
                      const SizedBox(height: 32),
                      
                      _AppInfoCard(appInfo: appInfo).animate().fadeIn(duration: 320.ms, delay: 50.ms).slideY(begin: .05, end: 0),
                      const SizedBox(height: 24),
                      
                      _PremiumCard(
                        child: Column(
                          children: [
                            if (appInfo.release.allowCustomUpdateChecker) ...[
                              _HoverableActionRow(
                                title: t.pages.about.checkForUpdate,
                                icon: Icons.autorenew,
                                trailingWidget: appUpdate is AppUpdateStateChecking
                                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: context.nodaMuted))
                                    : null,
                                onTap: () => ref.read(appUpdateNotifierProvider.notifier).check(),
                              ),
                              Divider(height: 1, color: context.nodaBorder, indent: 20, endIndent: 20),
                            ],
                            if (PlatformUtils.isDesktop) ...[
                              _HoverableActionRow(
                                title: t.pages.about.openWorkingDir,
                                icon: Icons.folder_outlined,
                                trailingIcon: Icons.open_in_new,
                                onTap: () async {
                                  final path = ref.read(appDirectoriesProvider).requireValue.workingDir.uri;
                                  await UriUtils.tryLaunch(path);
                                },
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(duration: 320.ms, delay: 100.ms).slideY(begin: .05, end: 0),
                      const SizedBox(height: 24),
                      
                      _PremiumCard(
                        child: Column(
                          children: [
                            _HoverableActionRow(
                              title: t.pages.about.sourceCode,
                              icon: Icons.code,
                              trailingIcon: Icons.open_in_new,
                              onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.githubUrl)),
                            ),
                            Divider(height: 1, color: context.nodaBorder, indent: 20, endIndent: 20),
                            _HoverableActionRow(
                              title: t.pages.about.telegramChannel,
                              icon: Icons.send_outlined,
                              trailingIcon: Icons.open_in_new,
                              onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.telegramChannelUrl)),
                            ),
                            Divider(height: 1, color: context.nodaBorder, indent: 20, endIndent: 20),
                            _HoverableActionRow(
                              title: t.pages.about.termsAndConditions,
                              icon: Icons.description_outlined,
                              trailingIcon: Icons.open_in_new,
                              onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.termsAndConditionsUrl)),
                            ),
                            Divider(height: 1, color: context.nodaBorder, indent: 20, endIndent: 20),
                            _HoverableActionRow(
                              title: t.pages.about.privacyPolicy,
                              icon: Icons.shield_outlined,
                              trailingIcon: Icons.open_in_new,
                              onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.privacyPolicyUrl)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 320.ms, delay: 150.ms).slideY(begin: .05, end: 0),
                      const SizedBox(height: 40),
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

class _AppInfoCard extends ConsumerWidget {
  final AppInfoEntity appInfo;
  const _AppInfoCard({required this.appInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return _PremiumCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'noda.',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  color: context.nodaText,
                  height: 1,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.nodaSurfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.nodaBorder),
                ),
                child: Text(
                  'Version ${appInfo.presentVersion}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.nodaMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            t.noda.about.summary,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.nodaMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverableActionRow extends StatefulWidget {
  final String title;
  final IconData icon;
  final IconData? trailingIcon;
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const _HoverableActionRow({
    required this.title,
    required this.icon,
    this.trailingIcon,
    this.trailingWidget,
    required this.onTap,
  });

  @override
  State<_HoverableActionRow> createState() => _HoverableActionRowState();
}

class _HoverableActionRowState extends State<_HoverableActionRow> {
  bool isHovered = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) {
          setState(() => isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: isPressed
                ? context.nodaSurfaceSoft
                : (isHovered ? context.nodaSurfaceSoft.withValues(alpha: 0.5) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: isHovered ? context.nodaNeon : context.nodaMuted),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isHovered ? context.nodaText : context.nodaText.withValues(alpha: 0.8),
                  ),
                ),
              ),
              widget.trailingWidget ?? Icon(
                widget.trailingIcon ?? Icons.chevron_right,
                size: 16,
                color: isHovered ? context.nodaText : context.nodaMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _PremiumCard({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.nodaSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.nodaBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WindowHeader extends StatelessWidget {
  const _WindowHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('noda.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: context.nodaText)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.nodaSurfaceSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('DEV', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: context.nodaMuted)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
