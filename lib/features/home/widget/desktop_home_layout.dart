import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/home/widget/countries_sidebar.dart';
import 'package:hiddify/features/home/widget/map_background.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/noda_settings_components.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum HomeModalMode { routing, audit, settings, about }

enum SettingsModalPage { overview, general, routing, about }

class DesktopHomeLayout extends HookConsumerWidget {
  const DesktopHomeLayout({
    super.key,
    required this.selectedCountry,
    required this.connectionStatus,
    required this.onToggle,
    required this.ip,
    required this.provider,
  });

  final Region selectedCountry;
  final AsyncValue<ConnectionStatus> connectionStatus;
  final Future<void> Function() onToggle;
  final String ip;
  final String provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalMode = useState<HomeModalMode?>(null);
    final state = connectionStatus.valueOrNull;
    final isConnected = state == const Connected();
    final isBusy = state == const Connecting() || state == const Disconnecting();

    return Row(
      children: [
        CountriesSidebar(
          selectedCountry: selectedCountry,
          onOpenAIAudit: () => modalMode.value = HomeModalMode.audit,
          onOpenSettings: () => modalMode.value = HomeModalMode.settings,
          onOpenAbout: () => modalMode.value = HomeModalMode.about,
        ),
        Expanded(
          child: ClipRect(
            child: DecoratedBox(
              decoration: BoxDecoration(color: context.nodaBg),
              child: Stack(
                children: [
                  MapBackground(isConnected: isConnected, selectedCountry: selectedCountry),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(56, 28, 116, 38),
                      child: Column(
                        children: [
                          _WorkspaceHeader(isConnected: isConnected, isBusy: isBusy, selectedCountry: selectedCountry),
                          const Spacer(),
                          _ConnectionCard(
                            selectedCountry: selectedCountry,
                            isConnected: isConnected,
                            isBusy: isBusy,
                            onToggle: onToggle,
                          ).animate().fadeIn(duration: 420.ms).slideY(begin: .035, end: 0),
                          const Gap(22),
                          SizedBox(
                            width: 520,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _InfoBlock(
                                    label: 'YOUR IP',
                                    value: _cleanValue(ip),
                                    icon: Icons.public_rounded,
                                    isConnected: isConnected,
                                  ),
                                ),
                                const Gap(14),
                                Expanded(
                                  child: _InfoBlock(
                                    label: 'PROVIDER',
                                    value: _cleanValue(provider),
                                    icon: Icons.router_rounded,
                                    isConnected: isConnected,
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: 80.ms).fadeIn(duration: 420.ms).slideY(begin: .045, end: 0),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  _FeaturePill(
                    isConnected: isConnected,
                    onOpenAiRouting: () => modalMode.value = HomeModalMode.routing,
                    onOpenSettings: () => modalMode.value = HomeModalMode.settings,
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _cleanValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '--') return '--';
    return trimmed;
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({required this.isConnected, required this.isBusy, required this.selectedCountry});

  final bool isConnected;
  final bool isBusy;
  final Region selectedCountry;

  @override
  Widget build(BuildContext context) {
    final accent = context.nodaNeon;

    return Row(
      children: [
        _StatusDot(isConnected: isConnected, isBusy: isBusy),
        const Gap(12),
        Text(
          isBusy
              ? 'Establishing secure tunnel'
              : isConnected
              ? 'Protected through ${_regionName(selectedCountry)}'
              : 'Ready to secure your connection',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.nodaText),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: context.nodaSurface.withValues(alpha: context.isDark ? .70 : .86),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isConnected ? accent.withValues(alpha: .36) : context.nodaBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? .22 : .06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.speed_rounded, size: 16, color: isConnected ? accent : context.nodaMuted),
              const Gap(8),
              Text(
                isConnected ? '18 ms' : 'Fastest node',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isConnected ? accent : context.nodaMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isConnected, required this.isBusy});

  final bool isConnected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final color = isConnected || isBusy ? context.nodaNeon : context.nodaMuted;

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isConnected || isBusy ? [BoxShadow(color: color.withValues(alpha: .55), blurRadius: 16)] : null,
      ),
    );
  }
}

class _ConnectionCard extends HookConsumerWidget {
  const _ConnectionCard({
    required this.selectedCountry,
    required this.isConnected,
    required this.isBusy,
    required this.onToggle,
  });

  final Region selectedCountry;
  final bool isConnected;
  final bool isBusy;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hovered = useState(false);
    final pointer = useState(Offset.zero);
    final accent = context.nodaNeon;
    final active = isConnected || isBusy;

    return MouseRegion(
      onEnter: (_) => hovered.value = true,
      onHover: (event) => pointer.value = event.localPosition,
      onExit: (_) {
        hovered.value = false;
        pointer.value = Offset.zero;
      },
      child: AnimatedContainer(
        duration: 360.ms,
        curve: Curves.easeOutCubic,
        width: 430,
        transform: _cardTransform(pointer.value, hovered.value),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: 360.ms,
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: context.nodaSurface.withValues(alpha: context.isDark ? .76 : .72),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: active ? accent.withValues(alpha: .46) : context.nodaBorder),
                      boxShadow: [
                        BoxShadow(
                          color: active
                              ? accent.withValues(alpha: context.isDark ? .24 : .18)
                              : Colors.black.withValues(alpha: context.isDark ? .36 : .10),
                          blurRadius: hovered.value ? 62 : 46,
                          offset: Offset(0, hovered.value ? 28 : 20),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(child: _CardGlassSurface(active: active)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 30, 34, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _ServerSelector(selectedCountry: selectedCountry),
                          const Spacer(),
                          _ProtectionPill(isConnected: isConnected, isBusy: isBusy),
                        ],
                      ),
                      const Gap(42),
                      _DesktopPowerButton(connected: isConnected, busy: isBusy, onTap: onToggle),
                      const Gap(30),
                      AnimatedSwitcher(
                        duration: 260.ms,
                        child: Text(
                          _title,
                          key: ValueKey(_title),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: context.nodaText),
                        ),
                      ),
                      const Gap(8),
                      AnimatedSwitcher(
                        duration: 260.ms,
                        child: Text(
                          _subtitle,
                          key: ValueKey(_subtitle),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.nodaMuted),
                        ),
                      ),
                      const Gap(30),
                      Divider(height: 1, color: context.nodaBorder),
                      const Gap(22),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCol(label: 'PROTOCOL', value: 'Reality', active: active),
                          ),
                          Container(width: 1, height: 38, color: context.nodaBorder),
                          Expanded(
                            child: _StatCol(label: 'ROUTE', value: _regionName(selectedCountry), active: active),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hovered.value)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: context.isDark ? .08 : .48)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    if (isBusy) return 'Connecting';
    if (isConnected) return 'Protected';
    return 'Disconnected';
  }

  String get _subtitle {
    if (isBusy) return 'Applying routes and starting tunnel';
    if (isConnected) return 'Traffic is encrypted and routed privately';
    return 'Tap noda to start a secure session';
  }

  Matrix4 _cardTransform(Offset pointer, bool hovered) {
    const width = 430.0;
    const height = 520.0;

    if (!hovered || pointer == Offset.zero) {
      return Matrix4.identity();
    }

    final x = ((pointer.dx / width) - .5).clamp(-.5, .5);
    final y = ((pointer.dy / height) - .5).clamp(-.5, .5);

    return Matrix4.identity()
      ..setEntry(3, 2, .0009)
      ..translateByDouble(0, -6, 0, 1)
      ..rotateX(-y * .075)
      ..rotateY(x * .095);
  }
}

class _CardGlassSurface extends StatelessWidget {
  const _CardGlassSurface({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: context.isDark ? .09 : .48),
              Colors.white.withValues(alpha: context.isDark ? .02 : .18),
              context.nodaNeon.withValues(alpha: active ? .08 : .015),
            ],
            stops: const [0, .48, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 22,
              right: 22,
              top: 1,
              child: Container(height: 1, color: Colors.white.withValues(alpha: context.isDark ? .15 : .70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerSelector extends ConsumerWidget {
  const _ServerSelector({required this.selectedCountry});

  final Region selectedCountry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<Region>(
      offset: const Offset(0, 42),
      elevation: 0,
      color: context.nodaSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.nodaBorder),
      ),
      onSelected: (region) => ref.read(ConfigOptions.region.notifier).update(region),
      itemBuilder: (_) => Region.availableCountries.map((region) {
        return PopupMenuItem(
          value: region,
          child: Row(
            children: [
              _FlagBubble(region: region, size: 22),
              const Gap(10),
              Text(
                _regionName(region),
                style: TextStyle(fontWeight: FontWeight.w800, color: context.nodaText),
              ),
            ],
          ),
        );
      }).toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FlagBubble(region: selectedCountry, size: 28),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECTED SERVER',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: context.nodaMuted,
                ),
              ),
              const Gap(4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _regionName(selectedCountry),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: context.nodaText),
                  ),
                  const Gap(4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: context.nodaMuted),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProtectionPill extends StatelessWidget {
  const _ProtectionPill({required this.isConnected, required this.isBusy});

  final bool isConnected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final active = isConnected || isBusy;
    final label = isBusy
        ? 'CONNECTING'
        : isConnected
        ? 'SECURE'
        : 'IDLE';

    return AnimatedContainer(
      duration: 260.ms,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: active ? context.nodaNeon.withValues(alpha: .12) : context.nodaSurfaceSoft.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? context.nodaNeon.withValues(alpha: .42) : context.nodaBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBusy ? Icons.sync_rounded : Icons.shield_rounded,
            size: 13,
            color: active ? context.nodaNeon : context.nodaMuted,
          ),
          const Gap(6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
              color: active ? context.nodaNeon : context.nodaMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopPowerButton extends HookWidget {
  const _DesktopPowerButton({required this.connected, required this.busy, required this.onTap});

  final bool connected;
  final bool busy;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final hovered = useState(false);
    final spinController = useAnimationController(duration: 1400.ms);
    final active = connected || busy;
    final accent = context.nodaNeon;

    useEffect(() {
      if (busy) {
        spinController.repeat();
      } else {
        spinController.stop();
      }
      return null;
    }, [busy]);

    return MouseRegion(
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: GestureDetector(
        onTapDown: (_) => pressed.value = true,
        onTapCancel: () => pressed.value = false,
        onTapUp: (_) => pressed.value = false,
        onTap: onTap,
        child: AnimatedScale(
          duration: 130.ms,
          curve: Curves.easeOutCubic,
          scale: pressed.value
              ? .95
              : hovered.value
              ? 1.03
              : 1,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (active) ...[
                  _SonarRing(color: accent, delay: Duration.zero),
                  _SonarRing(color: accent, delay: 700.ms),
                  _SonarRing(color: accent, delay: 1400.ms),
                ],
                if (busy)
                  RotationTransition(
                    turns: spinController,
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: CircularProgressIndicator(
                        value: .62,
                        strokeWidth: 2.5,
                        strokeCap: StrokeCap.round,
                        color: accent,
                        backgroundColor: accent.withValues(alpha: .10),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: 340.ms,
                  curve: Curves.easeOutCubic,
                  width: 142,
                  height: 142,
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF070A10) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active ? accent.withValues(alpha: .88) : context.nodaBorder,
                      width: active ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: active
                            ? accent.withValues(alpha: context.isDark ? .42 : .28)
                            : Colors.black.withValues(alpha: context.isDark ? .32 : .12),
                        blurRadius: active ? 46 : 24,
                        offset: const Offset(0, 18),
                      ),
                      if (active)
                        BoxShadow(color: accent.withValues(alpha: .24), blurRadius: 22, blurStyle: BlurStyle.inner),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Text(
                      'noda.',
                      style: GoogleFonts.cookie(
                        fontSize: 62,
                        height: 1,
                        color: active ? accent : context.nodaText.withValues(alpha: context.isDark ? .54 : .72),
                        shadows: active ? [Shadow(color: accent.withValues(alpha: .50), blurRadius: 20)] : null,
                      ),
                    ),
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

class _SonarRing extends StatelessWidget {
  const _SonarRing({required this.color, required this.delay});

  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 142,
          height: 142,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: .32), width: 2),
          ),
        )
        .animate(delay: delay, onPlay: (controller) => controller.repeat())
        .scaleXY(begin: 1, end: 1.58, duration: 2100.ms, curve: Curves.easeOut)
        .fade(begin: .62, end: 0, duration: 2100.ms, curve: Curves.easeOut);
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({required this.label, required this.value, required this.active});

  final String label;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: context.nodaMuted),
        ),
        const Gap(8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: active ? context.nodaNeon : context.nodaText,
          ),
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value, required this.icon, required this.isConnected});

  final String label;
  final String value;
  final IconData icon;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AnimatedContainer(
          duration: 260.ms,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: context.nodaSurface.withValues(alpha: context.isDark ? .74 : .78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isConnected ? context.nodaNeon.withValues(alpha: .35) : context.nodaBorder),
            boxShadow: [
              BoxShadow(
                color: isConnected
                    ? context.nodaNeon.withValues(alpha: .13)
                    : Colors.black.withValues(alpha: context.isDark ? .28 : .08),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isConnected ? context.nodaNeon.withValues(alpha: .12) : context.nodaSurfaceSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: isConnected ? context.nodaNeon.withValues(alpha: .32) : context.nodaBorder),
                ),
                child: Icon(icon, size: 17, color: isConnected ? context.nodaNeon : context.nodaMuted),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                        color: context.nodaMuted,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isConnected ? context.nodaNeon : context.nodaText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.isConnected, required this.onOpenAiRouting, required this.onOpenSettings});

  final bool isConnected;
  final VoidCallback onOpenAiRouting;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 30,
      top: 0,
      bottom: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
              decoration: BoxDecoration(
                color: context.nodaSurface.withValues(alpha: context.isDark ? .72 : .82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: isConnected ? context.nodaNeon.withValues(alpha: .34) : context.nodaBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? .28 : .10),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PillButton(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI ROUTING',
                    tooltip: 'AI routing',
                    special: true,
                    onTap: onOpenAiRouting,
                  ),
                  const _PillDivider(),
                  _PillButton(
                    icon: Icons.settings_rounded,
                    label: 'SETTINGS',
                    tooltip: 'Settings',
                    onTap: onOpenSettings,
                  ),
                  const _PillDivider(),
                  _PillButton(icon: Icons.grid_view_rounded, label: 'VIEW', tooltip: 'View', onTap: onOpenSettings),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends HookWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.special = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool special;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: 180.ms,
                    curve: Curves.easeOutCubic,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: special
                          ? context.nodaNeon.withValues(alpha: .15)
                          : hovered.value
                          ? context.nodaSurfaceSoft
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: special
                            ? context.nodaNeon.withValues(alpha: .40)
                            : hovered.value
                            ? context.nodaBorder
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: special
                          ? context.nodaNeon
                          : hovered.value
                          ? context.nodaText
                          : context.nodaMuted,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: special ? context.nodaNeon : context.nodaMuted,
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

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 24, height: 1, margin: const EdgeInsets.symmetric(vertical: 5), color: context.nodaBorder);
  }
}

class _LinkFab extends StatelessWidget {
  const _LinkFab({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 32,
      bottom: 32,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF0A101A),
          shape: BoxShape.circle,
          border: Border.all(color: isConnected ? const Color(0x9900BFFF) : const Color(0x1AFFFFFF)),
          boxShadow: [
            BoxShadow(
              color: isConnected ? const Color(0x6600BFFF) : const Color(0xCC000000),
              blurRadius: isConnected ? 25 : 40,
              offset: isConnected ? Offset.zero : const Offset(0, 15),
            ),
          ],
        ),
        child: Icon(Icons.link_rounded, color: isConnected ? const Color(0xFF00BFFF) : Colors.grey),
      ),
    );
  }
}

