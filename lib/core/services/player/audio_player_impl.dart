import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'player_interface.dart';
import '../cache/audio_cache_manager.dart';

class AudioPlayerImpl implements Player {
  late just_audio.AudioPlayer _player;
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
  final PlayerConfig config;
  int _retryCount = 0;
  String? _currentUrl;
  Map<String, String>? _currentHeaders;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _bufferingSubscription;

  AudioPlayerImpl({PlayerConfig? config})
      : config = config ?? const PlayerConfig() {
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _player = just_audio.AudioPlayer();

    // 配置音频会话
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    // 设置监听器
    _positionSubscription = _player.positionStream.listen((position) {
      _position.value = position;
    });

    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      _isBuffering.value =
          playerState.processingState == just_audio.ProcessingState.buffering;
      _updateState(playerState);
    });

    _bufferingSubscription = _player.bufferedPositionStream.listen((buffered) {
      if (_player.duration != null) {
        _bufferProgress.value =
            buffered.inMilliseconds / _player.duration!.inMilliseconds;
      }
    });
  }

  void _updateState(just_audio.PlayerState playerState) {
    switch (playerState.processingState) {
      case just_audio.ProcessingState.idle:
        _state.value = PlayerState.idle;
        break;
      case just_audio.ProcessingState.loading:
        _state.value = PlayerState.initializing;
        break;
      case just_audio.ProcessingState.buffering:
        _state.value = PlayerState.buffering;
        break;
      case just_audio.ProcessingState.ready:
        _state.value =
            playerState.playing ? PlayerState.playing : PlayerState.paused;
        break;
      case just_audio.ProcessingState.completed:
        _state.value = PlayerState.paused;
        break;
    }
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

      // 设置音频源
      await _player.setAudioSource(
        just_audio.AudioSource.file(
          cachedFile,
          tag: MediaItem(
            id: url,
            album: "白噪音",
            title: "放松音乐",
            artUri: Uri.parse("asset:///assets/images/default_cover.jpg"),
          ),
        ),
        preload: true,
      );

      _duration.value = _player.duration ?? Duration.zero;
      _state.value = PlayerState.ready;
      _retryCount = 0;
    } catch (e) {
      _handleError(PlayerError.initialization, e.toString());
    }
  }

  @override
  Future<void> play() async {
    if (_state.value == PlayerState.error) return;

    try {
      await _player.play();
    } catch (e) {
      _handleError(PlayerError.playback, e.toString());
    }
  }

  @override
  Future<void> pause() async {
    if (_state.value == PlayerState.error) return;

    try {
      await _player.pause();
    } catch (e) {
      _handleError(PlayerError.playback, e.toString());
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_state.value == PlayerState.error) return;

    try {
      await _player.seek(position);
      _position.value = position;
    } catch (e) {
      _handleError(PlayerError.seeking, e.toString());
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0.0, 1.0);
    try {
      await _player.setVolume(volume);
      _volume.value = volume;
    } catch (e) {
      _handleError(PlayerError.unknown, e.toString());
    }
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
      _playbackSpeed.value = speed;
    } catch (e) {
      _handleError(PlayerError.unknown, e.toString());
    }
  }

  @override
  Future<void> setLooping(bool looping) async {
    try {
      await _player.setLoopMode(
          looping ? just_audio.LoopMode.one : just_audio.LoopMode.off);
      _isLooping.value = looping;
    } catch (e) {
      _handleError(PlayerError.unknown, e.toString());
    }
  }

  @override
  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _bufferingSubscription?.cancel();
    await _player.dispose();
    await _eventController.close();

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
  ValueListenable<double> get downloadProgress => _downloadProgress;
}
