import 'dart:math';
import 'package:flutter/material.dart';

class InkDropLoader extends StatefulWidget {
  final double size;
  final Color color;

  const InkDropLoader({
    super.key,
    this.size = 60.0,
    this.color = const Color(0xFF007F70),
  });

  @override
  State<InkDropLoader> createState() => _InkDropLoaderState();
}

class _InkDropLoaderState extends State<InkDropLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _InkDropPainter(
              animationValue: _controller.value,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _InkDropPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _InkDropPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2.5;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // We animate three main phases for ink drops:
    // 1. Fall (drop dripping down from top)
    // 2. Splash / Merge (growing pool in the center)
    // 3. Ripple (expanding rings expanding out and fading)

    // Phase 1: Falling Droplet
    if (animationValue < 0.4) {
      final t = animationValue / 0.4; // 0 to 1
      final dropY = (size.height * 0.15) + (size.height * 0.35) * t;
      final dropRadius = 6.0 * (1.0 - t * 0.3);
      
      // Draw tail for droplet effect
      final path = Path()
        ..moveTo(center.dx - dropRadius, dropY)
        ..quadraticBezierTo(center.dx, dropY - dropRadius * 1.8, center.dx + dropRadius, dropY)
        ..arcToPoint(
          Offset(center.dx - dropRadius, dropY),
          radius: Radius.circular(dropRadius),
          clockwise: true,
        );
      canvas.drawPath(path, paint);
    }

    // Phase 2: Splashing Pool
    double poolScale = 0.0;
    if (animationValue >= 0.3 && animationValue < 0.8) {
      final t = (animationValue - 0.3) / 0.5; // 0 to 1
      poolScale = sin(t * pi); // sine curve for organic expand/retract
    }
    final poolRadius = maxRadius * 0.55 * poolScale;
    if (poolRadius > 0.1) {
      canvas.drawCircle(center, poolRadius, paint);
    }

    // Phase 3: Outward Fading Ripple Ring
    if (animationValue >= 0.5) {
      final t = (animationValue - 0.5) / 0.5; // 0 to 1
      final rippleRadius = maxRadius * 0.4 + (maxRadius * 0.6) * t;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final ripplePaint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1.0 - t * 0.5);
      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }

    // Always keep a tiny central resting point for visual continuity
    final idleOpacity = 0.25 + 0.15 * sin(animationValue * 2 * pi);
    final centerPaint = Paint()
      ..color = color.withOpacity(idleOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.0, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _InkDropPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