class GlassSectionModal extends HookConsumerWidget {
  const GlassSectionModal({required this.mode, required this.onClose});

  final HomeModalMode mode;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState<SettingsModalPage>(mode == HomeModalMode.about ? SettingsModalPage.about : SettingsModalPage.overview);
    final title = switch (page.value) {
      SettingsModalPage.overview => 'Settings',
      SettingsModalPage.general => 'General',
      SettingsModalPage.routing => 'Routing',
      SettingsModalPage.about => 'About',
    };
    final subtitle = switch (page.value) {
      SettingsModalPage.overview => 'Protocol, routing and account controls.',
      SettingsModalPage.general => 'Language, appearance and client preferences.',
      SettingsModalPage.routing => 'Location and direct-routing behavior.',
      SettingsModalPage.about => 'Version, product information and useful links.',
    };
    final canGoBack = page.value != SettingsModalPage.overview && mode != HomeModalMode.about;

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.black.withValues(alpha: context.isDark ? .34 : .16),
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  width: 820,
                  constraints: const BoxConstraints(maxWidth: 920, maxHeight: 760),
                  decoration: BoxDecoration(
                    color: context.nodaSurface.withValues(alpha: context.isDark ? .78 : .76),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: context.nodaNeon.withValues(alpha: .26)),
                    boxShadow: [
                      BoxShadow(
                        color: context.nodaNeon.withValues(alpha: context.isDark ? .18 : .10),
                        blurRadius: 70,
                        offset: const Offset(0, 26),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDark ? .38 : .10),
                        blurRadius: 44,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: _ModalGlassTint(active: mode == HomeModalMode.settings)),
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (canGoBack) ...[
                                  IconButton(
                                    onPressed: () => page.value = SettingsModalPage.overview,
                                    icon: Icon(Icons.arrow_back_rounded, color: context.nodaMuted),
                                  ),
                                  const Gap(6),
                                ],
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: context.nodaNeon.withValues(alpha: .12),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: context.nodaNeon.withValues(alpha: .30)),
                                  ),
                                  child: Icon(
                                    switch (page.value) {
                                      SettingsModalPage.overview => Icons.settings_rounded,
                                      SettingsModalPage.general => Icons.layers_rounded,
                                      SettingsModalPage.routing => Icons.route_rounded,
                                      SettingsModalPage.about => Icons.info_rounded,
                                    },
                                    color: context.nodaNeon,
                                    size: 20,
                                  ),
                                ),
                                const Gap(14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: context.nodaText,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Gap(3),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: context.nodaMuted,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: onClose,
                                  icon: Icon(Icons.close_rounded, color: context.nodaMuted),
                                ),
                              ],
                            ),
                            const Gap(24),
                            Flexible(
                              child: AnimatedSwitcher(
                                duration: 220.ms,
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: SingleChildScrollView(
                                  key: ValueKey(page.value),
                                  child: switch (page.value) {
                                    SettingsModalPage.overview => _SettingsPopupContent(
                                      onOpenGeneral: () => page.value = SettingsModalPage.general,
                                      onOpenRouting: () => page.value = SettingsModalPage.routing,
                                      onOpenAbout: () => page.value = SettingsModalPage.about,
                                    ),
                                    SettingsModalPage.general => const _GeneralPopupContent(),
                                    SettingsModalPage.routing => const _RoutingPopupContent(),
                                    SettingsModalPage.about => const _AboutPopupContent(),
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 180.ms).scaleXY(begin: .97, end: 1, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }
}

class _ModalGlassTint extends StatelessWidget {
  const _ModalGlassTint({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: context.isDark ? .08 : .50),
              Colors.white.withValues(alpha: context.isDark ? .02 : .14),
              context.nodaNeon.withValues(alpha: active ? .08 : .04),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsPopupContent extends ConsumerWidget {
  const _SettingsPopupContent({required this.onOpenGeneral, required this.onOpenRouting, required this.onOpenAbout});

  final VoidCallback onOpenGeneral;
  final VoidCallback onOpenRouting;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Column(
      children: [
        _PopupActionCard(
          icon: Icons.layers_rounded,
          title: t.pages.settings.general.title,
          description: t.noda.settings.generalSubtitle,
          onTap: onOpenGeneral,
        ),
        const Gap(14),
        _PopupActionCard(
          icon: Icons.route_rounded,
          title: t.pages.settings.routing.title,
          description: t.noda.settings.routingSubtitle,
          onTap: onOpenRouting,
        ),
        const Gap(14),
        _PopupActionCard(
          icon: Icons.info_rounded,
          title: t.pages.about.title,
          description: t.noda.settings.aboutSubtitle,
          onTap: onOpenAbout,
        ),
      ],
    );
  }
}

class _GeneralPopupContent extends ConsumerWidget {
  const _GeneralPopupContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsPremiumCard(
      child: Column(
        children: [
          const LocalePrefTile(),
          Divider(height: 1, color: context.nodaBorder, indent: 24, endIndent: 24),
          const ThemeModePrefTile(),
          Divider(height: 1, color: context.nodaBorder, indent: 24, endIndent: 24),
          const EnableAnalyticsPrefTile(),
        ],
      ),
    );
  }
}

class _RoutingPopupContent extends ConsumerWidget {
  const _RoutingPopupContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return SettingsPremiumCard(
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
    );
  }
}

class _AboutPopupContent extends ConsumerWidget {
  const _AboutPopupContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final appInfo = ref.watch(appInfoProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _popupCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('noda.', style: GoogleFonts.cookie(fontSize: 42, height: 1, color: context.nodaText)),
              const Gap(14),
              Text(
                appInfo == null ? 'Version loading...' : 'Version ${appInfo.presentVersion}',
                style: TextStyle(color: context.nodaNeon, fontSize: 12, fontWeight: FontWeight.w900),
              ),
              const Gap(12),
              Text(
                t.noda.about.summary,
                style: TextStyle(color: context.nodaMuted, fontSize: 13, height: 1.45, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const Gap(14),
        _PopupInfoRow(
          icon: Icons.code_rounded,
          title: t.pages.about.sourceCode,
          onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.githubUrl)),
        ),
        const Gap(10),
        _PopupInfoRow(
          icon: Icons.shield_rounded,
          title: t.pages.about.privacyPolicy,
          onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.privacyPolicyUrl)),
        ),
        const Gap(10),
        _PopupInfoRow(
          icon: Icons.description_rounded,
          title: t.pages.about.termsAndConditions,
          onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.termsAndConditionsUrl)),
        ),
      ],
    );
  }
}

