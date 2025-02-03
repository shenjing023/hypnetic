import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'video_provider.dart';
import 'package:flutter/foundation.dart';
import 'audio_player_provider.dart';

/// 定时器来源
enum TimerSource {
  homeScreen, // 本地音频页面
  homePage, // 轻松助眠页面
  none // 未启动
}

/// 定时器状态类
///
/// 包含定时器的当前状态信息：
/// - [duration]: 总时长
/// - [remaining]: 剩余时间
/// - [isRunning]: 是否正在运行
/// - [source]: 定时器来源
class TimerState {
  final Duration duration;
  final Duration remaining;
  final bool isRunning;
  final TimerSource source;

  const TimerState({
    required this.duration,
    required this.remaining,
    required this.isRunning,
    this.source = TimerSource.none,
  });

  /// 计算当前进度（0.0 到 1.0）
  double get progress => remaining.inSeconds / duration.inSeconds;

  /// 创建新的状态实例
  TimerState copyWith({
    Duration? duration,
    Duration? remaining,
    bool? isRunning,
    TimerSource? source,
  }) {
    return TimerState(
      duration: duration ?? this.duration,
      remaining: remaining ?? this.remaining,
      isRunning: isRunning ?? this.isRunning,
      source: source ?? this.source,
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
  return TimerNotifier(ref);
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
          source: TimerSource.none,
        ));

  /// 重置并启动定时器
  void resetAndStart(TimerSource newSource) {
    _timer?.cancel();
    final duration = state.duration.inSeconds == 0
        ? const Duration(minutes: 15)
        : state.duration;

    state = TimerState(
      duration: duration,
      remaining: duration,
      isRunning: true,
      source: newSource,
    );
    _startTimer();
  }

  /// 使用指定来源启动定时器
  void startWithSource(TimerSource source) {
    if (state.source != TimerSource.none && state.source != source) {
      return;
    }

    if (!state.isRunning && state.remaining > Duration.zero) {
      _startTimer();
      state = state.copyWith(isRunning: true, source: source);
    }
  }

  /// 启动定时器
  void start() {
    if (state.source == TimerSource.none &&
        !state.isRunning &&
        state.remaining > Duration.zero) {
      _startTimer();
      state = state.copyWith(isRunning: true);
    }
  }

  /// 暂停定时器
  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// 设置定时器时长
  void setDuration(Duration duration) {
    _timer?.cancel();
    state = TimerState(
      duration: duration,
      remaining: duration,
      isRunning: false,
      source: TimerSource.none,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final newRemaining = state.remaining - const Duration(seconds: 1);

      if (newRemaining.inSeconds <= 0) {
        timer.cancel();
        state = state.copyWith(
          remaining: Duration.zero,
          isRunning: false,
          source: TimerSource.none,
        );
        _stopAllPlayback();
      } else {
        state = state.copyWith(remaining: newRemaining);

        // 最后30秒音量渐弱
        if (newRemaining.inSeconds <= 30) {
          final volumeRatio = newRemaining.inSeconds / 30;
          Future.microtask(() {
            _ref.read(playbackStateProvider.notifier).setVolume(volumeRatio);
          });
        }
      }
    });
  }

  /// 停止所有播放并退出应用
  void _stopAllPlayback() {
    try {
      Future.microtask(() async {
        try {
          // 停止播放
          _ref.read(playbackStateProvider.notifier).setPlaying(false);
          _ref.read(currentVideoProvider.notifier).clear();
          _ref.read(streamStateProvider.notifier).clear();

          // 等待状态更新
          await Future.delayed(const Duration(milliseconds: 500));

          // 尝试多种方式退出应用
          SystemNavigator.pop(animated: true);
          await Future.delayed(const Duration(seconds: 1));
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          await Future.delayed(const Duration(seconds: 1));
          exit(0);
        } catch (e) {
          debugPrint('应用退出失败，强制退出');
          exit(0);
        }
      });
    } catch (e) {
      exit(0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
