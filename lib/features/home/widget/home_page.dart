import 'package:dartx/dartx.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/widget/app_logo.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
import 'package:hiddify/core/widget/noda_chrome.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hiddify/features/settings/widget/noda_settings_components.dart';

import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'desktop_home_layout.dart';




class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSubscriptionInput = useState(false);
    final subscriptionController = useTextEditingController();
    final addProfileState = ref.watch(addProfileNotifierProvider);
    final selectedCountry = ref.watch(ConfigOptions.region);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider.select((value) => value.valueOrNull));

    ref.listen(addProfileNotifierProvider, (previous, next) {
      if (previous?.isLoading == true && next.hasValue) {
        showSubscriptionInput.value = false;
        subscriptionController.clear();
      }
    });

    Future<void> submitSubscription() async {
      final rawInput = subscriptionController.text.trim();
      if (rawInput.isEmpty) return;
      await ref.read(addProfileNotifierProvider.notifier).addClipboard(rawInput);
    }

    Future<void> toggleConnection() async {
      await _handleConnectionToggle(ref);
    }

    final state = connectionStatus.valueOrNull;
    final isConnected = state == const Connected();
    final ip = isConnected ? activeProxy?.ipinfo.ip ?? "--" : "--";
    final provider = isConnected ? activeProxy?.ipinfo.org ?? "--" : "--";

    return Scaffold(
      backgroundColor: context.nodaBg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _SubscriptionFab(
        expanded: showSubscriptionInput.value,
        isLoading: addProfileState.isLoading,
        controller: subscriptionController,
        onToggle: () => showSubscriptionInput.value = !showSubscriptionInput.value,
        onClose: () => showSubscriptionInput.value = false,
        onSubmit: submitSubscription,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _WindowHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800 && PlatformUtils.isDesktop) {
                    return DesktopHomeLayout(
                      selectedCountry: selectedCountry,
                      connectionStatus: connectionStatus,
                      onToggle: toggleConnection,
                      ip: ip,
                      provider: provider,
                    );
                  }

                  final horizontalPadding = constraints.maxWidth < 560 ? 16.0 : 24.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 88),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: 460,
                          child: Column(
                            children: [
                              _ConnectionPanel(
                                selectedCountry: selectedCountry,
                                connectionStatus: connectionStatus,
                                onToggle: toggleConnection,
                              ).animate().fadeIn(duration: 280.ms).slideY(begin: .025, end: 0),
                              const Gap(12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoBlock(label: "ВАШ IP", value: ip, icon: Icons.public),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: _InfoBlock(
                                      label: "ПРОВАЙДЕР",
                                      value: provider,
                                      icon: Icons.router,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(duration: 280.ms, delay: 70.ms).slideY(begin: .04, end: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConnectionToggle(WidgetRef ref) async {
    final status = ref.read(connectionNotifierProvider);
    final t = ref.read(translationsProvider).requireValue;
    final requiresReconnect = ref.read(configOptionNotifierProvider).valueOrNull;

    switch (status) {
      case AsyncData(value: Connected()) when requiresReconnect == true:
        final activeProfile = await ref.read(activeProfileProvider.future);
        return await ref.read(connectionNotifierProvider.notifier).reconnect(activeProfile);
      case AsyncData(value: Disconnected()) || AsyncError():
        if (ref.read(activeProfileProvider).valueOrNull == null) {
          final selectedCountry = await ref
              .read(dialogNotifierProvider.notifier)
              .showSettingPicker<Region>(
                title: t.pages.proxies.ipInfo.country,
                showFlag: true,
                selected: ref.read(ConfigOptions.region),
                options: Region.availableCountries,
                getTitle: (region) => region.present(t),
              );
          if (selectedCountry != null) {
            await ref.read(ConfigOptions.region.notifier).update(selectedCountry);
          }
          return;
        }
        if (await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
          return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
        }
      case AsyncData(value: Connected()):
        if (requiresReconnect == true &&
            await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
          return await ref
              .read(connectionNotifierProvider.notifier)
              .reconnect(await ref.read(activeProfileProvider.future));
        }
        return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
      default:
        return;
    }
  }
}

class _ConnectionPanel extends ConsumerWidget {
  const _ConnectionPanel({required this.selectedCountry, required this.connectionStatus, required this.onToggle});

  final Region selectedCountry;
  final AsyncValue<ConnectionStatus> connectionStatus;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final state = connectionStatus.valueOrNull;
    final isConnected = state == const Connected();
    final isBusy = state == const Connecting() || state == const Disconnecting();
    final countryLabel = selectedCountry.present(t).split(" (").first;

    return AnimatedContainer(
      duration: 650.ms,
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.nodaSurface.withValues(alpha: isConnected ? .92 : .86),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: (isConnected ? context.nodaNeon : context.nodaBorder).withValues(alpha: .42)),
        boxShadow: [
          if (isConnected)
            BoxShadow(color: context.nodaNeon.withValues(alpha: .20), blurRadius: 50, offset: const Offset(0, 20))
          else
            BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 28, offset: const Offset(0, 14)),
        ],
      ),
      child: Stack(
        children: [
          if (isConnected)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: RadialGradient(
                      colors: [context.nodaNeon.withValues(alpha: .16), Colors.transparent],
                      radius: .82,
                    ),
                  ),
                ),
              ),
            ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CountrySelector(selectedCountry: selectedCountry, label: countryLabel, connected: isConnected),
                  _ProtectionChip(connected: isConnected, busy: isBusy),
                ],
              ),
              const Gap(34),
              _PowerButton(connected: isConnected, busy: isBusy, onTap: onToggle),
              const Gap(26),
              AnimatedSwitcher(
                duration: 260.ms,
                child: Text(
                  _panelTitle(isConnected: isConnected, isBusy: isBusy, countryLabel: countryLabel),
                  key: ValueKey("title-$isConnected-$isBusy-$countryLabel"),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.nodaText),
                ),
              ),
              const Gap(6),
              AnimatedSwitcher(
                duration: 260.ms,
                child: Text(
                  _panelHint(isConnected: isConnected, isBusy: isBusy),
                  key: ValueKey("hint-$isConnected-$isBusy"),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: isConnected ? context.nodaNeon.withValues(alpha: .72) : context.nodaMuted),
                ),
              ),
              const Gap(26),
              _PanelSpecs(connected: isConnected, busy: isBusy),
            ],
          ),
        ],
      ),
    );
  }

  String _panelTitle({required bool isConnected, required bool isBusy, required String countryLabel}) {
    if (isBusy) return "Переключаем соединение";
    if (isConnected) return "Подключено к $countryLabel";
    return "Готов к работе";
  }

  String _panelHint({required bool isConnected, required bool isBusy}) {
    if (isBusy) return "Подождите несколько секунд";
    if (isConnected) return "Ваше соединение надежно зашифровано";
    return "Нажмите кнопку для быстрого старта";
  }
}