class _PopupActionCard extends HookWidget {
  const _PopupActionCard({required this.icon, required this.title, required this.description, required this.onTap});

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return MouseRegion(
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: 180.ms,
            padding: const EdgeInsets.all(18),
            decoration: _popupCardDecoration(context, highlighted: hovered.value),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.nodaNeon.withValues(alpha: .12),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.nodaNeon.withValues(alpha: .24)),
                  ),
                  child: Icon(icon, color: context.nodaNeon, size: 20),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: context.nodaText, fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                      const Gap(4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.nodaMuted, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: hovered.value ? context.nodaNeon : context.nodaMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupInfoRow extends StatelessWidget {
  const _PopupInfoRow({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: _popupCardDecoration(context),
          child: Row(
            children: [
              Icon(icon, color: context.nodaNeon, size: 18),
              const Gap(12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: context.nodaText, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: context.nodaMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _popupCardDecoration(BuildContext context, {bool highlighted = false}) {
  return BoxDecoration(
    color: highlighted
        ? context.nodaSurfaceSoft.withValues(alpha: .92)
        : context.nodaSurfaceSoft.withValues(alpha: .72),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: highlighted ? context.nodaNeon.withValues(alpha: .30) : context.nodaBorder),
    boxShadow: highlighted
        ? [BoxShadow(color: context.nodaNeon.withValues(alpha: .10), blurRadius: 22, offset: const Offset(0, 12))]
        : null,
  );
}

class AiModal extends HookConsumerWidget {
  const AiModal({
    required this.mode,
    required this.isConnected,
    required this.selectedCountry,
    required this.onClose,
    required this.onSelectCountry,
  });

  final HomeModalMode mode;
  final bool isConnected;
  final Region selectedCountry;
  final VoidCallback onClose;
  final ValueChanged<Region> onSelectCountry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = useTextEditingController();
    final loading = useState(mode == HomeModalMode.audit);
    final resultText = useState<String?>(null);
    final resultServer = useState<Region?>(null);

    useEffect(() {
      if (mode == HomeModalMode.audit) {
        loading.value = true;
        Future<void>.delayed(850.ms, () {
          if (!context.mounted) return;
          final server = _regionName(selectedCountry);
          resultText.value = isConnected
              ? 'Tunnel active through $server. IP masking is enabled, route health looks stable.'
              : 'VPN is offline. Your direct route is exposed until noda protection is enabled.';
          loading.value = false;
        });
      }
      return null;
    }, [mode, isConnected, selectedCountry]);

    Future<void> runRouting() async {
      if (prompt.text.trim().isEmpty || loading.value) return;
      loading.value = true;
      resultText.value = null;
      resultServer.value = null;
      await Future<void>.delayed(750.ms);
      if (!context.mounted) return;

      final text = prompt.text.toLowerCase();
      final picked = text.contains('netflix') || text.contains('usa') || text.contains('сша')
          ? Region.us
          : text.contains('asia') || text.contains('singapore') || text.contains('азия')
          ? Region.sg
          : Region.fi;

      resultServer.value = picked;
      resultText.value = '${_regionName(picked)} selected as the best visual route for this task.';
      onSelectCountry(picked);
      loading.value = false;
    }

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: const Color(0xE6060913),
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0A101A),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0x6600BFFF)),
                boxShadow: const [BoxShadow(color: Color(0x3300BFFF), blurRadius: 80)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00BFFF)),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          mode == HomeModalMode.routing ? 'AI Smart Routing' : 'Security Audit',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Gap(16),
                  if (mode == HomeModalMode.routing) ...[
                    const Text(
                      'Describe your task and noda will suggest a server. This is a local UI preview, no external API call.',
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.35),
                    ),
                    const Gap(24),
                    TextField(
                      controller: prompt,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'What are you planning to do?',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF080D16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF00BFFF)),
                        ),
                      ),
                      onSubmitted: (_) => runRouting(),
                    ),
                    const Gap(24),
                    _ModalActionButton(loading: loading.value, label: 'Pick server', onTap: runRouting),
                  ] else ...[
                    const Text(
                      'noda is analyzing the visible protection state of your current session.',
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.35),
                    ),
                    const Gap(24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080D16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x1AFFFFFF)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isConnected ? Icons.lock_rounded : Icons.lock_open_rounded,
                            size: 32,
                            color: isConnected ? const Color(0xFF00BFFF) : Colors.redAccent,
                          ),
                          const Gap(12),
                          Text(
                            'STATUS: ${isConnected ? 'SECURE' : 'EXPOSED'}',
                            style: TextStyle(
                              color: isConnected ? const Color(0xFF00BFFF) : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (loading.value)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF00BFFF), strokeWidth: 2)),
                      ),
                  ],
                  if (resultText.value != null) ...[
                    const Gap(24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080D16),
                        borderRadius: BorderRadius.circular(16),
                        border: const Border(left: BorderSide(color: Color(0xFF00BFFF), width: 4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (resultServer.value != null) ...[
                            Text(
                              'SELECTED: ${_regionName(resultServer.value!)}',
                              style: const TextStyle(
                                color: Color(0xFF00BFFF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const Gap(8),
                          ],
                          Text(
                            resultText.value!,
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 180.ms).scaleXY(begin: .96, end: 1, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }
}

class _ModalActionButton extends StatelessWidget {
  const _ModalActionButton({required this.loading, required this.label, required this.onTap});

  final bool loading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0x1A00BFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x8000BFFF)),
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: Color(0xFF00BFFF), strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(color: Color(0xFF00BFFF), fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

class _FlagBubble extends StatelessWidget {
  const _FlagBubble({required this.region, required this.size});

  final Region region;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.nodaSurfaceSoft,
        shape: BoxShape.circle,
        border: Border.all(color: context.nodaBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .10), blurRadius: 10)],
      ),
      child: Transform.scale(
        scale: 1.28,
        child: IPCountryFlag(countryCode: _flagCode(region), size: size * 1.45),
      ),
    );
  }
}

String _regionName(Region region) {
  return switch (region) {
    Region.fi => 'Finland',
    Region.nl => 'Netherlands',
    Region.de => 'Germany',
    Region.us => 'United States',
    Region.uk => 'United Kingdom',
    Region.sg => 'Singapore',
    Region.ir => 'Iran',
    Region.cn => 'China',
    Region.ru => 'Russia',
    Region.af => 'Afghanistan',
    Region.id => 'Indonesia',
    Region.tr => 'Turkey',
    Region.br => 'Brazil',
    Region.other => 'Other',
    _ => region.name.toUpperCase(),
  };
}

String _flagCode(Region region) {
  return switch (region) {
    Region.uk => 'GB',
    Region.other => 'FI',
    _ => region.name.toUpperCase(),
  };
}
