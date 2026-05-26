import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PixelSparkle extends StatefulWidget {
  const PixelSparkle({super.key});

  @override
  State<PixelSparkle> createState() => _PixelSparkleState();
}

class _PixelSparkleState extends State<PixelSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _sparkles = [
    _Sparkle(0.09, 0.13, 4, 0.0),
    _Sparkle(0.88, 0.12, 3, 0.2),
    _Sparkle(0.72, 0.24, 5, 0.45),
    _Sparkle(0.16, 0.34, 3, 0.65),
    _Sparkle(0.91, 0.43, 4, 0.85),
    _Sparkle(0.08, 0.72, 5, 0.25),
    _Sparkle(0.76, 0.78, 3, 0.55),
    _Sparkle(0.48, 0.88, 4, 0.75),
    _Sparkle(0.31, 0.18, 2, 0.35),
    _Sparkle(0.57, 0.07, 3, 0.95),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _PixelSparklePainter(_controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _PixelSparklePainter extends CustomPainter {
  const _PixelSparklePainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    for (final sparkle in _PixelSparkleState._sparkles) {
      final phase = ((value + sparkle.phase) % 1.0);
      final opacity = 0.18 + (phase < 0.5 ? phase : 1 - phase) * 0.72;
      final x = size.width * sparkle.x;
      final y = size.height * sparkle.y;
      final paint = Paint()
        ..color = (sparkle.phase > 0.5 ? softPink : neonPink).withValues(
          alpha: opacity,
        )
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y),
          width: sparkle.size,
          height: sparkle.size,
        ),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y - sparkle.size * 1.7),
          width: sparkle.size * 0.72,
          height: sparkle.size * 0.72,
        ),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + sparkle.size * 1.7, y),
          width: sparkle.size * 0.72,
          height: sparkle.size * 0.72,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PixelSparklePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _Sparkle {
  const _Sparkle(this.x, this.y, this.size, this.phase);

  final double x;
  final double y;
  final double size;
  final double phase;
}
