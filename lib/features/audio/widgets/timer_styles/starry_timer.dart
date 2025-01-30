import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:math' show Random;
import 'timer_style.dart';

class StarryTimer extends TimerStyle {
  const StarryTimer({
    super.key,
    required super.timerState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B2E),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 星空动画
          _StarryAnimation(
            progress: getProgress(),
            isRunning: timerState.isRunning,
          ),
          // 时间文本
          Text(
            getTimeString(),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w300,
                ),
          ),
        ],
      ),
    );
  }
}

class _StarryAnimation extends StatefulWidget {
  final double progress;
  final bool isRunning;

  const _StarryAnimation({
    required this.progress,
    required this.isRunning,
  });

  @override
  State<_StarryAnimation> createState() => _StarryAnimationState();
}

class _StarryAnimationState extends State<_StarryAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
        return CustomPaint(
          size: const Size(280, 280),
          painter: StarryPainter(
            progress: widget.progress,
            isRunning: widget.isRunning,
            animationValue: _controller.value,
          ),
        );
      },
    );
  }
}

class StarryPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final double animationValue;
  static const int _maxStars = 100;
  final List<_Star> _stars = [];
  final Random _random = Random(42);

  StarryPainter({
    required this.progress,
    required this.isRunning,
    required this.animationValue,
  }) {
    if (_stars.isEmpty) {
      _initializeStars();
    }
  }

  void _initializeStars() {
    for (int i = 0; i < _maxStars; i++) {
      _stars.add(_Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2 + 0.5,
        blinkPhase: _random.nextDouble() * math.pi * 2,
        blinkSpeed: _random.nextDouble() * 2 + 1,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 绘制外圈
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius - 1, borderPaint);

    // 计算可见星星数量，避免除零错误
    final visibleStars =
        progress <= 0 ? _maxStars : (_maxStars * (1 - progress)).round();

    // 绘制星星
    for (int i = 0; i < visibleStars; i++) {
      final star = _stars[i];
      final x = center.dx + (star.x * 2 - 1) * (radius - 10);
      final y = center.dy + (star.y * 2 - 1) * (radius - 10);

      // 计算星星亮度
      final brightness = (math.sin(star.blinkPhase +
                  animationValue * star.blinkSpeed * math.pi * 2) +
              1) /
          2;

      // 绘制星星光晕
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(brightness * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(x, y), star.size * 2, glowPaint);

      // 绘制星星核心
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(brightness * 0.9)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), star.size * 0.5, starPaint);
    }
  }

  @override
  bool shouldRepaint(StarryPainter oldDelegate) {
    return true;
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double blinkPhase;
  final double blinkSpeed;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.blinkPhase,
    required this.blinkSpeed,
  });
}
