import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class AppShellBackground extends StatefulWidget {
  const AppShellBackground({
    super.key,
    required this.child,
    this.showMap = false,
  });

  final Widget child;
  final bool showMap;

  @override
  State<AppShellBackground> createState() => _AppShellBackgroundState();
}

class _AppShellBackgroundState extends State<AppShellBackground> with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  final List<_ClickNode> _clickNodes = <_ClickNode>[];
  int _nextNodeId = 0;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    final node = _ClickNode(id: _nextNodeId++, position: event.localPosition);
    setState(() {
      _clickNodes.add(node);
      if (_clickNodes.length > 5) {
        _clickNodes.removeRange(0, _clickNodes.length - 5);
      }
    });

    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _clickNodes.removeWhere((n) => n.id == node.id);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF081426), Color(0xFF09172B), Color(0xFF061121), Color(0xFF030813)]
                : const [Color(0xFFF2F7FF), Color(0xFFEAF4FF), Color(0xFFF7FAFE)],
          ),
        ),
        child: AnimatedBuilder(
          animation: _ambientController,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -110,
                  left: -90,
                  child: _GlowOrb(
                    size: 360,
                    color: const Color(0xFF2295FF).withValues(alpha: dark ? 0.22 : 0.12),
                  ),
                ),
                Positioned(
                  top: 30,
                  right: -80,
                  child: _GlowOrb(
                    size: 290,
                    color: const Color(0xFF314AA0).withValues(alpha: dark ? 0.12 : 0.08),
                  ),
                ),
                Positioned(
                  bottom: -140,
                  left: 90,
                  child: _GlowOrb(
                    size: 320,
                    color: const Color(0xFF1C88AE).withValues(alpha: dark ? 0.10 : 0.06),
                  ),
                ),
                if (widget.showMap)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: const AssetImage('assets/images/world_map.png'),
                          fit: BoxFit.cover,
                          opacity: dark ? 0.15 : 0.08,
                          colorFilter: ColorFilter.mode(
                            const Color(0xFF66C1FF).withValues(alpha: dark ? 0.20 : 0.08),
                            BlendMode.screen,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.showMap)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF2A8FFF).withValues(alpha: dark ? 0.05 : 0.04),
                              Colors.transparent,
                              const Color(0xFF040914).withValues(alpha: dark ? 0.30 : 0.04),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.showMap)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _MapPointsOverlay(
                        progress: _ambientController.value,
                        dark: dark,
                      ),
                    ),
                  ),
                widget.child,
                if (_clickNodes.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _ClickFxOverlay(
                        nodes: List<_ClickNode>.unmodifiable(_clickNodes),
                        color: const Color(0xFF2B9DFF),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class NodaPanel extends StatelessWidget {
  const NodaPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.radius = 28,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: dark ? 18 : 10, sigmaY: dark ? 18 : 10),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF102038).withValues(alpha: dark ? 0.64 : 0.76),
                const Color(0xFF0A172B).withValues(alpha: dark ? 0.56 : 0.08),
                (color ?? theme.colorScheme.surfaceContainer).withValues(alpha: dark ? 0.34 : 0.64),
              ],
            ),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: dark ? 0.28 : 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.22 : 0.08),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              if (dark)
                BoxShadow(
                  color: const Color(0xFF4DB6FF).withValues(alpha: 0.045),
                  blurRadius: 36,
                  spreadRadius: -8,
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPointsOverlay extends StatelessWidget {
  const _MapPointsOverlay({
    required this.progress,
    required this.dark,
  });

  final double progress;
  final bool dark;

  static const List<Offset> _points = [
    Offset(.14, .72),
    Offset(.19, .70),
    Offset(.27, .61),
    Offset(.33, .52),
    Offset(.37, .47),
    Offset(.42, .39),
    Offset(.47, .46),
    Offset(.52, .41),
    Offset(.55, .34),
    Offset(.59, .37),
    Offset(.63, .43),
    Offset(.68, .48),
    Offset(.73, .44),
    Offset(.78, .39),
    Offset(.84, .47),
    Offset(.88, .59),
    Offset(.61, .58),
    Offset(.57, .64),
    Offset(.51, .68),
    Offset(.44, .63),
    Offset(.34, .73),
    Offset(.70, .67),
    Offset(.76, .62),
    Offset(.81, .71),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final absolutePoints = _points
            .map((point) => Offset(constraints.maxWidth * point.dx, constraints.maxHeight * point.dy))
            .toList(growable: false);

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _NetworkLinesPainter(
                  points: absolutePoints,
                  progress: progress,
                  dark: dark,
                ),
              ),
            ),
            for (var i = 0; i < _points.length; i++)
              Positioned(
                left: absolutePoints[i].dx,
                top: absolutePoints[i].dy,
                child: _MapPoint(
                  phase: (progress + (i * .11)) % 1,
                  color: i % 4 == 0 ? const Color(0xFF85CFFF) : const Color(0xFF5FB8FF),
                  dark: dark,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NetworkLinesPainter extends CustomPainter {
  _NetworkLinesPainter({
    required this.points,
    required this.progress,
    required this.dark,
  });

  final List<Offset> points;
  final double progress;
  final bool dark;

  static const List<(int, int)> _connections = [
    (2, 3),
    (3, 4),
    (4, 6),
    (6, 7),
    (7, 9),
    (9, 10),
    (10, 12),
    (12, 13),
    (13, 14),
    (8, 9),
    (9, 11),
    (16, 17),
    (17, 18),
    (18, 19),
    (19, 20),
    (21, 22),
    (22, 23),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final wave = (math.sin(progress * math.pi * 2) + 1) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF7CCBFF).withValues(alpha: dark ? 0.04 + (wave * 0.04) : 0.02),
          const Color(0xFF2D8CFF).withValues(alpha: dark ? 0.08 + (wave * 0.06) : 0.03),
          const Color(0xFF7CCBFF).withValues(alpha: dark ? 0.02 + (wave * 0.03) : 0.015),
        ],
      ).createShader(Offset.zero & size);

    for (final (from, to) in _connections) {
      if (from >= points.length || to >= points.length) continue;
      canvas.drawLine(points[from], points[to], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkLinesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.dark != dark || oldDelegate.points != points;
  }
}

class _MapPoint extends StatelessWidget {
  const _MapPoint({
    required this.phase,
    required this.color,
    required this.dark,
  });

  final double phase;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final wave = (math.sin(phase * math.pi * 2) + 1) / 2;
    final glow = dark ? (0.10 + wave * 0.16) : (0.04 + wave * 0.06);
    final size = 4.0 + (wave * 2.4);

    return Transform.translate(
      offset: const Offset(-8, -8),
      child: SizedBox(
        width: 18,
        height: 18,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14 + (wave * 5),
              height: 14 + (wave * 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: glow),
              ),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: dark ? 0.92 : 0.72),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: dark ? 0.42 : 0.18),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClickNode {
  const _ClickNode({
    required this.id,
    required this.position,
  });

  final int id;
  final Offset position;
}

class _ClickFxOverlay extends StatelessWidget {
  const _ClickFxOverlay({
    required this.nodes,
    required this.color,
  });

  final List<_ClickNode> nodes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Stack(
            children: [
              for (var i = 0; i < nodes.length - 1; i++)
                _ClickLineEffect(
                  key: ValueKey('${nodes[i].id}-${nodes[i + 1].id}'),
                  start: nodes[i].position,
                  end: nodes[i + 1].position,
                  color: color,
                ),
            ],
          ),
        ),
        for (final node in nodes)
          _ClickCircleEffect(
            key: ValueKey(node.id),
            position: node.position,
            color: color,
          ),
      ],
    );
  }
}

class _ClickLineEffect extends StatelessWidget {
  const _ClickLineEffect({
    super.key,
    required this.start,
    required this.end,
    required this.color,
  });

  final Offset start;
  final Offset end;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return CustomPaint(
          painter: _ClickLinePainter(
            start: start,
            end: end,
            progress: value,
            color: color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ClickLinePainter extends CustomPainter {
  _ClickLinePainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.color,
  });

  final Offset start;
  final Offset end;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final currentEnd = Offset.lerp(start, end, progress) ?? end;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.6 * (1 - progress));
    canvas.drawLine(start, currentEnd, paint);
  }

  @override
  bool shouldRepaint(covariant _ClickLinePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}

class _ClickCircleEffect extends StatelessWidget {
  const _ClickCircleEffect({
    super.key,
    required this.position,
    required this.color,
  });

  final Offset position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final size = 12 * (1 + (value * 2));
        return Positioned(
          left: position.dx - (size / 2),
          top: position.dy - (size / 2),
          child: Opacity(
            opacity: 0.8 * (1 - value),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.14 * (1 - value)),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
