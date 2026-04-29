import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/theme/noda_theme.dart';

class MapBackground extends HookWidget {
  const MapBackground({super.key, required this.isConnected, required this.selectedCountry});

  final bool isConnected;
  final Region selectedCountry;

  @override
  Widget build(BuildContext context) {
    final floatController = useAnimationController(duration: const Duration(seconds: 18))..repeat(reverse: true);
    final arcController = useAnimationController(duration: const Duration(milliseconds: 1300));
    final radarController = useAnimationController(duration: const Duration(milliseconds: 2200));
    final flowController = useAnimationController(duration: const Duration(milliseconds: 2400))..repeat();

    useEffect(() {
      if (isConnected) {
        arcController.forward(from: 0);
        radarController.repeat();
      } else {
        arcController.value = 0;
        radarController.stop();
      }
      return null;
    }, [isConnected, selectedCountry]);

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.nodaBg,
          gradient: context.isDark
              ? const RadialGradient(
                  center: Alignment(0.1, -0.08),
                  radius: 1.05,
                  colors: [Color(0xFF111A28), Color(0xFF080C13)],
                )
              : const RadialGradient(
                  center: Alignment(0.1, -0.08),
                  radius: 1.05,
                  colors: [Color(0xFFFFFFFF), Color(0xFFF4F5F7)],
                ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(.05, -.10),
                    radius: .85,
                    colors: [
                      context.isDark ? context.nodaNeon.withValues(alpha: .10) : Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0, .74],
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([floatController, arcController, radarController, flowController]),
                builder: (context, _) {
                  final float = math.sin(floatController.value * math.pi * 2);

                  return Transform.translate(
                    offset: Offset(-4 * float, 3 * float),
                    child: Transform.scale(
                      scale: 1.10 + (0.018 * ((float + 1) / 2)),
                      child: AspectRatio(
                        aspectRatio: 1024 / 614,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              context.isDark ? 'assets/images/world_map_dark.jpg' : 'assets/images/world_map_light.png',
                              fit: BoxFit.cover,
                              opacity: AlwaysStoppedAnimation(context.isDark ? .72 : .45),
                              filterQuality: FilterQuality.high,
                            ),
                            CustomPaint(
                              painter: _NetworkMapPainter(
                                selectedCountry: selectedCountry,
                                isConnected: isConnected,
                                arcProgress: Curves.easeOutQuart.transform(arcController.value),
                                radarProgress: radarController.value,
                                flowProgress: flowController.value,
                                accent: context.nodaNeon,
                                textColor: context.nodaText,
                                bgColor: context.nodaBg,
                                isDark: context.isDark,
                              ),
                            ),
                          ],
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
}

class _NetworkMapPainter extends CustomPainter {
  _NetworkMapPainter({
    required this.selectedCountry,
    required this.isConnected,
    required this.arcProgress,
    required this.radarProgress,
    required this.flowProgress,
    required this.accent,
    required this.textColor,
    required this.bgColor,
    required this.isDark,
  });

  final Region selectedCountry;
  final bool isConnected;
  final double arcProgress;
  final double radarProgress;
  final double flowProgress;
  final Color accent;
  final Color textColor;
  final Color bgColor;
  final bool isDark;

  static const _servers = {
    Region.fi: Offset(0.548, 0.214),
  };

  static const _userLoc = Offset(0.250, 0.402);

  @override
  void paint(Canvas canvas, Size size) {
    final target = _scale(_servers[selectedCountry] ?? _servers[Region.fi]!, size);
    final user = _scale(_userLoc, size);

    _drawTexture(canvas, size);

    for (final entry in _servers.entries) {
      final isTarget = entry.key == selectedCountry;
      _drawServer(canvas, _scale(entry.value, size), isTarget);
    }

    if (isConnected && arcProgress > 0) {
      _drawArc(canvas, user, target);
      _drawRadar(canvas, target, radarProgress);
      _drawRadar(canvas, target, (radarProgress + .5) % 1);
    }

    _drawUser(canvas, user);
    _drawTarget(canvas, target);
    _drawVignette(canvas, Offset.zero & size);
  }

  void _drawTexture(Canvas canvas, Size size) {
    final paint = Paint();
    const step = 34.0;

    for (var y = 10.0; y < size.height; y += step) {
      for (var x = 10.0; x < size.width; x += step) {
        final wave = (math.sin((x * .018) + (y * .013)) + 1) / 2;
        paint.color = textColor.withValues(alpha: (isDark ? .018 : .026) + wave * (isDark ? .026 : .030));
        canvas.drawCircle(Offset(x, y), 1.0 + wave * .35, paint);
      }
    }
  }

  void _drawArc(Canvas canvas, Offset user, Offset target) {
    final control = Offset((user.dx + target.dx) / 2, math.min(user.dy, target.dy) - 86);
    final path = Path()
      ..moveTo(user.dx, user.dy)
      ..quadraticBezierTo(control.dx, control.dy, target.dx, target.dy);
    final metric = path.computeMetrics().first;
    final limit = metric.length * arcProgress;
    final visible = metric.extractPath(0, limit);

    canvas.drawPath(
      visible,
      Paint()
        ..color = accent.withValues(alpha: isDark ? .45 : .26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    final paint = Paint()
      ..color = accent.withValues(alpha: .95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    const dash = 8.0;
    const gap = 9.0;
    for (var distance = 0.0; distance < limit; distance += dash + gap) {
      canvas.drawPath(metric.extractPath(distance, math.min(distance + dash, limit)), paint);
    }

    if (limit > 20) {
      final tangent = metric.getTangentForOffset(limit * flowProgress);
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          6.5,
          Paint()
            ..color = accent.withValues(alpha: isDark ? .65 : .42)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
        canvas.drawCircle(tangent.position, 2.8, Paint()..color = Colors.white);
      }
    }
  }

  void _drawServer(Canvas canvas, Offset center, bool selected) {
    final opacity = selected ? .85 : .35;
    final glowSize = selected ? 22.0 : 14.0;
    
    // Outer glow
    canvas.drawCircle(
      center, 
      glowSize, 
      Paint()
        ..color = accent.withValues(alpha: opacity * .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    
    // Core dot
    canvas.drawCircle(
      center,
      selected ? 5.0 : 3.2,
      Paint()
        ..color = accent.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    
    canvas.drawCircle(center, 1.6, Paint()..color = Colors.white.withValues(alpha: isDark ? .85 : 1.0));
  }

  void _drawUser(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 22, Paint()..color = accent.withValues(alpha: isConnected ? .16 : .09));
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = accent.withValues(alpha: isConnected ? .95 : .46)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, 4, Paint()..color = isDark ? Colors.white : textColor);

    final label = Rect.fromCenter(center: center.translate(0, -29), width: 42, height: 18);
    final rrect = RRect.fromRectAndRadius(label, const Radius.circular(9));
    canvas.drawRRect(rrect, Paint()..color = isDark ? const Color(0xFF0A1018) : Colors.white.withValues(alpha: .92));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withValues(alpha: .62)
        ..style = PaintingStyle.stroke,
    );
    _drawText(canvas, 'YOU', center.translate(0, -30), 8, FontWeight.w900, textColor);
  }

  void _drawTarget(Canvas canvas, Offset target) {
    canvas.drawCircle(
      target,
      isConnected ? 8 : 5,
      Paint()
        ..color = accent.withValues(alpha: isConnected ? 1 : .52)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isConnected ? 8 : 4),
    );
    canvas.drawCircle(target, 2.6, Paint()..color = Colors.white);
  }

  void _drawRadar(Canvas canvas, Offset center, double progress) {
    final opacity = (.72 - progress * .72).clamp(0.0, .72);
    final radius = 24 + progress * 66;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accent.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3 - progress
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            isDark ? bgColor.withValues(alpha: .56) : Colors.transparent,
          ],
          stops: const [.48, 1],
        ).createShader(rect),
    );
  }

  void _drawText(Canvas canvas, String text, Offset center, double size, FontWeight weight, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, fontWeight: weight, letterSpacing: 1.2, color: color),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  Offset _scale(Offset unit, Size size) => Offset(unit.dx * size.width, unit.dy * size.height);

  @override
  bool shouldRepaint(covariant _NetworkMapPainter oldDelegate) {
    return oldDelegate.selectedCountry != selectedCountry ||
        oldDelegate.isConnected != isConnected ||
        oldDelegate.arcProgress != arcProgress ||
        oldDelegate.radarProgress != radarProgress ||
        oldDelegate.flowProgress != flowProgress ||
        oldDelegate.accent != accent ||
        oldDelegate.textColor != textColor ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.isDark != isDark;
  }
}
