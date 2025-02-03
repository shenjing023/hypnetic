import 'player_interface.dart';
import 'audio_player_impl.dart';
import 'video_player_impl.dart';

enum PlayerType {
  audio,
  video,
}

class PlayerFactory {
  static Player createPlayer(PlayerType type, {PlayerConfig? config}) {
    switch (type) {
      case PlayerType.audio:
        return AudioPlayerImpl(config: config);
      case PlayerType.video:
        return VideoPlayerImpl(config: config);
    }
  }
}
