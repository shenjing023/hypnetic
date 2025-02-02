import 'package:just_audio/just_audio.dart';

/// 音频加载异常
class AudioLoadException implements Exception {
  final String message;
  final String audioId;

  AudioLoadException(this.audioId, this.message);

  @override
  String toString() =>
      'AudioLoadException: Failed to load audio $audioId - $message';
}

/// 音频管理器单例类
///
/// 负责管理应用中所有的音频播放、暂停、音量控制等操作。
/// 使用单例模式确保全局只有一个音频管理实例。
///
/// 主要功能：
/// - 音频加载和资源管理
/// - 播放控制（播放/暂停）
/// - 音量控制（单个音频/全局音量）
/// - 资源释放
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final Map<String, AudioPlayer> _players = {};
  final Map<String, AudioSource> _audioSources = {};
  final Map<String, double> _volumes = {};
  String? _currentPlayingId;
  Function(String, bool)? onPlayStateChanged; // 添加状态变化回调

  /// 加载音频资源
  ///
  /// [id] 音频唯一标识符
  /// [assetPath] 音频文件路径
  /// 如果音频已加载，将跳过加载过程
  Future<void> loadAudio(String id, String assetPath) async {
    try {
      if (!_audioSources.containsKey(id)) {
        final audioSource = AudioSource.asset(assetPath);
        _audioSources[id] = audioSource;

        final player = AudioPlayer();
        await player.setAudioSource(audioSource);
        await player.setLoopMode(LoopMode.one);
        _players[id] = player;
        _volumes[id] = 1.0;

        // 使用playerStateStream监听播放状态变化
        player.playerStateStream.listen((playerState) {
          final isPlaying = playerState.playing;
          if (!isPlaying && _currentPlayingId == id) {
            _currentPlayingId = null;
          }
          // 触发状态变化回调
          onPlayStateChanged?.call(id, isPlaying);
        });

        // 额外监听播放完成事件
        player.processingStateStream.listen((state) {
          if (state == ProcessingState.completed && _currentPlayingId == id) {
            player.seek(Duration.zero); // 循环播放
            player.play();
          }
        });
      }
    } catch (e) {
      throw AudioLoadException(id, e.toString());
    }
  }

  Future<void> play(String id) async {
    try {
      final player = _players[id];
      if (player == null) return;

      // 如果当前音频已经在播放，不做任何操作
      if (_currentPlayingId == id && player.playing) {
        return;
      }

      // 停止当前正在播放的音频
      if (_currentPlayingId != null && _currentPlayingId != id) {
        final currentPlayer = _players[_currentPlayingId];
        if (currentPlayer != null) {
          await currentPlayer.pause();
          _currentPlayingId = null;
        }
      }

      // 设置当前播放ID（提前设置以确保UI响应）
      _currentPlayingId = id;

      // 确保从头开始播放
      await player.seek(Duration.zero);
      await player.play();

      // 立即触发回调
      onPlayStateChanged?.call(id, true);
    } catch (e) {
      print('播放音频失败: $e');
      _currentPlayingId = null;
      onPlayStateChanged?.call(id, false);
    }
  }

  Future<void> pause(String id) async {
    try {
      final player = _players[id];
      if (player != null && _currentPlayingId == id) {
        await player.pause();
        _currentPlayingId = null;
        // 立即触发回调
        onPlayStateChanged?.call(id, false);
      }
    } catch (e) {
      print('暂停音频失败: $e');
      _currentPlayingId = null;
      onPlayStateChanged?.call(id, false);
    }
  }

  bool isPlaying(String id) {
    final player = _players[id];
    return player != null && player.playing && _currentPlayingId == id;
  }

  Future<void> dispose() async {
    for (var player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _audioSources.clear();
    _volumes.clear();
    _currentPlayingId = null;
  }

  Future<void> setVolume(String id, double volume) async {
    try {
      final player = _players[id];
      if (player != null) {
        await player.setVolume(volume);
        _volumes[id] = volume;
      }
    } catch (e) {
      print('设置音量失败: $e');
    }
  }

  Future<void> setGlobalVolume(double volume) async {
    try {
      for (var entry in _players.entries) {
        if (entry.key == _currentPlayingId) {
          await entry.value.setVolume(_volumes[entry.key]! * volume);
        }
      }
    } catch (e) {
      print('设置全局音量失败: $e');
    }
  }

  double getVolume(String id) {
    return _volumes[id] ?? 1.0;
  }

  /// 获取音频播放器实例
  ///
  /// 用于扩展功能时可以直接访问播放器实例
  /// [id] 音频唯一标识符
  AudioPlayer? getPlayer(String id) => _players[id];

  /// 批量设置音频音量
  ///
  /// [volumeMap] 音频ID到音量的映射
  Future<void> setBatchVolumes(Map<String, double> volumeMap) async {
    for (var entry in volumeMap.entries) {
      await setVolume(entry.key, entry.value);
    }
  }

  /// 获取所有正在播放的音频ID
  List<String> getPlayingAudioIds() {
    return _players.entries
        .where((entry) => entry.value.playing)
        .map((entry) => entry.key)
        .toList();
  }

  /// 设置播放状态变化回调
  void setPlayStateCallback(Function(String, bool)? callback) {
    onPlayStateChanged = callback;
  }
}
