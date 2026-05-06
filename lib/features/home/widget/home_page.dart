import 'dart:math' as math;

import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
import 'package:hiddify/core/widget/app_logo.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/desktop_home_layout.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/features/settings/widget/noda_settings_components.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _helsinkiVlessLink =
    'vless://b22b8cce-b18d-4f3e-941c-d95649efd0d0@95.216.193.189:8443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=SPqnkIcxVhBBAZDeHO2esgU_sz74Oqpp4NGyCcN51hE&sid=93fefb115d67d341&type=tcp&headerType=none#noda-reality';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSubscriptionInput = useState(false);
    final subscriptionController = useTextEditingController();
    final addProfileState = ref.watch(addProfileNotifierProvider);
    final savedCountry = ref.watch(ConfigOptions.region);
    final selectedCountry = Region.availableCountries.contains(savedCountry)
        ? savedCountry
        : Region.availableCountries.first;
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final modalMode = useState<HomeModalMode?>(null);
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
        onToggle: () {
          if (!showSubscriptionInput.value && subscriptionController.text.trim().isEmpty) {
            subscriptionController.text = _helsinkiVlessLink;
          }
          showSubscriptionInput.value = !showSubscriptionInput.value;
        },
        onClose: () => showSubscriptionInput.value = false,
        onSubmit: submitSubscription,
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useDesktopHome = constraints.maxWidth > 1100 && PlatformUtils.isDesktop;

            if (useDesktopHome) {
              return DesktopHomeLayout(
                selectedCountry: selectedCountry,
                connectionStatus: connectionStatus,
                onToggle: toggleConnection,
                ip: ip,
                provider: provider,
              );
            }

            return Stack(
              children: [
                _MobileHomeLayout(
                  selectedCountry: selectedCountry,
                  connectionStatus: connectionStatus,
                  ip: ip,
                  provider: provider,
                  onToggle: toggleConnection,
                  onOpenCountries: () => _showMobileCountriesSheet(context, ref, selectedCountry),
                  onOpenSettings: () => modalMode.value = HomeModalMode.settings,
                  onOpenAbout: () => modalMode.value = HomeModalMode.about,
                ),
                if (modalMode.value == HomeModalMode.routing || modalMode.value == HomeModalMode.audit)
                  AiModal(
                    mode: modalMode.value!,
                    isConnected: isConnected,
                    selectedCountry: selectedCountry,
                    onClose: () => modalMode.value = null,
                    onSelectCountry: (region) => ref.read(ConfigOptions.region.notifier).update(region),
                  ),
                if (modalMode.value == HomeModalMode.settings || modalMode.value == HomeModalMode.about)
                  GlassSectionModal(mode: modalMode.value!, onClose: () => modalMode.value = null),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleConnectionToggle(WidgetRef ref) async {
    final status = ref.read(connectionNotifierProvider);
    final requiresReconnect = ref.read(configOptionNotifierProvider).valueOrNull;

    switch (status) {
      case AsyncData(value: Connected()) when requiresReconnect == true:
        await _ensureDesktopSystemProxy(ref);
        final activeProfile = await ref.read(activeProfileProvider.future);
        return await ref.read(connectionNotifierProvider.notifier).reconnect(activeProfile);
      case AsyncData(value: Disconnected()) || AsyncError():
        await _ensureDesktopSystemProxy(ref);
        if (ref.read(activeProfileProvider).valueOrNull == null) {
          await ref.read(addProfileNotifierProvider.notifier).addClipboard(_helsinkiVlessLink);
          final hasActiveProfile = await _waitForActiveProfile(ref);
          if (!hasActiveProfile) return;
          return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
        }
        if (await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
          return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
        }
      case AsyncData(value: Connected()):
        if (requiresReconnect == true &&
            await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
          await _ensureDesktopSystemProxy(ref);
          return await ref
              .read(connectionNotifierProvider.notifier)
              .reconnect(await ref.read(activeProfileProvider.future));
        }
        return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
      default:
        return;
    }
  }

  Future<void> _ensureDesktopSystemProxy(WidgetRef ref) async {
    if (!PlatformUtils.isDesktop) return;
    if (ref.read(ConfigOptions.serviceMode) == ServiceMode.systemProxy) return;
    await ref.read(ConfigOptions.serviceMode.notifier).update(ServiceMode.systemProxy);
  }

  Future<bool> _waitForActiveProfile(WidgetRef ref) async {
    for (var attempt = 0; attempt < 12; attempt++) {
      if (ref.read(activeProfileProvider).valueOrNull != null) return true;

      ref.invalidate(activeProfileProvider);
      final activeProfile = await ref
          .read(activeProfileProvider.future)
          .timeout(const Duration(milliseconds: 180), onTimeout: () => null);
      if (activeProfile != null) return true;

      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    return false;
  }
}

class _MobileHomeLayout extends StatelessWidget {
  const _MobileHomeLayout({
    required this.selectedCountry,
    required this.connectionStatus,
    required this.ip,
    required this.provider,
    required this.onToggle,
    required this.onOpenCountries,
    required this.onOpenSettings,
    required this.onOpenAbout,
  });

  final Region selectedCountry;
  final AsyncValue<ConnectionStatus> connectionStatus;
  final String ip;
  final String provider;
  final Future<void> Function() onToggle;
  final VoidCallback onOpenCountries;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    final state = connectionStatus.valueOrNull;
    final isConnected = state == const Connected();
    final isBusy = state == const Connecting() || state == const Disconnecting();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.min(constraints.maxWidth - 32, 430).clamp(300.0, 430.0).toDouble();
        final compactHeight = constraints.maxHeight < 720;
        final powerSize = compactHeight ? 142.0 : 164.0;
        final topGap = compactHeight ? 12.0 : 22.0;

        return DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF060913)),
          child: Stack(
            children: [
              const Positioned.fill(child: _MobileAmbientBackground()),
              Positioned(
                top: 50,
                left: -80,
                right: -80,
                height: compactHeight ? 190 : 220,
                child: Opacity(
                  opacity: .56,
                  child: Image.asset(
                    'assets/images/world_map_dark.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 94 + bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 94 - bottomInset),
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          children: [
                            _MobileHeader(onOpenMenu: onOpenCountries, onOpenSettings: onOpenSettings),
                            SizedBox(height: topGap),
                            _MobileServerChip(
                              selectedCountry: selectedCountry,
                              isConnected: isConnected,
                              isBusy: isBusy,
                              onTap: onOpenCountries,
                            ).animate().fadeIn(duration: 260.ms).slideY(begin: .04, end: 0),
                            SizedBox(height: compactHeight ? 24 : 38),
                            _MobilePowerOrb(isConnected: isConnected, isBusy: isBusy, size: powerSize, onTap: onToggle)
                                .animate()
                                .fadeIn(duration: 320.ms)
                                .scale(begin: const Offset(.96, .96), end: const Offset(1, 1)),
                            Gap(compactHeight ? 22 : 30),
                            _MobileConnectionCopy(isConnected: isConnected, isBusy: isBusy),
                            Gap(compactHeight ? 18 : 28),
                            _MobileStatsCard(isConnected: isConnected, isBusy: isBusy),
                            const Gap(14),
                            Row(
                              children: [
                                Expanded(
                                  child: _MobileInfoBlock(
                                    label: 'YOUR IP',
                                    value: _cleanDisplayValue(ip),
                                    icon: Icons.public_rounded,
                                    isConnected: isConnected,
                                  ),
                                ),
                                const Gap(10),
                                Expanded(
                                  child: _MobileInfoBlock(
                                    label: 'PROVIDER',
                                    value: _cleanDisplayValue(provider),
                                    icon: Icons.cloud_queue_rounded,
                                    isConnected: isConnected,
                                  ),
                                ),
                              ],
                            ).animate(delay: 80.ms).fadeIn(duration: 300.ms).slideY(begin: .04, end: 0),
                            if (!compactHeight) const Gap(10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 14 + bottomInset,
                child: Center(
                  child: SizedBox(
                    width: math.min(contentWidth, isIos ? 360 : 390).toDouble(),
                    child: _MobileBottomNav(
                      isIos: isIos,
                      onCountries: onOpenCountries,
                      onSettings: onOpenSettings,
                      onAbout: onOpenAbout,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileAmbientBackground extends StatelessWidget {
  const _MobileAmbientBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -.62),
          radius: 1.12,
          colors: [
            const Color(0xFF00BFFF).withValues(alpha: .12),
            const Color(0xFF0A1A2D).withValues(alpha: .36),
            const Color(0xFF060913),
          ],
          stops: const [0, .42, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: .20), Colors.transparent, Colors.black.withValues(alpha: .34)],
            stops: const [0, .38, 1],
          ),
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.onOpenMenu, required this.onOpenSettings});

  final VoidCallback onOpenMenu;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _MobileHeaderButton(icon: Icons.menu_rounded, onTap: onOpenMenu),
          ),
          Text(
            'noda.',
            style: GoogleFonts.cookie(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1,
              color: Colors.white,
              shadows: [Shadow(color: Colors.white.withValues(alpha: .24), blurRadius: 10)],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _MobileHeaderButton(icon: Icons.tune_rounded, onTap: onOpenSettings),
          ),
        ],
      ),
    );
  }
}

class _MobileHeaderButton extends StatelessWidget {
  const _MobileHeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white.withValues(alpha: .92), size: 21),
    );
  }
}

