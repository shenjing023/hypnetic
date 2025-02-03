import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'player_interface.dart';
import '../cache/audio_cache_manager.dart';

class VideoPlayerImpl implements Player {
  late VideoPlayerController _controller;
  final _state = ValueNotifier<PlayerState>(PlayerState.idle);
  final _position = ValueNotifier<Duration>(Duration.zero);
  final _duration = ValueNotifier<Duration>(Duration.zero);
  final _bufferProgress = ValueNotifier<double>(0.0);
  final _isBuffering = ValueNotifier<bool>(false);
  final _volume = ValueNotifier<double>(1.0);
  final _playbackSpeed = ValueNotifier<double>(1.0);
  final _isLooping = ValueNotifier<bool>(false);
  final _downloadProgress = ValueNotifier<double>(0.0);

  final _eventController = StreamController<PlayerEvent>.broadcast();
  Timer? _positionTimer;
  final PlayerConfig config;
  int _retryCount = 0;
  String? _currentUrl;
  Map<String, String>? _currentHeaders;

  VideoPlayerImpl({PlayerConfig? config})
      : config = config ?? const PlayerConfig();

  @override
  ValueListenable<PlayerState> get state => _state;
  @override
  ValueListenable<Duration> get position => _position;
  @override
  ValueListenable<Duration> get duration => _duration;
  @override
  ValueListenable<double> get bufferProgress => _bufferProgress;
  @override
  ValueListenable<bool> get isBuffering => _isBuffering;
  @override
  ValueListenable<double> get volume => _volume;
  @override
  ValueListenable<double> get playbackSpeed => _playbackSpeed;
  @override
  ValueListenable<bool> get isLooping => _isLooping;
  @override
  Stream<PlayerEvent> get events => _eventController.stream;

  // 新增：下载进度监听器
  ValueListenable<double> get downloadProgress => _downloadProgress;

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(
      config.positionUpdateInterval,
      (timer) {
        if (_controller.value.isInitialized) {
          _position.value = _controller.value.position;
        }
      },
    );
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _handleError(PlayerError error, String message) {
    _state.value = PlayerState.error;
    _eventController.add(PlayerErrorEvent(error, message));

    if (_retryCount < config.maxRetries) {
      _retryCount++;
      Future.delayed(config.retryDelay, () {
        if (_currentUrl != null) {
          initialize(_currentUrl!, headers: _currentHeaders);
        }
      });
    }
  }

  void _updateState() {
    if (_controller.value.hasError) {
      _state.value = PlayerState.error;
      return;
    }

    if (!_controller.value.isInitialized) {
      _state.value = PlayerState.initializing;
      return;
    }

    if (_controller.value.isBuffering) {
      _state.value = PlayerState.buffering;
      return;
    }

    if (_controller.value.isPlaying) {
      _state.value = PlayerState.playing;
    } else {
      _state.value = PlayerState.paused;
    }
  }

  void _listener() {
    _updateState();
    _isBuffering.value = _controller.value.isBuffering;

    if (_controller.value.isInitialized) {
      _duration.value = _controller.value.duration;

      if (_controller.value.buffered.isNotEmpty) {
        final buffered = _controller.value.buffered.last.end;
        final total = _controller.value.duration;
        _bufferProgress.value = buffered.inMilliseconds / total.inMilliseconds;
      }
    }

    if (_controller.value.isPlaying) {
      if (_positionTimer == null) {
        _startPositionTimer();
      }
    } else {
      _stopPositionTimer();
    }
  }

  @override
  Future<void> initialize(String url, {Map<String, String>? headers}) async {
    _state.value = PlayerState.initializing;
    _currentUrl = url;
    _currentHeaders = headers;

    try {
      // 获取缓存文件
      final cachedFile = await AudioCacheManager.instance.getCachedFile(
        url,
        headers: headers,
      );

      // 创建新的控制器
      _controller = VideoPlayerController.file(
        File(cachedFile),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: config.allowBackgroundPlay,
        ),
      );

      await _controller.initialize();
      _controller.addListener(_listener);

      // 预加载
      await _controller.seekTo(Duration.zero);
      if (_controller.value.buffered.isEmpty) {
        await _controller.play();
        await Future.delayed(config.preloadDuration);
        await _controller.pause();
        await _controller.seekTo(Duration.zero);
      }

      _state.value = PlayerState.ready;
      _retryCount = 0;
    } catch (e) {
      if (e is TimeoutException) {
        _handleError(PlayerError.network, '连接超时');
      } else {
        _handleError(PlayerError.initialization, e.toString());
      }
    }
  }

  @override
  Future<void> play() async {
    if (_state.value == PlayerState.error) return;

    try {
      // 启用屏幕常亮
      await WakelockPlus.enable();

      await _controller.play();
      _startPositionTimer();
    } catch (e) {
      _handleError(PlayerError.playback, e.toString());
    }
  }

  @override
  Future<void> pause() async {
    if (_state.value == PlayerState.error) return;

    try {
      // 禁用屏幕常亮
      await WakelockPlus.disable();

      await _controller.pause();
      _stopPositionTimer();
    } catch (e) {
      _handleError(PlayerError.playback, e.toString());
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_state.value == PlayerState.error) return;

    try {
      _isBuffering.value = true;

      // 限制位置范围
      if (position < Duration.zero) {
        position = Duration.zero;
      }
      if (position > _controller.value.duration) {
        position = _controller.value.duration;
      }

      await _controller.seekTo(position);
      _position.value = position;

      if (_controller.value.isPlaying) {
        await play();
      }
    } catch (e) {
      _handleError(PlayerError.seeking, e.toString());
    } finally {
      _isBuffering.value = false;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0.0, 1.0);
    try {
      await _controller.setVolume(volume);
      _volume.value = volume;
    } catch (e) {
      _handleError(PlayerError.unknown, e.toString());
    }
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _controller.setPlaybackSpeed(speed);
      _playbackSpeed.value = speed;
    } catch (e) {
      _handleError(PlayerError.unknown, e.toString());
    }
  }

  @override
  Future<void> setLooping(bool looping) async {
    try {
      await _controller.setLooping(looping);
      _isLooping.value = looping;
    } catch (e) {
      _handleError(PlayerError.unknown, e.toString());
    }
  }

  @override
  Future<void> dispose() async {
    // 确保释放屏幕常亮
    await WakelockPlus.disable();

    _stopPositionTimer();
    _eventController.close();
    await _controller.dispose();

    _state.dispose();
    _position.dispose();
    _duration.dispose();
    _bufferProgress.dispose();
    _isBuffering.dispose();
    _volume.dispose();
    _playbackSpeed.dispose();
    _isLooping.dispose();
    _downloadProgress.dispose();
  }
}
