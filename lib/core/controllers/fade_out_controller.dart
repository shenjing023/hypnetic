import 'package:flutter/foundation.dart';

class FadeOutController {
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onComplete;
  double _volume = 1.0;

  FadeOutController({
    required this.onVolumeChanged,
    required this.onComplete,
  });

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    onVolumeChanged(_volume);
    if (_volume <= 0) {
      onComplete();
    }
  }

  void stop() {
    _volume = 1.0;
    onVolumeChanged(_volume);
  }

  void dispose() {
    stop();
  }
}