class _MobileServerChip extends ConsumerWidget {
  const _MobileServerChip({
    required this.selectedCountry,
    required this.isConnected,
    required this.isBusy,
    required this.onTap,
  });

  final Region selectedCountry;
  final bool isConnected;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final accent = context.nodaNeon;
    final label = _countryTitle(selectedCountry, t);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: 260.ms,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF101A2A).withValues(alpha: isBusy ? .92 : .80),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (isConnected || isBusy ? accent : Colors.white).withValues(alpha: isBusy ? .36 : .10),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isBusy ? .22 : .10),
                blurRadius: isBusy ? 24 : 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              if (isBusy) ...[
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
                const Gap(10),
                Expanded(
                  child: Text(
                    'Connecting...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent),
                  ),
                ),
              ] else ...[
                IPCountryFlag(countryCode: selectedCountry.name.toUpperCase(), size: 20),
                const Gap(10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const Gap(4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white.withValues(alpha: .58)),
                const Spacer(),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(color: Color(0xFF18D778), shape: BoxShape.circle),
                ),
                const Gap(7),
                Text(
                  '18 ms',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: .76),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MobilePowerOrb extends HookWidget {
  const _MobilePowerOrb({required this.isConnected, required this.isBusy, required this.size, required this.onTap});

  final bool isConnected;
  final bool isBusy;
  final double size;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final accent = context.nodaNeon;
    final active = isConnected || isBusy;
    final buttonColor = isBusy ? const Color(0xFF0B1728) : Colors.white;
    final logoColor = isBusy || isConnected ? accent : const Color(0xFF07101D);

    return GestureDetector(
      onTapDown: (_) => pressed.value = true,
      onTapCancel: () => pressed.value = false,
      onTapUp: (_) => pressed.value = false,
      onTap: onTap,
      child: AnimatedScale(
        duration: 120.ms,
        curve: Curves.easeOutCubic,
        scale: pressed.value ? .96 : 1,
        child: SizedBox(
          width: size + 48,
          height: size + 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (active)
                Container(
                      width: size + 42,
                      height: size + 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: .08),
                        boxShadow: [BoxShadow(color: accent.withValues(alpha: .38), blurRadius: 46, spreadRadius: 3)],
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scaleXY(begin: .94, end: 1.04, duration: 1600.ms),
              if (isBusy)
                SizedBox(
                  width: size + 20,
                  height: size + 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    value: .74,
                    backgroundColor: Colors.white.withValues(alpha: .06),
                    color: accent,
                  ),
                ),
              if (isConnected)
                Container(
                  width: size + 18,
                  height: size + 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: .82), width: 9),
                  ),
                ),
              AnimatedContainer(
                duration: 320.ms,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? accent.withValues(alpha: .58) : Colors.black.withValues(alpha: .12),
                  ),
                  boxShadow: [
                    if (!active)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: .22),
                        blurRadius: 12,
                        offset: const Offset(-4, -4),
                      ),
                    BoxShadow(
                      color: active ? accent.withValues(alpha: .38) : Colors.black.withValues(alpha: .50),
                      blurRadius: active ? 34 : 22,
                      offset: active ? Offset.zero : const Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'noda.',
                    style: GoogleFonts.cookie(
                      fontSize: size * .38,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: logoColor,
                      shadows: active ? [Shadow(color: accent.withValues(alpha: .58), blurRadius: 18)] : null,
                    ),
                  ),
                ),
              ),
              if (isConnected)
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: .44), blurRadius: 24)],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileConnectionCopy extends StatelessWidget {
  const _MobileConnectionCopy({required this.isConnected, required this.isBusy});

  final bool isConnected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final title = isBusy
        ? 'Connecting...'
        : isConnected
        ? 'Connected'
        : 'Ready to connect';
    final subtitle = isBusy
        ? 'Securing your connection'
        : isConnected
        ? 'Your connection is secure'
        : 'Best server based on your location';

    return Column(
      children: [
        AnimatedSwitcher(
          duration: 220.ms,
          child: Text(
            title,
            key: ValueKey(title),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1),
          ),
        ),
        const Gap(7),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: .58)),
        ),
      ],
    );
  }
}