class _CountrySelector extends ConsumerWidget {
  const _CountrySelector({required this.selectedCountry, required this.label, required this.connected});

  final Region selectedCountry;
  final String label;
  final bool connected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: PlatformUtils.isDesktop
            ? null // handled by PopupMenuButton if we wrap it, but actually let's use a dynamic approach below
            : () async {
                final selected = await ref
                    .read(dialogNotifierProvider.notifier)
                    .showSettingPicker<Region>(
                      title: t.pages.proxies.ipInfo.country,
                      showFlag: true,
                      selected: selectedCountry,
                      options: Region.availableCountries,
                      getTitle: (region) => region.present(t),
                    );
                if (selected != null) {
                  await ref.read(ConfigOptions.region.notifier).update(selected);
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: connected ? context.nodaNeon.withValues(alpha: .16) : context.nodaSurfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: IPCountryFlag(countryCode: selectedCountry.name.toUpperCase()),
              ),
              const Gap(8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 176),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.nodaText),
                ),
              ),
              const Gap(4),
              Icon(Icons.keyboard_arrow_down, size: 12, color: context.nodaMuted),
            ],
          ),
        ),
      ),
    );

    if (PlatformUtils.isDesktop) {
      return NodaDesktopDropdown<Region>(
        value: selectedCountry,
        items: Region.availableCountries,
        width: 250,
        yOffset: 36,
        onSelected: (selected) async {
          await ref.read(ConfigOptions.region.notifier).update(selected);
        },
        itemBuilder: (region, isSelected, isHovered) {
          return Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1))
                  ],
                ),
                child: IPCountryFlag(countryCode: region.name.toUpperCase(), size: 20),
              ),
              const Gap(14),
              Text(
                region.present(t),
                style: TextStyle(
                  color: isSelected ? context.nodaText : context.nodaText.withValues(alpha: 0.8),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          );
        },
        childBuilder: (context, isOpen) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IPCountryFlag(countryCode: selectedCountry.name.toUpperCase(), size: 20),
                const Gap(10),
                Text(
                  selectedCountry.present(t).split(' ')[0], // Like "Netherlands"
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.nodaText,
                  ),
                ),
                const Gap(6),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: context.nodaMuted,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return child;
  }
}

class _ProtectionChip extends StatelessWidget {
  const _ProtectionChip({required this.connected, required this.busy});

  final bool connected;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final active = connected || busy;
    final label = busy
        ? "ПРОЦЕСС"
        : connected
        ? "ЗАЩИЩЕНО"
        : "ПАУЗА";

