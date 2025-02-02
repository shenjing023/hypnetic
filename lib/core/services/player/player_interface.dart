import 'package:flutter/foundation.dart';

/// 播放器状态
enum PlayerState {
  idle,
  initializing,
  ready,
  playing,
  paused,
  buffering,
  error,
}

/// 播放器错误类型
enum PlayerError {
  initialization('初始化失败'),
  playback('播放失败'),
  seeking('跳转失败'),
  network('网络错误'),
  unknown('未知错误');

  final String message;
  const PlayerError(this.message);
}

/// 播放器配置
class PlayerConfig {
  final Duration positionUpdateInterval;
  final Duration preloadDuration;
  final int maxRetries;
  final Duration retryDelay;
  final bool allowBackgroundPlay;

  const PlayerConfig({
    this.positionUpdateInterval = const Duration(milliseconds: 50),
    this.preloadDuration = const Duration(milliseconds: 200),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.allowBackgroundPlay = true,
  });
}

/// 播放器事件
abstract class PlayerEvent {}

class PlayerErrorEvent extends PlayerEvent {
  final PlayerError error;
  final String message;

  PlayerErrorEvent(this.error, this.message);
}

/// 播放器接口
abstract class Player {
  /// 状态相关
  ValueListenable<PlayerState> get state;
  ValueListenable<Duration> get position;
  ValueListenable<Duration> get duration;
  ValueListenable<double> get bufferProgress;
  ValueListenable<bool> get isBuffering;
  ValueListenable<double> get volume;
  ValueListenable<double> get playbackSpeed;
  ValueListenable<bool> get isLooping;
  Stream<PlayerEvent> get events;

  /// 控制方法
  Future<void> initialize(String url, {Map<String, String>? headers});
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setPlaybackSpeed(double speed);
  Future<void> setLooping(bool looping);

  /// 资源释放
  Future<void> dispose();
}
