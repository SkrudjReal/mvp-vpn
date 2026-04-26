import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
import 'package:hiddify/core/widget/app_logo.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'countries_sidebar.dart';
import 'map_background.dart';

class DesktopHomeLayout extends HookConsumerWidget {
  final Region selectedCountry;
  final AsyncValue<ConnectionStatus> connectionStatus;
  final Future<void> Function() onToggle;
  final String ip;
  final String provider;

  const DesktopHomeLayout({
    super.key,
    required this.selectedCountry,
    required this.connectionStatus,
    required this.onToggle,
    required this.ip,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final state = connectionStatus.valueOrNull;
    final isConnected = state == const Connected();
    final isBusy = state == const Connecting() || state == const Disconnecting();

    return Row(
      children: [
        // Left: Wide Countries Sidebar
        const CountriesSidebar(),

        // Right: Main Area
        Expanded(
          child: Stack(
            children: [
              // 1. Background Map
              MapBackground(isConnected: isConnected, selectedCountry: selectedCountry),

              // 2. Central Glassmorphism Card and Floating Cards
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Main connection card with Hover 3D
                      HookBuilder(
                        builder: (context) {
                          final isHovered = useState(false);
                          
                          return MouseRegion(
                            onEnter: (_) => isHovered.value = true,
                            onExit: (_) => isHovered.value = false,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutQuart,
                              transform: Matrix4.translationValues(0, isHovered.value ? -4.0 : 0.0, 0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                                  child: Container(
                                    width: 480,
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.light ? Colors.white.withValues(alpha: 0.85) : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: Theme.of(context).brightness == Brightness.light ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isHovered.value 
                                            ? Colors.black.withValues(alpha: 0.12)
                                            : Colors.black.withValues(alpha: 0.08),
                                          blurRadius: isHovered.value ? 80 : 60,
                                          offset: Offset(0, isHovered.value ? 30 : 20),
                                          spreadRadius: -15,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Top row: country and status
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "ВЫБРАННЫЙ СЕРВЕР",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.2,
                                                    color: context.nodaMuted,
                                                  ),
                                                ),
                                                const Gap(4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      selectedCountry.present(t).split(' ').first,
                                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.nodaText),
                                                    ),
                                                    const Gap(8),
                                                    Icon(Icons.keyboard_arrow_down, size: 16, color: context.nodaMuted),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            _DesktopProtectionChip(connected: isConnected, busy: isBusy),
                                          ],
                                        ),
                                        const Gap(40),
                                        
                                        // Connection Button
                                        _DesktopPowerButton(connected: isConnected, busy: isBusy, onTap: onToggle),
                                        const Gap(32),
                                        
                                        // Text status
                                        Text(
                                          isBusy ? "Переключаем..." : (isConnected ? "Подключено" : "Готов к работе"),
                                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: context.nodaText),
                                        ),
                                        const Gap(6),
                                        Text(
                                          isBusy ? "Ожидайте ответа от сервера" : (isConnected ? "Ваша активность надежно зашифрована" : "Лучший сервер на основе вашей локации"),
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.nodaMuted),
                                        ),
                                        const Gap(32),
                                        
                                        // Stats
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border(top: BorderSide(color: context.nodaBorder)),
                                          ),
                                          padding: const EdgeInsets.only(top: 24),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _StatCol(label: "ПРОТОКОЛ", value: "Reality"),
                                              ),
                                              Container(width: 1, height: 32, color: context.nodaBorder),
                                              Expanded(
                                                child: _StatCol(label: "ТРАФИК", value: isConnected ? "0.00 KB/s" : "--"),
                                              ),
                                            ],
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
                      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut).slideY(begin: 0.05, end: 0),
                      
                      const Gap(24),
                      
                      // Bottom IP / Provider cards
                      SizedBox(
                        width: 480,
                        child: Row(
                          children: [
                            Expanded(child: _DesktopInfoBlock(label: "ВАШ IP", value: ip, icon: Icons.public, isConnected: isConnected)),
                            const Gap(16),
                            Expanded(child: _DesktopInfoBlock(label: "ПРОВАЙДЕР", value: provider, icon: Icons.router, isConnected: isConnected)),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0),
                    ],
                  ),
                ),
              ),

              // 3. Right Floating Panels (Features)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.light ? Colors.white.withValues(alpha: 0.8) : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.light ? Colors.white.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _FeatureItem(icon: Icons.settings_rounded, label: "Settings"),
                            const Gap(16),
                            _FeatureItem(icon: Icons.dashboard_customize_rounded, label: "Customize"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopProtectionChip extends StatelessWidget {
  final bool connected;
  final bool busy;

  const _DesktopProtectionChip({required this.connected, required this.busy});

  @override
  Widget build(BuildContext context) {
    final active = connected || busy;
    final isGreen = connected && !busy;
    
    final color = isGreen 
        ? Colors.green 
        : (busy ? context.nodaNeon : context.nodaMuted);
    
    final label = busy ? "ПРОЦЕСС" : (connected ? "ЗАЩИЩЕНО" : "ПАУЗА");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.1) : context.nodaSurfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? color.withValues(alpha: 0.3) : context.nodaBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(busy ? Icons.autorenew : Icons.shield_rounded, size: 12, color: color),
          const Gap(6),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: color),
          ),
        ],
      ),
    );
  }
}

