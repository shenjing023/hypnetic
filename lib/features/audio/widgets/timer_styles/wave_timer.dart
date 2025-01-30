import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'timer_style.dart';

class WaveTimer extends TimerStyle {
  const WaveTimer({
    super.key,
    required super.timerState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 波浪动画
          _WaveAnimation(
            progress: getProgress(),
            color: Theme.of(context).colorScheme.primary,
            isRunning: timerState.isRunning,
          ),
          // 时间文本
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getTimeString(),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w300,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaveAnimation extends StatefulWidget {
  final double progress;
  final Color color;
  final bool isRunning;

  const _WaveAnimation({
    required this.progress,
    required this.color,
    required this.isRunning,
  });

  @override
  State<_WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<_WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
          size: const Size(260, 260),
          painter: WavePainter(
            progress: widget.progress,
            color: widget.color,
            isRunning: widget.isRunning,
            animationValue: _controller.value,
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isRunning;
  final double animationValue;
  static const double _waveCount = 3;
  static const double _amplitude = 6.0;

  WavePainter({
    required this.progress,
    required this.color,
    required this.isRunning,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final wavePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 绘制外部圆形
    canvas.drawCircle(center, radius - 2, paint);

    // 计算波浪高度
    final waveTop = center.dy + radius - (2 * radius * progress);

    // 创建波浪路径
    final wavePath = Path();
    wavePath.moveTo(center.dx - radius, waveTop);

    // 使用动画值控制波浪
    final time = animationValue * 2 * math.pi;

    // 绘制波浪
    for (double x = -radius; x <= radius; x += 1) {
      final relativeX = x / radius;
      final normalizedX = relativeX * math.pi * _waveCount;

      // 主波浪
      final mainWave = math.sin(normalizedX + time) * _amplitude;
      // 次波浪
      final secondaryWave =
          math.sin(normalizedX * 1.5 - time * 1.2) * (_amplitude * 0.4);

      final y = (mainWave + secondaryWave) * (isRunning ? 1.0 : 0.3);

      wavePath.lineTo(
        center.dx + x,
        waveTop + y,
      );
    }

    wavePath.lineTo(center.dx + radius, size.height);
    wavePath.lineTo(center.dx - radius, size.height);
    wavePath.close();

    // 创建圆形裁剪区域
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - 2));

    canvas.save();
    canvas.clipPath(clipPath);
    canvas.drawPath(wavePath, wavePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return true;
  }
}
