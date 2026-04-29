import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/core/widget/app_logo.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// TODO: rewrite
class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;

    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;
    final today = DateTime.now();
    // final animationController = useAnimationController(
    //   duration: const Duration(seconds: 1),
    // )..repeat(reverse: true); // Ensure the animation loops indefinitely

    //   // Listen to the animation's value
    //   final animationValue = useAnimation(Tween<double>(begin: 0.8, end: 1).animate(animationController));

    //   // useEffect(() {
    //   //   if (true) {
    //   // Start repeating animation
    //   //   } else {
    //   //     animationController.stop(); // Stop animation if connected, disconnected, or error
    //   //   }

    //   //   // Cleanup when widget is disposed
    //   //   return animationController.dispose;
    //   // }, [connectionStatus.value]);

    //   // ref.listen(
    //   //   connectionNotifierProvider,
    //   //   (_, next) {
    //   //     if (next case AsyncError(:final error)) {
    //   //       CustomAlertDialog.fromErr(t.presentError(error)).show(context);
    //   //     }
    //   //     if (next case AsyncData(value: Disconnected(:final connectionFailure?))) {
    //   //       CustomAlertDialog.fromErr(t.presentError(connectionFailure)).show(context);
    //   //     }
    //   //   },
    //   // );

    const buttonTheme = ConnectionButtonTheme.light;

    //   // return CircleDesignWidget(
    //   //   onTap: switch (connectionStatus) {
    //   //     // AsyncData(value: Disconnected()) || AsyncError() => () async {
    //   //     //     if (await showExperimentalNotice()) {
    //   //     //       return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    //   //     //     }
    //   //     //   },
    //   //     // AsyncData(value: Connected()) => () async {
    //   //     //     if (requiresReconnect == true && await showExperimentalNotice()) {
    //   //     //       return await ref.read(connectionNotifierProvider.notifier).reconnect(await ref.read(activeProfileProvider.future));
    //   //     //     }
    //   //     //     return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    //   //     //   },
    //   //     _ => () {},
    //   //   },
    //   //   // enabled: switch (connectionStatus) {
    //   //   //   AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
    //   //   //   _ => false,
    //   //   // },
    //   //   // label: switch (connectionStatus) {
    //   //   //   AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
    //   //   //   AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
    //   //   //   AsyncData(value: final status) => status.present(t),
    //   //   //   _ => "",
    //   //   // },
    //   //   color: switch (connectionStatus) {
    //   //     AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
    //   //     AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => Color.fromARGB(255, 157, 139, 1),
    //   //     AsyncData(value: Connected()) => Colors.green.shade900,
    //   //     AsyncData(value: _) => Colors.indigo.shade700, // Color(0xFF3446A5), //buttonTheme.idleColor!,
    //   //     _ => Colors.red,
    //   //   },

    //   //   animated: true ||
    //   //       switch (connectionStatus) {
    //   //         AsyncData(value: Connected()) when requiresReconnect == true => false,
    //   //         AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => false,
    //   //         AsyncData(value: Connected()) => true,
    //   //         AsyncData(value: _) => true,
    //   //         _ => false,
    //   //       },
    //   //   animationValue: animationValue,
    //   // );
    // }
    var secureLabel =
        (ref.watch(ConfigOptions.enableWarp) && ref.watch(ConfigOptions.warpDetourMode) == WarpDetourMode.warpOverProxy)
        ? t.connection.secure
        : "";
    if (delay <= 0 || delay > 65000 || connectionStatus.value != const Connected()) {
      secureLabel = "";
    }
    return _ConnectionButton(
      onTap: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => () async {
          final activeProfile = await ref.read(activeProfileProvider.future);
          return await ref.read(connectionNotifierProvider.notifier).reconnect(activeProfile);
        },
        AsyncData(value: Disconnected()) || AsyncError() => () async {
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
        },
        AsyncData(value: Connected()) => () async {
          if (requiresReconnect == true &&
              await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
            return await ref
                .read(connectionNotifierProvider.notifier)
                .reconnect(await ref.read(activeProfileProvider.future));
          }
          return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
        },
        _ => () {},
      },
      enabled: switch (connectionStatus) {
        AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
        _ => false,
      },
      label: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
        AsyncData(value: final status) => status.present(t),
        _ => "",
      },
      buttonColor: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => const Color.fromARGB(255, 185, 176, 103),
        AsyncData(value: Connected()) => buttonTheme.connectedColor!,
        AsyncData(value: _) => buttonTheme.idleColor!,
        _ => Colors.red,
      },
      image: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Assets.images.disconnectNorouz,
        AsyncData(value: Connected()) => Assets.images.connectNorouz,
        _ => Assets.images.disconnectNorouz,
      },
      newButtonColor: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => const Color.fromARGB(255, 185, 176, 103),
        AsyncData(value: Connected()) => buttonTheme.connectedColor!,
        AsyncData(value: _) => buttonTheme.idleColor!,
        _ => Colors.red,
      },
      animated: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => false,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => false,
        AsyncData(value: Connected()) => true,
        AsyncData(value: _) => true,
        _ => false,
      },
      connected: connectionStatus.value == const Connected(),
      busy: switch (connectionStatus.value) {
        Connecting() || Disconnecting() => true,
        _ => false,
      },
      useImage: today.day >= 19 && today.day <= 23 && today.month == 3,
      secureLabel: secureLabel,
    );
  }
}

