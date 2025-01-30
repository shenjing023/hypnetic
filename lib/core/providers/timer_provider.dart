import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound_model.dart';
import 'sound_provider.dart';
import 'fade_out_provider.dart';

/// 定时器状态类
///
/// 包含定时器的当前状态信息：
/// - [duration]: 总时长
/// - [remaining]: 剩余时间
/// - [isRunning]: 是否正在运行
class TimerState {
  final Duration duration;
  final Duration remaining;
  final bool isRunning;

  const TimerState({
    required this.duration,
    required this.remaining,
    required this.isRunning,
  });

  /// 计算当前进度（0.0 到 1.0）
  double get progress => remaining.inSeconds / duration.inSeconds;

  /// 创建新的状态实例
  TimerState copyWith({
    Duration? duration,
    Duration? remaining,
    bool? isRunning,
  }) {
    return TimerState(
      duration: duration ?? this.duration,
      remaining: remaining ?? this.remaining,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

/// 音频淡出控制器
///
/// 处理音频的渐变淡出效果
class FadeOutController {
  Timer? _timer;
  double _volume = 1.0;
  final void Function(double) onVolumeChanged;
  final void Function() onComplete;

  FadeOutController({
    required this.onVolumeChanged,
    required this.onComplete,
  });

  void startFadeOut({Duration duration = const Duration(seconds: 30)}) {
    _volume = 1.0;
    const fadeOutInterval = Duration(milliseconds: 100);
    final steps = duration.inMilliseconds ~/ fadeOutInterval.inMilliseconds;
    final volumeDecrement = 1.0 / steps;

    _timer = Timer.periodic(fadeOutInterval, (timer) {
      if (_volume > 0) {
        _volume = (_volume - volumeDecrement).clamp(0.0, 1.0);
        onVolumeChanged(_volume);
      } else {
        stop();
        onComplete();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }

  void setVolume(double ratio) {
    _volume = ratio.clamp(0.0, 1.0);
  }
}

/// 全局定时器提供者
///
/// 监听音频状态变化，自动控制定时器的启动和暂停
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final notifier = TimerNotifier(ref);

  ref.listen<List<SoundModel>>(soundProvider, (previous, next) {
    final wasPlaying = previous?.any((s) => s.isPlaying) ?? false;
    final isPlaying = next.any((s) => s.isPlaying);

    if (wasPlaying != isPlaying) {
      if (isPlaying) {
        notifier.start();
      } else {
        notifier.pause();
      }
    }
  });

  return notifier;
});

/// 定时器状态管理器
class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;
  final Ref _ref;

  TimerNotifier(this._ref)
      : super(const TimerState(
          duration: Duration(minutes: 15),
          remaining: Duration(minutes: 15),
          isRunning: false,
        ));

  void start() {
    if (!state.isRunning && state.remaining > Duration.zero) {
      _startTimer();
      state = state.copyWith(isRunning: true);
    }
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void setDuration(Duration duration) {
    _timer?.cancel();
    // 重置音量
    _ref.read(soundProvider.notifier).setGlobalVolume(1.0);
    state = TimerState(
      duration: duration,
      remaining: duration,
      isRunning: false,
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemaining = state.remaining - const Duration(seconds: 1);

      // 当剩余时间小于等于30秒时，开始音量渐弱
      if (newRemaining.inSeconds <= 30) {
        final volumeRatio = newRemaining.inSeconds / 30;
        _ref.read(soundProvider.notifier).setGlobalVolume(volumeRatio);
      }

      if (newRemaining.inSeconds <= 0) {
        timer.cancel();
        state = state.copyWith(
          remaining: Duration.zero,
          isRunning: false,
        );
      } else {
        state = state.copyWith(
          remaining: newRemaining,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
