import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/widget/app_logo.dart';
import 'package:hiddify/core/widget/noda_chrome.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final activeProfile = ref.watch(activeProfileProvider);
    final selectedCountry = ref.watch(ConfigOptions.region);
    final showSubscriptionInput = useState(false);
    final subscriptionController = useTextEditingController();
    final addProfileState = ref.watch(addProfileNotifierProvider);

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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(height: 24),
            const Gap(8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: t.common.appTitle),
                  const TextSpan(text: " "),
                  const WidgetSpan(child: AppVersionLabel(), alignment: PlaceholderAlignment.middle),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _SubscriptionFab(
        expanded: showSubscriptionInput.value,
        isLoading: addProfileState.isLoading,
        controller: subscriptionController,
        onToggle: () => showSubscriptionInput.value = !showSubscriptionInput.value,
        onClose: () => showSubscriptionInput.value = false,
        onSubmit: submitSubscription,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1080;
          final isCompactMobile = !isWide && constraints.maxHeight < 860;
          final heroHeight = isWide
              ? (constraints.maxHeight - 12).clamp(460.0, 760.0)
              : isCompactMobile
                  ? (constraints.maxHeight - 120).clamp(440.0, 540.0)
                  : 580.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            children: [
              SizedBox(
                height: heroHeight,
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 286,
                            child: _CountrySidebar(
                              selectedCountry: selectedCountry,
                              onSelect: ref.read(ConfigOptions.region.notifier).update,
                            ),
                          ).animate().fadeIn(duration: 320.ms).slideX(begin: -.06, end: 0),
                          const Gap(18),
                          Expanded(
                            child: _HomeStage(
                              selectedCountry: selectedCountry,
                              compact: false,
                            ),
                          ).animate().fadeIn(duration: 380.ms, delay: 60.ms),
                        ],
                      )
                    : Column(
                        children: [
                          _CountryStrip(
                            selectedCountry: selectedCountry,
                            onSelect: ref.read(ConfigOptions.region.notifier).update,
                          ).animate().fadeIn(duration: 280.ms).slideY(begin: -.04, end: 0),
                          const Gap(14),
                          Expanded(
                            child: _HomeStage(
                              selectedCountry: selectedCountry,
                              compact: isCompactMobile,
                            ),
                          ).animate().fadeIn(duration: 360.ms),
                        ],
                      ),
              ),
              const Gap(14),
              switch (activeProfile) {
                AsyncData(value: final profile?) => ProfileTile(
                  profile: profile,
                  isMain: true,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ).animate().fadeIn(duration: 280.ms, delay: 80.ms).slideY(begin: .04, end: 0),
                _ => const SizedBox.shrink(),
              },
              const Gap(12),
              const ActiveProxyFooter().animate().fadeIn(duration: 280.ms, delay: 120.ms).slideY(begin: .04, end: 0),
            ],
          );
        },
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
    final theme = Theme.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = (maxWidth - 32).clamp(300.0, 440.0);

    return AnimatedSwitcher(
      duration: 260.ms,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .92, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
      child: expanded
          ? NodaPanel(
              key: const ValueKey('subscription-expanded'),
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: SizedBox(
                width: panelWidth,
                child: Row(
                  children: [
                    Icon(Icons.add_link_rounded, color: theme.colorScheme.primary),
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
                      icon: const Icon(Icons.close_rounded),
                    ),
                    FilledButton.icon(
                      onPressed: isLoading ? null : () async => await onSubmit(),
                      icon: isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded),
                      label: Text(t.common.add),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 220.ms).slideY(begin: .08, end: 0)
          : NodaPanel(
              key: const ValueKey('subscription-collapsed'),
              radius: 999,
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onToggle,
                  child: const SizedBox(
                    width: 58,
                    height: 58,
                    child: Icon(Icons.add_link_rounded),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 220.ms).scale(begin: const Offset(.92, .92), end: const Offset(1, 1)),
    );
  }
}

class _HomeStage extends ConsumerWidget {
  const _HomeStage({
    required this.selectedCountry,
    required this.compact,
  });

  final Region selectedCountry;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final selectedCountryLabel = selectedCountry.present(t).split(' (').first;
    final connectionStatus = ref.watch(connectionNotifierProvider).valueOrNull;
    final isConnected = connectionStatus == const Connected();
    final isBusy = connectionStatus == const Connecting() || connectionStatus == const Disconnecting();
    final isApple = PlatformUtils.isIOS || PlatformUtils.isMacOS;
    final accentColor = isConnected
        ? const Color(0xFF47D7FF)
        : isBusy
            ? const Color(0xFF83C9FF)
            : theme.colorScheme.primary;
    final statusTitle = isConnected
        ? t.noda.home.connectedTitle(country: selectedCountryLabel)
        : isBusy
            ? t.noda.home.connectingTitle
            : t.noda.home.readyTitle;
    final statusHint = isConnected
        ? t.noda.home.connectedHint(country: selectedCountryLabel.toLowerCase())
        : isBusy
            ? t.noda.home.connectingHint
            : t.noda.home.disconnectedHint(country: selectedCountryLabel.toLowerCase());
    final panelPadding = compact
        ? const EdgeInsets.fromLTRB(16, 16, 16, 14)
        : EdgeInsets.fromLTRB(isApple ? 20 : 22, isApple ? 20 : 22, isApple ? 20 : 22, 18);
    final iconSize = compact ? 48.0 : 58.0;
    final iconRadius = compact ? 16.0 : 20.0;
    final iconInnerSize = compact ? 24.0 : 28.0;
    final contentGap = compact ? 12.0 : 18.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveCompact = compact || constraints.maxHeight < 680;
        final dense = constraints.maxHeight < 590;
        final localPanelPadding = effectiveCompact
            ? const EdgeInsets.fromLTRB(16, 16, 16, 14)
            : panelPadding;
        final localIconSize = dense
            ? 42.0
            : effectiveCompact
                ? 48.0
                : iconSize;
        final localIconRadius = dense
            ? 14.0
            : effectiveCompact
                ? 16.0
                : iconRadius;
        final localIconInnerSize = dense
            ? 22.0
            : effectiveCompact
                ? 24.0
                : iconInnerSize;
        final localContentGap = dense
            ? 10.0
            : effectiveCompact
                ? 12.0
                : contentGap;
        final titleStyle = dense ? theme.textTheme.headlineSmall : (effectiveCompact ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge);

        return NodaPanel(
          padding: localPanelPadding,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.12, -0.1),
                      radius: 0.9,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: 420.ms,
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.1),
                        radius: .78,
                        colors: [
                          accentColor.withValues(alpha: isConnected ? 0.16 : (isBusy ? 0.11 : 0.04)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: 320.ms,
                        curve: Curves.easeOutCubic,
                        width: localIconSize,
                        height: localIconSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(localIconRadius),
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withValues(alpha: 0.30),
                              accentColor.withValues(alpha: 0.12),
                            ],
                          ),
                          border: Border.all(color: accentColor.withValues(alpha: 0.38)),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: isConnected || isBusy ? 0.24 : 0.08),
                              blurRadius: isConnected ? 24 : 14,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isConnected
                              ? Icons.verified_rounded
                              : isBusy
                                  ? Icons.sync_rounded
                                  : Icons.bolt_rounded,
                          color: accentColor,
                          size: localIconInnerSize,
                        ),
                      )
                          .animate(target: isBusy ? 1 : 0)
                          .rotate(begin: 0, end: 1, duration: 1200.ms, curve: Curves.linear),
                      Gap(effectiveCompact ? 12 : 16),
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: 280.ms,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, .08), end: Offset.zero).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Wrap(
                            key: ValueKey(selectedCountryLabel),
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              Text(
                                selectedCountryLabel,
                                style: titleStyle,
                                textAlign: TextAlign.center,
                              ),
                              _StatusChip(
                                icon: Icons.lock_outline_rounded,
                                label: t.noda.home.ruDirect,
                                color: theme.colorScheme.secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap(effectiveCompact ? 8 : 12),
                  Text(
                    statusTitle,
                    textAlign: TextAlign.center,
                    style: (effectiveCompact ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Gap(localContentGap),
                  if (!dense) const Center(child: _ConnectionStateBadge()),
                  Gap(dense ? 8 : 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, stageConstraints) {
                        final maxButtonHeight = (stageConstraints.maxHeight - (dense ? 8 : 18)).clamp(
                          dense ? 132.0 : 168.0,
                          320.0,
                        );
                        final maxButtonWidth = (maxButtonHeight * 232 / 320).clamp(
                          dense ? 96.0 : 120.0,
                          232.0,
                        );
                        final hintGap = dense ? 8.0 : 14.0;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: AnimatedContainer(
                                duration: 320.ms,
                                curve: Curves.easeOutCubic,
                                width: maxButtonWidth,
                                height: maxButtonHeight,
                                child: FittedBox(
                                  child: AnimatedContainer(
                                    duration: 320.ms,
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(alpha: isConnected ? 0.22 : (isBusy ? 0.16 : 0.08)),
                                          blurRadius: isConnected ? 44 : 24,
                                          spreadRadius: -12,
                                        ),
                                      ],
                                    ),
                                    child: const ConnectionButton(),
                                  ),
                                ),
                              ),
                            ),
                            if (!dense) ...[
                              Gap(hintGap),
                              Center(
                                child: AnimatedSwitcher(
                                  duration: 250.ms,
                                  child: Text(
                                    statusHint,
                                    key: ValueKey('hint-$selectedCountryLabel-$isConnected-$isBusy'),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  Gap(dense ? 8 : 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _InfoChip(
                        icon: Icons.public_rounded,
                        title: t.noda.home.location,
                        value: selectedCountryLabel,
                      ),
                      _InfoChip(
                        icon: Icons.call_split_rounded,
                        title: t.noda.home.routing,
                        value: t.noda.home.routingBypassed,
                        accent: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConnectionStateBadge extends ConsumerWidget {
  const _ConnectionStateBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final status = ref.watch(connectionNotifierProvider);

    final ({String label, Color color, bool glow}) state = switch (status) {
      AsyncData(value: Connected()) => (
        label: t.noda.home.vpnEnabled,
        color: const Color(0xFF47D7FF),
        glow: true,
      ),
      AsyncData(value: Connecting()) || AsyncData(value: Disconnecting()) => (
        label: t.noda.home.switchingState,
        color: const Color(0xFF83C9FF),
        glow: true,
      ),
      _ => (
        label: t.noda.home.vpnDisabled,
        color: theme.colorScheme.error,
        glow: false,
      ),
    };

    final badge = AnimatedContainer(
      duration: 260.ms,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            state.color.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: state.color.withValues(alpha: 0.30)),
        boxShadow: state.glow
            ? [
                BoxShadow(
                  color: state.color.withValues(alpha: 0.18),
                  blurRadius: 26,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: state.color, enabled: state.glow),
          const Gap(10),
          Text(
            state.label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: state.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return state.glow
        ? badge.animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(
            duration: 1800.ms,
            color: state.color.withValues(alpha: 0.08),
          )
        : badge;
  }
}


class _PulseDot extends StatelessWidget {
  const _PulseDot({
    required this.color,
    required this.enabled,
  });

  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: enabled ? 0.72 : 0.24),
            blurRadius: enabled ? 16 : 6,
            spreadRadius: enabled ? 1 : 0,
          ),
        ],
      ),
    );

    return enabled
        ? dot.animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(
            begin: .88,
            end: 1.12,
            duration: 900.ms,
          )
        : dot;
  }
}

class _CountrySidebar extends ConsumerWidget {
  const _CountrySidebar({
    required this.selectedCountry,
    required this.onSelect,
  });

  final Region selectedCountry;
  final Future<void> Function(Region) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return NodaPanel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.24),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.30)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const Gap(10),
                Expanded(
                  child: Text(
                    t.noda.home.browseLocations,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const Gap(18),
          Text(t.noda.home.countries, style: Theme.of(context).textTheme.titleMedium),
          const Gap(10),
          Expanded(
            child: ListView.separated(
              itemCount: Region.availableCountries.length,
              separatorBuilder: (_, _) => const Gap(10),
              itemBuilder: (context, index) {
                final region = Region.availableCountries[index];
                return _CountryTile(
                  region: region,
                  selected: region == selectedCountry,
                  onTap: () async => await onSelect(region),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryStrip extends StatelessWidget {
  const _CountryStrip({
    required this.selectedCountry,
    required this.onSelect,
  });

  final Region selectedCountry;
  final Future<void> Function(Region) onSelect;

  @override
  Widget build(BuildContext context) {
    return NodaPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      radius: 24,
      child: SizedBox(
        height: 70,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: Region.availableCountries.length,
          separatorBuilder: (_, _) => const Gap(10),
          itemBuilder: (context, index) {
            final region = Region.availableCountries[index];
            return _CountryPill(
              region: region,
              selected: region == selectedCountry,
              onTap: () async => await onSelect(region),
            );
          },
        ),
      ),
    );
  }
}

class _CountryTile extends HookConsumerWidget {
  const _CountryTile({
    required this.region,
    required this.selected,
    required this.onTap,
  });

  final Region region;
  final bool selected;
  final VoidCallback onTap;

  String get _countryCode => region.name.toUpperCase();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final title = region.present(t).split(' (').first;
    final hovered = useState(false);
    final active = selected || hovered.value;

    return AnimatedScale(
      duration: 180.ms,
      scale: hovered.value ? 1.015 : 1,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: 240.ms,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: active
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: selected ? 0.42 : 0.24),
                    theme.colorScheme.primary.withValues(alpha: selected ? 0.22 : 0.12),
                  ],
                )
              : null,
          color: active ? null : theme.colorScheme.surface.withValues(alpha: 0.16),
          border: Border.all(
            color: active
                ? theme.colorScheme.primary.withValues(alpha: selected ? 0.60 : 0.34)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.30),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: hovered.value ? 0.16 : 0.10),
                    blurRadius: hovered.value ? 22 : 14,
                    spreadRadius: -6,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            onHover: (value) => hovered.value = value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: 180.ms,
                    scale: hovered.value ? 1.06 : 1,
                    child: IPCountryFlag(countryCode: _countryCode, size: 34),
                  ),
                  const Gap(12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: 180.ms,
                      style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      ),
                      child: Text(title),
                    ),
                  ),
                  AnimatedScale(
                    scale: active ? 1 : .9,
                    duration: 180.ms,
                    child: Icon(
                      selected ? Icons.radio_button_checked_rounded : Icons.arrow_outward_rounded,
                      color: active ? theme.colorScheme.secondary : theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(target: hovered.value ? 1 : 0).shimmer(duration: 900.ms, color: theme.colorScheme.primary.withValues(alpha: 0.06));
  }
}

