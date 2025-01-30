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

        // 为每个音频创建一个播放器
        final player = AudioPlayer();
        await player.setAudioSource(audioSource);
        await player.setLoopMode(LoopMode.one);
        _players[id] = player;
        _volumes[id] = 1.0;
      }
    } catch (e) {
      throw AudioLoadException(id, e.toString());
    }
  }

  Future<void> play(String id) async {
    try {
      final player = _players[id];
      if (player != null) {
        await player.play();
      }
    } catch (e) {
      print('播放音频失败: $e');
      rethrow;
    }
  }

  Future<void> pause(String id) async {
    try {
      final player = _players[id];
      if (player != null) {
        await player.pause();
      }
    } catch (e) {
      print('暂停音频失败: $e');
      rethrow;
    }
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
      rethrow;
    }
  }

  Future<void> setGlobalVolume(double volume) async {
    try {
      for (var entry in _players.entries) {
        final id = entry.key;
        final player = entry.value;
        if (player.playing) {
          await player.setVolume(_volumes[id]! * volume);
        }
      }
    } catch (e) {
      print('设置全局音量失败: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    for (var player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _audioSources.clear();
    _volumes.clear();
  }

  bool isPlaying(String id) {
    final player = _players[id];
    return player?.playing ?? false;
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

  /// 停止所有音频播放
  Future<void> stopAll() async {
    for (var player in _players.values) {
      await player.stop();
    }
  }
}
