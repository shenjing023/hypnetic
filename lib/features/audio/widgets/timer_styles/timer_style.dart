import 'package:flutter/material.dart';
import '../../../../core/providers/timer_provider.dart';

/// 定时器样式枚举
enum TimerStyleType {
  circle('圆形'),
  wave('波浪'),
  starry('星空');

  final String label;
  const TimerStyleType(this.label);
}

/// 定时器样式基类
abstract class TimerStyle extends StatelessWidget {
  final TimerState timerState;

  const TimerStyle({
    super.key,
    required this.timerState,
  });

  /// 获取剩余时间的格式化字符串
  String getTimeString() {
    final hours = timerState.remaining.inHours;
    final minutes = timerState.remaining.inMinutes % 60;
    final seconds = timerState.remaining.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// 获取进度值（0.0 到 1.0）
  double getProgress() {
    return timerState.remaining.inSeconds / timerState.duration.inSeconds;
  }
}
