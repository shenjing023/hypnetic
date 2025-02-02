import 'package:flutter/material.dart';
import 'package:hypnetic/core/services/player/player_interface.dart';

class PlayerControls extends StatelessWidget {
  final Player player;
  final double iconSize;
  final Color iconColor;

  const PlayerControls({
    super.key,
    required this.player,
    this.iconSize = 32.0,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 后退按钮
        IconButton(
          icon: Icon(Icons.replay_10, color: iconColor),
          onPressed: () {
            final newPosition =
                player.position.value - const Duration(seconds: 10);
            player.seekTo(newPosition);
          },
        ),
        // 播放/暂停按钮
        ValueListenableBuilder<PlayerState>(
          valueListenable: player.state,
          builder: (context, state, _) {
            final isPlaying = state == PlayerState.playing;
            return IconButton(
              iconSize: iconSize,
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: iconColor,
              ),
              onPressed: isPlaying ? player.pause : player.play,
            );
          },
        ),
        // 前进按钮
        IconButton(
          icon: Icon(Icons.forward_10, color: iconColor),
          onPressed: () {
            final newPosition =
                player.position.value + const Duration(seconds: 10);
            player.seekTo(newPosition);
          },
        ),
      ],
    );
  }
}