    return AnimatedContainer(
      duration: 420.ms,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? context.nodaNeon.withValues(alpha: .18) : context.nodaSurfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? context.nodaNeon.withValues(alpha: .54) : context.nodaBorder.withValues(alpha: .70)),
        boxShadow: active ? [BoxShadow(color: context.nodaNeon.withValues(alpha: .26), blurRadius: 14)] : null,
      ),
      child: Row(
        children: [
          Icon(
            busy ? Icons.autorenew : Icons.security,
            size: 10,
            color: active ? context.nodaNeon : context.nodaMuted,
          ),
          const Gap(6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
              color: active ? context.nodaText : context.nodaMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerButton extends HookWidget {
  const _PowerButton({required this.connected, required this.busy, required this.onTap});

  final bool connected;
  final bool busy;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final active = connected || busy;
    final accent = connected
        ? context.nodaNeon
        : busy
        ? context.nodaNeonSoft
        : const Color(0xFF5B8DFF);

    return GestureDetector(
      onTapDown: (_) => pressed.value = true,
      onTapCancel: () => pressed.value = false,
      onTapUp: (_) => pressed.value = false,
      onTap: onTap,
      child: AnimatedScale(
        duration: 110.ms,
        scale: pressed.value ? .96 : 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              AnimatedContainer(
                    duration: 420.ms,
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: .08)),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: .96, end: 1.04, duration: 1400.ms),
            AnimatedContainer(
              duration: 420.ms,
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: .32)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: active ? .36 : .18),
                    blurRadius: active ? 34 : 18,
                    spreadRadius: active ? 1 : -2,
                  ),
                ],
              ),
              child: Center(
                child: busy
                    ? SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.4, color: accent))
                    : Padding(
                        padding: const EdgeInsets.all(28),
                        child: AppLogo(color: accent),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelSpecs extends StatelessWidget {
  const _PanelSpecs({required this.connected, required this.busy});

  final bool connected;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: connected ? context.nodaNeon.withValues(alpha: .18) : context.nodaBorder.withValues(alpha: .60)),
        ),
      ),
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Expanded(
            child: _SpecColumn(label: "ПРОТОКОЛ", value: "Reality", connected: connected),
          ),
          Container(
            height: 24,
            width: 1,
            color: connected ? context.nodaNeon.withValues(alpha: .16) : context.nodaBorder.withValues(alpha: .60),
          ),
          Expanded(
            child: _SpecColumn(
              label: "СТАТУС",
              value: busy
                  ? "Идёт..."
                  : connected
                  ? "Активно"
                  : "--",
              connected: connected,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecColumn extends StatelessWidget {
  const _SpecColumn({required this.label, required this.value, required this.connected});

  final String label;
  final String value;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("", style: TextStyle(fontSize: 0)),
        Text(
          label,
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: context.nodaMuted),
        ),
        const Gap(4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.nodaText),
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.nodaSurface.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.nodaBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.nodaNeon.withValues(alpha: .56)),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: context.nodaMuted,
                    letterSpacing: .2,
                  ),
                ),
                const Gap(2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.nodaText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionFab extends ConsumerWidget {
  const _SubscriptionFab({
    required this.expanded,
    required this.isLoading,
    required this.controller,
    required this.onToggle,
    required this.onClose,
    required this.onSubmit,
  });

  final bool expanded;
  final bool isLoading;
  final TextEditingController controller;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final maxWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = (maxWidth - 32).clamp(300.0, 440.0);

    return AnimatedSwitcher(
      duration: 240.ms,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: .94,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: expanded
          ? Container(
              key: const ValueKey("subscription-expanded"),
              width: panelWidth,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.nodaSurface.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.nodaBorder),
                boxShadow: [
                  BoxShadow(color: context.nodaNeon.withValues(alpha: .16), blurRadius: 24, offset: const Offset(0, 12)),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.add_link_rounded, color: context.nodaNeon, size: 20),
                  const Gap(10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) async => await onSubmit(),
                      decoration: InputDecoration(
                        hintText: t.pages.profileDetails.form.urlHint,
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                    onPressed: isLoading ? null : onClose,
                    icon: Icon(Icons.close, size: 18),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.nodaNeon,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(44, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: isLoading ? null : () async => await onSubmit(),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.arrow_upward_rounded, size: 18),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 180.ms).slideY(begin: .06, end: 0)
          : Material(
              key: const ValueKey("subscription-collapsed"),
              color: context.nodaSurface.withValues(alpha: .92),
              shape: const CircleBorder(),
              elevation: 12,
              shadowColor: context.nodaNeon.withValues(alpha: .24),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onToggle,
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Icon(Icons.add_link_rounded, color: context.nodaNeon, size: 22),
                ),
              ),
            ).animate().fadeIn(duration: 180.ms).scale(begin: const Offset(.92, .92), end: const Offset(1, 1)),
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
              Text(
                "noda.",
                style: GoogleFonts.cookie(
                  fontSize: 34, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: -.5, 
                  color: context.nodaText,
                ),
              ),
              Gap(8),
              AppVersionLabel(),
            ],
          ),
        ],
      ),
    );
  }
}


class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: ref.watch(translationsProvider).requireValue.common.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(color: context.nodaSurfaceSoft, borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: context.nodaMuted),
        ),
      ),
    );
  }
}
