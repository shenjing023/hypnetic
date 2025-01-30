import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'timer_style.dart';

class CircleTimer extends TimerStyle {
  const CircleTimer({
    super.key,
    required super.timerState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFD4C3C3), // 更暗的背景色
        boxShadow: [
          // 外阴影（凸起效果）
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            offset: const Offset(-15, -15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
          // 内阴影（凹陷效果）
          BoxShadow(
            color: const Color(0xFF9E8E8E).withOpacity(0.7),
            offset: const Offset(15, 15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 进度环
          CustomPaint(
            size: const Size(280, 280),
            painter: CircleProgressPainter(
              progress: getProgress(),
              color: const Color(0xFF8A7575),
              isRunning: timerState.isRunning,
            ),
          ),
          // 内部凹陷圆
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4C3C3),
              boxShadow: [
                // 内部凹陷效果
                BoxShadow(
                  color: const Color(0xFF9E8E8E).withOpacity(0.5),
                  offset: const Offset(-8, -8),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  offset: const Offset(8, 8),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // 时间文本
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getTimeString(),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: const Color(0xFF665959),
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

class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isRunning;
  static double _phase = 0.0;

  CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.isRunning,
  }) {
    if (isRunning) {
      _phase += 0.05;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30; // 调整进度条位置
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 绘制背景轨道
    final trackPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(center, radius, trackPaint);

    // 绘制进度
    final progressPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // 计算进度角度
    final progressAngle = 2 * math.pi * progress;
    final startAngle = -math.pi / 2;

    // 绘制进度弧
    canvas.drawArc(rect, startAngle, progressAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isRunning != isRunning;
  }
}
