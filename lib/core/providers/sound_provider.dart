import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound_model.dart';
import '../models/audio_manager.dart';
import '../services/sound_config_service.dart';

final soundProvider =
    StateNotifierProvider<SoundNotifier, List<SoundModel>>((ref) {
  return SoundNotifier();
});

class SoundNotifier extends StateNotifier<List<SoundModel>> {
  SoundNotifier() : super([]);

  Future<void> initializeSounds() async {
    try {
      final configService = SoundConfigService();
      await configService.loadSoundConfig();
      final sounds = configService.sounds;

      for (var sound in sounds) {
        await sound.loadAudio();
      }

      state = sounds;
    } catch (e) {
      print('音频初始化错误: $e');
    }
  }

  Future<void> toggleSound(String id) async {
    try {
      final audioManager = AudioManager();
      final sound = state.firstWhere((s) => s.id == id);
      final isPlaying = sound.isPlaying;

      // 如果要播放新的声音，先停止其他正在播放的声音
      if (!isPlaying) {
        final playingSound = state.where((s) => s.isPlaying).firstOrNull;
        if (playingSound != null) {
          await audioManager.pause(playingSound.id);
        }
      }

      // 更新所有声音的状态
      state = [
        for (final s in state)
          if (s.id == id)
            SoundModel(
              id: s.id,
              type: s.type,
              assetPath: s.assetPath,
              isPlaying: !isPlaying,
            )
          else if (s.isPlaying) // 确保其他声音都停止
            SoundModel(
              id: s.id,
              type: s.type,
              assetPath: s.assetPath,
              isPlaying: false,
            )
          else
            s
      ];

      // 执行音频操作
      if (!isPlaying) {
        await audioManager.play(id);
      } else {
        await audioManager.pause(id);
      }
    } catch (e) {
      print('播放出错: $e');
      // 如果出错，恢复原始状态
      state = [
        for (final s in state)
          if (s.id == id)
            SoundModel(
              id: s.id,
              type: s.type,
              assetPath: s.assetPath,
              isPlaying: AudioManager().isPlaying(id),
            )
          else
            s
      ];
    }
  }

  Future<void> setGlobalVolume(double volume) async {
    try {
      await AudioManager().setGlobalVolume(volume);
    } catch (e) {
      print('设置全局音量出错: $e');
    }
  }

  Future<void> dispose() async {
    await AudioManager().dispose();
  }
}
