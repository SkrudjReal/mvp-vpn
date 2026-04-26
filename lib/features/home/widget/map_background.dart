import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/theme/noda_theme.dart';

class MapBackground extends HookWidget {
  final bool isConnected;
  final Region selectedCountry;

  const MapBackground({
    super.key,
    required this.isConnected,
    required this.selectedCountry,
  });

  @override
  Widget build(BuildContext context) {
    // Coordinate mapping relative to viewBox 1000x500
    final offsets = {
      Region.nl: const Offset(0.508, 0.290), // x: 508, y: 145
      Region.ir: const Offset(0.65, 0.45),
      Region.ru: const Offset(0.60, 0.25),
      Region.cn: const Offset(0.80, 0.40),
      Region.id: const Offset(0.85, 0.65),
      Region.tr: const Offset(0.58, 0.40),
      Region.br: const Offset(0.35, 0.65),
      Region.af: const Offset(0.68, 0.48),
    };

    final currentCoord = offsets[selectedCountry] ?? offsets[Region.nl]!;
    final userLoc = const Offset(0.530, 0.310); // Poland x: 530, y: 155
    
    final inactiveServers = const [
      Offset(0.23, 0.34), // US East
      Offset(0.16, 0.36), // US West
      Offset(0.82, 0.40), // Japan
      Offset(0.75, 0.56), // Singapore
      Offset(0.53, 0.48), // Middle East
    ];

    // "Floating" animation for the map
    final floatController = useAnimationController(
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    
    final floatAnimX = Tween<double>(begin: 0, end: -8).animate(CurvedAnimation(parent: floatController, curve: Curves.easeInOutSine));
    final floatAnimY = Tween<double>(begin: 0, end: 6).animate(CurvedAnimation(parent: floatController, curve: Curves.easeInOutSine));
    final scaleAnim = Tween<double>(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: floatController, curve: Curves.easeInOutSine));

    return Positioned.fill(
      child: Opacity(
        opacity: Theme.of(context).brightness == Brightness.light ? 0.3 : 0.15,
        child: AnimatedBuilder(
          animation: floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(floatAnimX.value, floatAnimY.value),
              child: Transform.scale(
                scale: scaleAnim.value * 1.4, // 140% size like in React
                child: child,
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 2.0, // 1000 / 500
                  child: CustomPaint(
                    size: const Size(1000, 500),
                    painter: _MapPainter(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              Center(
                child: AspectRatio(
                  aspectRatio: 2.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cw = constraints.maxWidth;
                      final ch = constraints.maxHeight;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Inactive Servers (Global Network)
                          for (final loc in inactiveServers)
                            Positioned(
                              left: cw * loc.dx - 4,
                              top: ch * loc.dy - 4,
                              child: _PulsingDot(color: context.nodaNeon.withValues(alpha: 0.4), size: 8),
                            ),

                          // Connection Arc
                          if (isConnected)
                            Positioned.fill(
                              child: _ConnectionArc(
                                start: Offset(cw * userLoc.dx, ch * userLoc.dy),
                                end: Offset(cw * currentCoord.dx, ch * currentCoord.dy),
                                color: context.nodaNeon,
                              ),
                            ),

                          // User Location (YOU)
                          Positioned(
                            left: cw * userLoc.dx - 4,
                            top: ch * userLoc.dy - 4,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "YOU",
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Target Server Node & Radar
                          Positioned(
                            left: cw * currentCoord.dx - 30, // center 60x60
                            top: ch * currentCoord.dy - 30,
                            child: _RadarPulse(size: 60, isConnected: isConnected),
                          ),
                        ],
                      );
                    },
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

class _ConnectionArc extends HookWidget {
  final Offset start;
  final Offset end;
  final Color color;

  const _ConnectionArc({required this.start, required this.end, required this.color});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    )..forward();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ArcPainter(
            start: start,
            end: end,
            color: color,
            progress: CurvedAnimation(parent: controller, curve: Curves.easeOutQuart).value,
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double progress;

  _ArcPainter({required this.start, required this.end, required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Q control point: midpoint X, and Y slightly above the highest point
    final midX = (start.dx + end.dx) / 2;
    final midY = math.min(start.dy, end.dy) - 50; 
    path.quadraticBezierTo(midX, midY, end.dx, end.dy);

    // Render path incrementally based on progress
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final extractPath = metric.extractPath(0.0, metric.length * progress);

      // Dash path logic like in react stroke-dasharray: 6 4
      final dashPath = Path();
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      var distance = 0.0;
      
      final extMetrics = extractPath.computeMetrics().toList();
      if (extMetrics.isNotEmpty) {
        final extMetric = extMetrics.first;
        while (distance < extMetric.length) {
          dashPath.addPath(
            extMetric.extractPath(distance, distance + dashWidth),
            Offset.zero,
          );
          distance += dashWidth + dashSpace;
        }
        canvas.drawPath(dashPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.start != start || oldDelegate.end != end;
  }
}

class _PulsingDot extends HookWidget {
  final Color color;
  final double size;

  const _PulsingDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + (controller.value * 0.6),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _RadarPulse extends HookWidget {
  final double size;
  final bool isConnected;

  const _RadarPulse({required this.size, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 2, milliseconds: 500),
    );
    
    if (isConnected) {
      controller.repeat();
    } else {
      controller.stop();
      controller.value = 0.0;
    }

    final delayedController = useAnimationController(
      duration: const Duration(seconds: 2, milliseconds: 500),
    );

    useEffect(() {
      if (isConnected) {
        Future.delayed(const Duration(milliseconds: 1250), () {
          if (context.mounted && isConnected) delayedController.repeat();
        });
      } else {
        delayedController.stop();
        delayedController.value = 0.0;
      }
      return null;
    }, [isConnected]);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Delayed radar
          if (isConnected)
            AnimatedBuilder(
              animation: delayedController,
              builder: (context, child) {
                final progress = delayedController.value;
                return Transform.scale(
                  scale: 0.5 + progress * 3.5, // 0.5 to 4.0
                  child: Opacity(
                    opacity: math.max(0.0, 0.8 - progress * 0.8),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.nodaNeon, width: 1.0),
                      ),
                    ),
                  ),
                );
              },
            ),
            
          // Main radar
          if (isConnected)
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final progress = controller.value;
                return Transform.scale(
                  scale: 0.5 + progress * 3.5, // 0.5 to 4.0
                  child: Opacity(
                    opacity: math.max(0.0, 0.8 - progress * 0.8),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.nodaNeon, width: 2.0),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Inner glowing dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isConnected ? context.nodaNeon : Colors.grey.shade300,
              shape: BoxShape.circle,
              boxShadow: isConnected ? [
                BoxShadow(color: context.nodaNeon.withValues(alpha: 0.8), blurRadius: 10),
              ] : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final Color color;

  _MapPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Scale the path to fit the actual canvas size
    // Original SVG viewBox is 1000x500
    final scaleX = size.width / 1000.0;
    final scaleY = size.height / 500.0;
    
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final path = Path();
    path.moveTo(141.7, 117.1);
    path.relativeCubicTo(-1.4, -1.2, -2.3, -2.6, -2.5, -4.5);
    path.relativeCubicTo(-0.2, -1.6, -0.8, -2.5, -2.2, -3.4);
    path.relativeCubicTo(-2.4, -1.4, -3.1, -3.6, -2, -6.1);
    path.relativeCubicTo(1.5, -3.2, 0.9, -5.6, -1.5, -8);
    path.relativeCubicTo(-1.6, -1.6, -2, -3.8, -1.5, -6);
    path.relativeCubicTo(0.3, -1.6, 1.4, -2.8, 2.8, -3.4);
    path.relativeCubicTo(2.8, -1.1, 5.3, -2.8, 7.3, -5.2);
    path.relativeCubicTo(1.7, -2.1, 3.7, -2.9, 6.3, -2.6);
    path.relativeCubicTo(1.7, 0.2, 3.3, -0.5, 4.7, -1.6);
    path.relativeCubicTo(1.7, -1.3, 3.7, -1.4, 5.6, -0.3);
    path.relativeCubicTo(1.7, 1, 3.4, 0.7, 4.8, -0.7);
    path.relativeCubicTo(2, -2, 4.6, -2.6, 7.4, -2.1);
    path.relativeCubicTo(2, 0.4, 3.7, -0.1, 5.2, -1.6);
    path.relativeCubicTo(1.6, -1.6, 3.6, -2.2, 5.8, -1.8);
    path.relativeCubicTo(2.2, 0.4, 4, 0, 5.6, -1.6);
    path.relativeCubicTo(2.4, -2.5, 5.6, -3.2, 9, -2.2);
    path.relativeCubicTo(2.4, 0.7, 4.3, 0.1, 6, -1.7);
    path.relativeCubicTo(1.7, -1.8, 3.9, -2.5, 6.3, -2.1);
    path.relativeCubicTo(1.5, 0.2, 2.8, -0.2, 4, -1.2);
    path.relativeCubicTo(2.1, -1.7, 4.6, -2.1, 7.2, -1.2);
    path.relativeCubicTo(2, 0.7, 4.1, 0.5, 6, -0.7);
    path.relativeCubicTo(3.2, -1.9, 6.6, -1.8, 9.7, 0.5);
    path.relativeCubicTo(1.4, 1, 2.9, 1.1, 4.5, 0.4);
    path.relativeCubicTo(3.2, -1.4, 6.5, -1.1, 9.3, 1.3);
    path.relativeCubicTo(1.6, 1.4, 3.5, 1.8, 5.5, 1.2);
    path.relativeCubicTo(1.6, -0.5, 3.3, -0.3, 4.7, 0.8);
    path.relativeCubicTo(2.4, 1.8, 5.1, 2.1, 8, 1);
    path.relativeCubicTo(2.1, -0.8, 4.2, -0.5, 6.1, 0.8);
    path.relativeCubicTo(2, 1.3, 4.1, 1.5, 6.2, 0.4);
    path.relativeCubicTo(2, -1.1, 4.3, -1.2, 6.5, -0.2);
    path.relativeCubicTo(2.6, 1.2, 5.2, 1, 7.6, -0.7);
    path.relativeCubicTo(1.8, -1.3, 3.9, -1.5, 6, -0.6);
    path.relativeCubicTo(2.5, 1, 5.1, 0.8, 7.4, -0.8);
    path.relativeCubicTo(1.6, -1.1, 3.4, -1.3, 5.1, -0.6);
    path.relativeCubicTo(1.7, 0.7, 3.6, 0.5, 5.2, -0.5);
    path.relativeCubicTo(3.2, -2, 6.8, -2, 10, 0);
    path.relativeCubicTo(1.8, 1.1, 3.8, 1.3, 5.8, 0.4);
    path.relativeCubicTo(2.8, -1.2, 5.8, -0.9, 8.4, 1);
    path.relativeCubicTo(1.5, 1.1, 3.1, 1.4, 4.8, 0.8);
    path.relativeCubicTo(1.8, -0.7, 3.6, -0.4, 5.2, 0.7);
    path.relativeCubicTo(3.1, 2.1, 6.5, 2.1, 9.6, 0.1);
    path.relativeCubicTo(1.7, -1.1, 3.6, -1.3, 5.5, -0.5);
    path.relativeCubicTo(2.6, 1.1, 5.3, 1, 7.8, -0.6);
    path.relativeCubicTo(1.6, -1, 3.4, -1.2, 5.2, -0.4);
    path.relativeCubicTo(2.8, 1.2, 5.8, 1, 8.4, -0.8);
    path.relativeCubicTo(1.6, -1.1, 3.5, -1.4, 5.4, -0.7);
    path.relativeCubicTo(2.6, 1, 5.4, 0.8, 7.8, -0.8);
    path.relativeCubicTo(1.7, -1.1, 3.6, -1.4, 5.5, -0.7);
    path.relativeCubicTo(1.7, 0.6, 3.6, 0.5, 5.2, -0.5);
    path.relativeCubicTo(2.7, -1.7, 5.7, -1.7, 8.4, 0);
    path.relativeCubicTo(1.8, 1.1, 3.8, 1.3, 5.8, 0.4);
    path.relativeCubicTo(2, -0.9, 4.2, -0.8, 6.1, 0.3);
    path.relativeCubicTo(2.4, 1.4, 5.1, 1.4, 7.5, -0.1);
    path.relativeCubicTo(1.6, -1, 3.4, -1.2, 5.2, -0.4);
    path.relativeCubicTo(2.6, 1.1, 5.4, 1, 7.8, -0.6);
    path.relativeCubicTo(1.6, -1, 3.4, -1.3, 5.2, -0.6);
    path.relativeCubicTo(2.4, 1, 5, 0.9, 7.3, -0.5);
    path.relativeCubicTo(1.8, -1.1, 3.8, -1.3, 5.8, -0.4);
    path.relativeCubicTo(2.3, 1.1, 4.9, 1, 7.1, -0.4);
    path.relativeCubicTo(1.6, -1, 3.3, -1.3, 5.1, -0.6);
    path.relativeCubicTo(2.6, 1, 5.4, 0.9, 7.8, -0.6);
    path.relativeCubicTo(1.7, -1.1, 3.6, -1.4, 5.5, -0.7);
    path.relativeCubicTo(1.6, 0.6, 3.4, 0.5, 5, -0.4);
    path.relativeCubicTo(2.7, -1.6, 5.7, -1.6, 8.4, 0);
    path.relativeCubicTo(1.8, 1.1, 3.8, 1.3, 5.8, 0.4);
    path.relativeCubicTo(2, -0.9, 4.2, -0.8, 6.1, 0.3);
    path.relativeCubicTo(2.4, 1.4, 5.1, 1.4, 7.5, -0.1);
    path.relativeCubicTo(1.6, -1, 3.4, -1.2, 5.2, -0.4);
    path.relativeCubicTo(2.6, 1.1, 5.4, 1, 7.8, -0.6);
    path.relativeCubicTo(1.6, -1, 3.4, -1.3, 5.2, -0.6);
    path.relativeCubicTo(2.4, 1, 5, 0.9, 7.3, -0.5);
    path.relativeCubicTo(1.8, -1.1, 3.8, -1.3, 5.8, -0.4);
    path.relativeCubicTo(2.3, 1.1, 4.9, 1, 7.1, -0.4);
    path.relativeCubicTo(1.6, -1, 3.3, -1.3, 5.1, -0.6);
    path.relativeCubicTo(2.6, 1, 5.4, 0.9, 7.8, -0.6);
    path.relativeCubicTo(1.7, -1.1, 3.6, -1.4, 5.5, -0.7);
    path.relativeCubicTo(1.6, 0.6, 3.4, 0.5, 5, -0.4);
    path.relativeCubicTo(2.7, -1.6, 5.7, -1.6, 8.4, 0);
    path.relativeCubicTo(1.8, 1.1, 3.8, 1.3, 5.8, 0.4);
    path.relativeCubicTo(2, -0.9, 4.2, -0.8, 6.1, 0.3);
    path.relativeCubicTo(2.4, 1.4, 5.1, 1.4, 7.5, -0.1);
    path.relativeCubicTo(1.6, -1, 3.4, -1.2, 5.2, -0.4);
    path.relativeCubicTo(2.6, 1.1, 5.4, 1, 7.8, -0.6);
    path.relativeCubicTo(1.6, -1, 3.4, -1.3, 5.2, -0.6);
    path.moveTo(450, 150);
    path.quadraticBezierTo(480, 120, 520, 130);
    path.quadraticBezierTo(600, 160, 600, 160);
    path.quadraticBezierTo(650, 220, 650, 220);
    path.quadraticBezierTo(620, 300, 620, 300);
    path.quadraticBezierTo(550, 350, 550, 350);
    path.quadraticBezierTo(480, 300, 480, 300);
    path.quadraticBezierTo(430, 220, 430, 220);
    path.close();
    path.moveTo(430, 220);
    path.quadraticBezierTo(400, 250, 420, 320);
    path.quadraticBezierTo(460, 400, 460, 400);
    path.quadraticBezierTo(520, 380, 520, 380);
    path.quadraticBezierTo(500, 280, 500, 280);
    path.close();
    path.moveTo(200, 100);
    path.quadraticBezierTo(280, 80, 320, 150);
    path.quadraticBezierTo(280, 250, 280, 250);
    path.quadraticBezierTo(220, 200, 220, 200);
    path.quadraticBezierTo(180, 150, 180, 150);
    path.close();
    path.moveTo(220, 200);
    path.quadraticBezierTo(250, 250, 280, 350);
    path.quadraticBezierTo(250, 450, 250, 450);
    path.quadraticBezierTo(200, 350, 200, 350);
    path.close();
    path.moveTo(700, 250);
    path.quadraticBezierTo(750, 220, 800, 280);
    path.quadraticBezierTo(750, 350, 750, 350);
    path.quadraticBezierTo(680, 300, 680, 300);
    path.close();
    path.moveTo(750, 350);
    path.quadraticBezierTo(800, 350, 850, 420);
    path.quadraticBezierTo(750, 450, 750, 450);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
