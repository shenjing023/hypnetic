import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayer?>((ref) {
  return AudioPlayerNotifier();
});

class AudioPlayerNotifier extends StateNotifier<AudioPlayer?> {
  AudioPlayerNotifier() : super(null);

  void setPlayer(AudioPlayer? player) {
    state = player;
  }

  Future<void> setVolume(double volume) async {
    if (state != null) {
      await state!.setVolume(volume.clamp(0.0, 1.0));
    }
  }

  @override
  void dispose() {
    state?.dispose();
    super.dispose();
  }
}
