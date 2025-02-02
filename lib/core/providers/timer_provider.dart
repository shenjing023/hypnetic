import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'video_provider.dart';

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
  final notifier = TimerNotifier(ref);

  // // 监听声音和视频的播放状态
  // ref.listen<({bool isPlaying, Duration position, Duration duration})>(
  //     playbackStateProvider, (previous, next) {
  //   if (next.isPlaying) {
  //     // 如果视频开始播放，且当前定时器不是来自HomePage
  //     if (notifier.state.source != TimerSource.homePage) {
  //       // 停止所有声音
  //       final sounds = ref.read(soundProvider);
  //       for (var sound in sounds.where((s) => s.isPlaying)) {
  //         ref.read(soundProvider.notifier).toggleSound(sound.id);
  //       }
  //       // 重置定时器并设置新来源
  //       notifier.resetAndStart(TimerSource.homePage);
  //     }
  //   } else {
  //     // 视频停止时，只有当定时器来源是HomePage时才暂停
  //     if (notifier.state.source == TimerSource.homePage) {
  //       notifier.pause();
  //     }
  //   }
  // });

  // ref.listen<List<SoundModel>>(soundProvider, (previous, next) {
  //   final soundPlaying = next.any((s) => s.isPlaying);
  //   if (soundPlaying) {
  //     // 如果有声音在播放，且当前定时器不是来自HomeScreen
  //     if (notifier.state.source != TimerSource.homeScreen) {
  //       // 停止视频播放
  //       if (ref.read(playbackStateProvider).isPlaying) {
  //         ref.read(playbackStateProvider.notifier).setPlaying(false);
  //         ref.read(currentVideoProvider.notifier).clear();
  //         ref.read(streamStateProvider.notifier).clear();
  //       }
  //       // 重置定时器并设置新来源
  //       notifier.resetAndStart(TimerSource.homeScreen);
  //     }
  //   } else {
  //     // 声音停止时，只有当定时器来源是HomeScreen时才暂停
  //     if (notifier.state.source == TimerSource.homeScreen) {
  //       notifier.pause();
  //     }
  //   }
  // });

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
          source: TimerSource.none,
        ));

  void resetAndStart(TimerSource newSource) {
    // 停止当前定时器
    _timer?.cancel();

    // 如果定时器时长为0，设置默认15分钟
    final duration = state.duration.inSeconds == 0
        ? const Duration(minutes: 15)
        : state.duration;

    // 重置状态并启动
    state = TimerState(
      duration: duration,
      remaining: duration,
      isRunning: true,
      source: newSource,
    );
    // _startTimer();
  }

  void startWithSource(TimerSource source) {
    // 如果来源不同，不要启动新的定时器
    if (state.source != TimerSource.none && state.source != source) {
      return;
    }

    if (!state.isRunning && state.remaining > Duration.zero) {
      // _startTimer();
      state = state.copyWith(isRunning: true, source: source);
    }
  }

  void start() {
    // 只有当定时器没有特定来源时才允许启动
    if (state.source == TimerSource.none &&
        !state.isRunning &&
        state.remaining > Duration.zero) {
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
      final newRemaining = state.remaining - const Duration(seconds: 1);

      if (newRemaining.inSeconds <= 0) {
        timer.cancel();
        state = state.copyWith(
          remaining: Duration.zero,
          isRunning: false,
          source: TimerSource.none,
        );
        // 停止所有播放
        _stopAllPlayback();
      } else {
        state = state.copyWith(remaining: newRemaining);

        // 当剩余时间小于等于30秒时，开始音量渐弱
        // if (newRemaining.inSeconds <= 30) {
        //   final volumeRatio = newRemaining.inSeconds / 30;
        //   _ref.read(soundProvider.notifier).setGlobalVolume(volumeRatio);
        // }
      }
    });
  }

  void _stopAllPlayback() {
    // 停止视频播放
    _ref.read(playbackStateProvider.notifier).setPlaying(false);
    _ref.read(currentVideoProvider.notifier).clear();
    _ref.read(streamStateProvider.notifier).clear();

    // 停止声音播放
    // final sounds = _ref.read(soundProvider);
    // for (var sound in sounds) {
    //   if (sound.isPlaying) {
    //     _ref.read(soundProvider.notifier).toggleSound(sound.id);
    //   }
    // }

    // 退出应用
    SystemNavigator.pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