class _MobileStatsCard extends StatelessWidget {
  const _MobileStatsCard({required this.isConnected, required this.isBusy});

  final bool isConnected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF09111D).withValues(alpha: .88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .28), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MobileSpec(label: 'PROTOCOL', value: 'Reality', active: isConnected || isBusy),
          ),
          Container(width: 1, height: 28, color: Colors.white.withValues(alpha: .10)),
          Expanded(
            child: _MobileSpec(
              label: 'TRAFFIC',
              value: isConnected ? '↓ 12.4 MB\n↑ 8.7 MB' : '--',
              active: isConnected,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSpec extends StatelessWidget {
  const _MobileSpec({required this.label, required this.value, required this.active, this.alignRight = false});

  final String label;
  final String value;
  final bool active;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
            color: Colors.white.withValues(alpha: .46),
          ),
        ),
        const Gap(6),
        Text(
          value,
          maxLines: 2,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: active ? context.nodaNeon : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _MobileInfoBlock extends StatelessWidget {
  const _MobileInfoBlock({required this.label, required this.value, required this.icon, required this.isConnected});

  final String label;
  final String value;
  final IconData icon;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final accent = context.nodaNeon;

    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF09111D).withValues(alpha: .88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isConnected ? accent.withValues(alpha: .14) : Colors.white.withValues(alpha: .06),
              shape: BoxShape.circle,
              border: Border.all(
                color: isConnected ? accent.withValues(alpha: .34) : Colors.white.withValues(alpha: .08),
              ),
            ),
            child: Icon(icon, size: 15, color: isConnected ? accent : Colors.white.withValues(alpha: .72)),
          ),
          const Gap(9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                    color: Colors.white.withValues(alpha: .46),
                  ),
                ),
                const Gap(3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({
    required this.isIos,
    required this.onCountries,
    required this.onSettings,
    required this.onAbout,
  });

  final bool isIos;
  final VoidCallback onCountries;
  final VoidCallback onSettings;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final background = isIos ? Colors.white.withValues(alpha: .94) : const Color(0xFF08111E).withValues(alpha: .92);
    final muted = isIos ? const Color(0xFF7D8794) : Colors.white.withValues(alpha: .62);
    final accent = context.nodaNeon;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: isIos ? .72 : .08)),
        boxShadow: [
          BoxShadow(
            color: isIos ? Colors.black.withValues(alpha: .12) : Colors.black.withValues(alpha: .38),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MobileNavItem(
              icon: Icons.public_rounded,
              label: 'Countries',
              color: accent,
              active: true,
              onTap: onCountries,
            ),
          ),
          Expanded(
            child: _MobileNavItem(icon: Icons.bookmark_border_rounded, label: 'Saved', color: muted, onTap: onSettings),
          ),
          Expanded(
            child: _MobileNavItem(icon: Icons.history_rounded, label: 'Recent', color: muted, onTap: onAbout),
          ),
        ],
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: 220.ms,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: .12) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: active ? Border.all(color: color.withValues(alpha: .24)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              if (active) ...[
                const Gap(7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showMobileCountriesSheet(BuildContext context, WidgetRef ref, Region selectedCountry) async {
  final platform = Theme.of(context).platform;
  final isIos = platform == TargetPlatform.iOS;
  final t = ref.read(translationsProvider).requireValue;
  const countries = Region.availableCountries;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (context) {
      final bg = isIos ? Colors.white : const Color(0xFF09111D);
      final fg = isIos ? const Color(0xFF111827) : Colors.white;
      final muted = isIos ? const Color(0xFF6B7280) : Colors.white.withValues(alpha: .58);
      final line = isIos ? const Color(0xFFE5E7EB) : Colors.white.withValues(alpha: .08);
      const accent = Color(0xFF00BFFF);

      return FractionallySizedBox(
        heightFactor: isIos ? .48 : .50,
        child: Container(
          padding: EdgeInsets.fromLTRB(22, 10, 22, 18 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: isIos ? .7 : .10)),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .36), blurRadius: 36, offset: const Offset(0, -10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isIos ? const Color(0xFFC8CDD4) : Colors.white).withValues(alpha: .62),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Gap(18),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isIos ? const Color(0xFFF3F5F8) : const Color(0xFF101A2A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 18, color: muted),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        'Search country',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: muted),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(18),
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Recents',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'All Countries',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent),
                        ),
                        const Gap(8),
                        Container(height: 2, color: accent),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 1, color: line),
              const Gap(10),
              _MobileCountrySheetRow(
                title: 'Fastest country',
                subtitle: null,
                leading: const Icon(Icons.bolt_rounded, size: 18, color: accent),
                ping: null,
                selected: false,
                foreground: fg,
                muted: muted,
                accent: accent,
                onTap: () async {
                  await ref.read(ConfigOptions.region.notifier).update(Region.fi);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              const Gap(6),
              ...countries.map((region) {
                final active = region == selectedCountry;
                return _MobileCountrySheetRow(
                  title: _countryTitle(region, t),
                  subtitle: _countrySubtitle(region, t),
                  leading: IPCountryFlag(countryCode: region.name.toUpperCase(), size: 22),
                  ping: '18 ms',
                  selected: active,
                  foreground: fg,
                  muted: muted,
                  accent: accent,
                  onTap: () async {
                    await ref.read(ConfigOptions.region.notifier).update(region);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

class _MobileCountrySheetRow extends StatelessWidget {
  const _MobileCountrySheetRow({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.ping,
    required this.selected,
    required this.foreground,
    required this.muted,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget leading;
  final String? ping;
  final bool selected;
  final Color foreground;
  final Color muted;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: .09) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected ? Border.all(color: accent.withValues(alpha: .20)) : null,
          ),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: Center(child: leading)),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: foreground),
                    ),
                    if (subtitle != null) ...[
                      const Gap(2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (ping != null) ...[
                Text(
                  ping!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                ),
                const Gap(9),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                ),
              ] else
                Icon(Icons.chevron_right_rounded, color: muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

String _countryTitle(Region region, TranslationsEn t) {
  return region.present(t).split(',').first.split(' (').first.trim();
}

String? _countrySubtitle(Region region, TranslationsEn t) {
  final label = region.present(t);
  if (!label.contains(',')) return null;
  return label.split(',').skip(1).join(',').replaceAll(RegExp(r'\s*\([^)]+\)'), '').trim();
}

String _cleanDisplayValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed == '--') return '--';
  return trimmed;
}

// ignore: unused_element
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
                  style: TextStyle(
                    fontSize: 11,
                    color: isConnected ? context.nodaNeon.withValues(alpha: .72) : context.nodaMuted,
                  ),
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1)),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.nodaText),
                ),
                const Gap(6),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: context.nodaMuted),
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
        border: Border.all(
          color: active ? context.nodaNeon.withValues(alpha: .54) : context.nodaBorder.withValues(alpha: .70),
        ),
        boxShadow: active ? [BoxShadow(color: context.nodaNeon.withValues(alpha: .26), blurRadius: 14)] : null,
      ),
      child: Row(
        children: [
          Icon(busy ? Icons.autorenew : Icons.security, size: 10, color: active ? context.nodaNeon : context.nodaMuted),
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
          top: BorderSide(
            color: connected ? context.nodaNeon.withValues(alpha: .18) : context.nodaBorder.withValues(alpha: .60),
          ),
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
        const Text('', style: TextStyle(fontSize: 0)),
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

// ignore: unused_element
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
                  BoxShadow(
                    color: context.nodaNeon.withValues(alpha: .16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
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
                    icon: const Icon(Icons.close, size: 18),
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
                        : const Icon(Icons.arrow_upward_rounded, size: 18),
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

// ignore: unused_element
class _WindowHeader extends StatelessWidget {
  const _WindowHeader({required this.onOpenMenu});

  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!PlatformUtils.isDesktop) ...[
            Text(
              "noda.",
              style: GoogleFonts.cookie(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                color: context.nodaText,
              ),
            ),
            const Gap(8),
          ] else
            IconButton(
              onPressed: onOpenMenu,
              style: IconButton.styleFrom(backgroundColor: context.nodaSurfaceSoft, padding: const EdgeInsets.all(10)),
              icon: Icon(Icons.menu_rounded, color: context.nodaText, size: 20),
            ),
          const AppVersionLabel(),
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