class _ConnectionButton extends StatefulWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.buttonColor,
    required this.image,
    required this.useImage,
    required this.newButtonColor,
    required this.animated,
    required this.connected,
    required this.busy,
    required this.secureLabel,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final Color buttonColor;
  final AssetGenImage image;
  final bool useImage;
  final String secureLabel;

  final Color newButtonColor;

  final bool animated;
  final bool connected;
  final bool busy;

  @override
  State<_ConnectionButton> createState() => _ConnectionButtonState();
}

class _ConnectionButtonState extends State<_ConnectionButton> with TickerProviderStateMixin {
  late final AnimationController _sparkleController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 760));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
      lowerBound: .94,
      upperBound: 1.04,
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _ConnectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connected != widget.connected || oldWidget.busy != widget.busy) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (widget.connected || widget.busy) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _sparkleController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neonColor = widget.connected
        ? const Color(0xFF4DD8FF)
        : widget.busy
            ? const Color(0xFF7DBBFF)
            : theme.colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 232,
          height: 232,
          child: AnimatedBuilder(
            animation: Listenable.merge([_sparkleController, _pulseController]),
            builder: (context, child) {
              final pulse = widget.connected || widget.busy ? _pulseController.value : 1.0;

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 188,
                      height: 188,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            neonColor.withValues(alpha: 0.24),
                            neonColor.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: neonColor.withValues(alpha: widget.connected ? 0.28 : 0.18),
                            blurRadius: widget.connected ? 44 : 28,
                            spreadRadius: widget.connected ? 2 : -2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: neonColor.withValues(alpha: 0.26)),
                    ),
                  ),
                  _SparkleBurst(
                    progress: _sparkleController.value,
                    color: neonColor,
                  ),
                  Semantics(
                    button: true,
                    enabled: widget.enabled,
                    label: widget.label,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(blurRadius: 18, color: neonColor.withValues(alpha: .32)),
                        ],
                      ),
                      width: 148,
                      height: 148,
                      child: Material(
                        key: const ValueKey("home_connection_button"),
                        shape: const CircleBorder(),
                        color: Colors.white,
                        child: InkWell(
                          focusColor: Colors.grey,
                          onTap: _handleTap,
                          child: Padding(
                            padding: const EdgeInsets.all(36),
                            child: TweenAnimationBuilder(
                              tween: ColorTween(end: widget.buttonColor),
                              duration: const Duration(milliseconds: 250),
                              builder: (context, value, child) {
                                if (widget.useImage) {
                                  return widget.image.image();
                                } else {
                                  return AppLogo(colorFilter: ColorFilter.mode(value!, BlendMode.srcIn));
                                }
                              },
                            ),
                          ),
                        ),
                      ).animate(target: widget.enabled ? 0 : 1).blurXY(end: 1),
                    ).animate(target: widget.enabled ? 0 : 1).scaleXY(end: .88, curve: Curves.easeIn),
                  ),
                ],
              );
            },
          ),
        ),
        const Gap(16),
        ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedText(widget.label, style: theme.textTheme.titleMedium),
              if (widget.secureLabel.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.shieldHalved, size: 16, color: theme.colorScheme.secondary),
                    const Gap(4),
                    Text(
                      widget.secureLabel,
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SparkleBurst extends StatelessWidget {
  const _SparkleBurst({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();

    const particles = 10;
    final widgets = <Widget>[];
    for (var i = 0; i < particles; i++) {
      final angle = (math.pi * 2 / particles) * i + (i.isEven ? 0.18 : -0.12);
      final distance = 24 + (64 * Curves.easeOutCubic.transform(progress));
      final dx = math.cos(angle) * distance;
      final dy = math.sin(angle) * distance;
      final size = i.isEven ? 10.0 : 6.0;
      final opacity = (1 - progress).clamp(0.0, 1.0);

      widgets.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    color.withValues(alpha: 0.92),
                    color.withValues(alpha: 0.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.46),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: widgets,
      ),
    );
  }
}
