import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/fade_out_controller.dart';
import 'sound_provider.dart';

final fadeOutControllerProvider = Provider<FadeOutController>((ref) {
  final controller = FadeOutController(
    onVolumeChanged: (volume) {
      ref.read(soundProvider.notifier).setGlobalVolume(volume);
    },
    onComplete: () {
      // 音量渐弱完成后的回调
    },
  );

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});