class _DesktopPowerButton extends HookWidget {
  final bool connected;
  final bool busy;
  final Future<void> Function() onTap;

  const _DesktopPowerButton({required this.connected, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final isHovered = useState(false);
    final active = connected || busy;
    final accent = context.nodaNeon;

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTapDown: (_) => pressed.value = true,
        onTapCancel: () => pressed.value = false,
        onTapUp: (_) => pressed.value = false,
        onTap: onTap,
        child: AnimatedScale(
          duration: 150.ms,
          scale: pressed.value ? 0.95 : (isHovered.value ? 1.05 : 1.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (active)
                ...[
                  AnimatedContainer(
                    duration: 500.ms,
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).scaleXY(begin: 1.0, end: 1.5, duration: 2.5.seconds).fade(begin: 0.8, end: 0),
                  AnimatedContainer(
                    duration: 500.ms,
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(), delay: 1.25.seconds).scaleXY(begin: 1.0, end: 1.5, duration: 2.5.seconds).fade(begin: 0.8, end: 0),
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.05),
                          blurRadius: 30,
                          spreadRadius: 10,
                        )
                      ]
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1, duration: 1.seconds),
                ],
              
              AnimatedContainer(
                duration: 300.ms,
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? Colors.white : (isHovered.value ? Colors.grey.shade200 : Colors.grey.shade100),
                    width: active ? 4 : 3,
                  ),
                  boxShadow: active ? [
                    BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 50, offset: const Offset(0, 20))
                  ] : [
                    BoxShadow(color: Colors.black.withValues(alpha: isHovered.value ? 0.08 : 0.05), blurRadius: isHovered.value ? 40 : 30, offset: Offset(0, isHovered.value ? 15 : 10))
                  ],
                ),
                child: Center(
                  child: busy
                      ? SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: accent))
                      : Text(
                          "noda.",
                          style: GoogleFonts.cookie(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: accent,
                            height: 1.0,
                          ),
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

class _StatCol extends StatelessWidget {
  final String label;
  final String value;

  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: context.nodaMuted),
        ),
        const Gap(6),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.nodaText),
        ),
      ],
    );
  }
}

class _DesktopInfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isConnected;

  const _DesktopInfoBlock({required this.label, required this.value, required this.icon, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light ? Colors.white.withValues(alpha: 0.8) : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).brightness == Brightness.light ? Colors.white.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isConnected ? context.nodaNeon.withValues(alpha: 0.1) : context.nodaSurfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: isConnected ? context.nodaNeon : context.nodaMuted),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: context.nodaMuted),
                    ),
                    const Gap(2),
                    Text(
                      value,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.nodaText),
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

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              hoverColor: Colors.white,
              child: Icon(icon, size: 24, color: context.nodaMuted),
            ),
          ),
        ),
        const Gap(6),
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: context.nodaMuted),
        ),
      ],
    );
  }
}