class _CountryPill extends HookConsumerWidget {
  const _CountryPill({
    required this.region,
    required this.selected,
    required this.onTap,
  });

  final Region region;
  final bool selected;
  final VoidCallback onTap;

  String get _countryCode => region.name.toUpperCase();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final title = region.present(ref.watch(translationsProvider).requireValue).split(' (').first;
    final hovered = useState(false);
    final active = selected || hovered.value;

    return AnimatedScale(
      duration: 180.ms,
      scale: hovered.value ? 1.02 : 1,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: 220.ms,
        curve: Curves.easeOutCubic,
        width: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: active
              ? theme.colorScheme.primary.withValues(alpha: selected ? 0.30 : 0.18)
              : theme.colorScheme.surface.withValues(alpha: 0.14),
          border: Border.all(
            color: active
                ? theme.colorScheme.primary.withValues(alpha: selected ? 0.55 : 0.30)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.30),
          ),
          boxShadow: hovered.value
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    blurRadius: 20,
                    spreadRadius: -6,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            onHover: (value) => hovered.value = value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: 180.ms,
                    scale: hovered.value ? 1.05 : 1,
                    child: IPCountryFlag(countryCode: _countryCode, size: 32),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.title,
    required this.value,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;

    return NodaPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      radius: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(value, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NodaPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const Gap(8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.common.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
