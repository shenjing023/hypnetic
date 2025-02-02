// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../models/sound_model.dart';
// import '../models/audio_manager.dart';
// import '../services/sound_config_service.dart';
// import 'video_provider.dart';
// import 'timer_provider.dart';

// final soundProvider =
//     StateNotifierProvider<SoundNotifier, List<SoundModel>>((ref) {
//   return SoundNotifier(ref);
// });

// class SoundNotifier extends StateNotifier<List<SoundModel>> {
//   final Ref _ref;
//   bool _isProcessing = false;

//   SoundNotifier(this._ref) : super([]) {
//     // 设置音频播放状态回调
//     AudioManager().setPlayStateCallback(_handlePlayStateChange);
//   }

//   void _handlePlayStateChange(String id, bool isPlaying) {
//     state = [
//       for (final s in state)
//         if (s.id == id)
//           s.copyWith(isPlaying: isPlaying)
//         else
//           s.copyWith(isPlaying: false)
//     ];

//     // 处理定时器
//     if (isPlaying) {
//       final timerState = _ref.read(timerProvider);
//       if (timerState.remaining > Duration.zero) {
//         _ref
//             .read(timerProvider.notifier)
//             .startWithSource(TimerSource.homeScreen);
//       }
//     } else {
//       if (_ref.read(timerProvider).source == TimerSource.homeScreen) {
//         _ref.read(timerProvider.notifier).pause();
//       }
//     }
//   }

//   Future<void> initializeSounds() async {
//     try {
//       final configService = SoundConfigService();
//       await configService.loadSoundConfig();
//       final sounds = configService.sounds;

//       for (var sound in sounds) {
//         await sound.loadAudio();
//       }

//       state = sounds;
//     } catch (e) {
//       print('音频初始化错误: $e');
//     }
//   }

//   Future<void> toggleSound(String id) async {
//     if (_isProcessing) return;
//     _isProcessing = true;

//     try {
//       final audioManager = AudioManager();
//       final isPlaying = audioManager.isPlaying(id);

//       // 如果视频在播放，先停止视频
//       if (!isPlaying && _ref.read(playbackStateProvider).isPlaying) {
//         _ref.read(playbackStateProvider.notifier).setPlaying(false);
//         _ref.read(currentVideoProvider.notifier).clear();
//         _ref.read(streamStateProvider.notifier).clear();
//       }

//       if (isPlaying) {
//         await audioManager.pause(id);
//       } else {
//         // 停止所有正在播放的音频
//         final playingSounds = audioManager.getPlayingAudioIds();
//         for (final soundId in playingSounds) {
//           await audioManager.pause(soundId);
//         }

//         // 播放新音频
//         await audioManager.play(id);
//       }
//     } catch (e) {
//       print('播放出错: $e');
//       // 发生错误时重置状态
//       state = [for (final s in state) s.copyWith(isPlaying: false)];
//       // 确保暂停定时器
//       _ref.read(timerProvider.notifier).pause();
//     } finally {
//       _isProcessing = false;
//     }
//   }

//   Future<void> setGlobalVolume(double volume) async {
//     try {
//       await AudioManager().setGlobalVolume(volume);
//     } catch (e) {
//       print('设置全局音量出错: $e');
//     }
//   }

//   void updateAllStates(bool isPlaying) {
//     state = [for (final s in state) s.copyWith(isPlaying: isPlaying)];
//   }

//   @override
//   void dispose() {
//     AudioManager().setPlayStateCallback(null);
//     super.dispose();
//   }
// }
