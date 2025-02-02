import 'package:flutter/material.dart';
import 'package:hypnetic/core/services/player/player_interface.dart';

class ProgressBar extends StatelessWidget {
  final Player player;
  final double height;
  final Color activeColor;
  final Color inactiveColor;
  final Color bufferColor;
  final double thumbRadius;

  const ProgressBar({
    super.key,
    required this.player,
    this.height = 4.0,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.transparent,
    this.bufferColor = Colors.white24,
    this.thumbRadius = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 缓冲进度条
        ValueListenableBuilder<double>(
          valueListenable: player.bufferProgress,
          builder: (context, progress, _) {
            return LinearProgressIndicator(
              value: progress,
              backgroundColor: bufferColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                bufferColor.withOpacity(0.5),
              ),
              minHeight: height,
            );
          },
        ),
        // 播放进度条
        ValueListenableBuilder<Duration>(
          valueListenable: player.position,
          builder: (context, position, _) {
            return ValueListenableBuilder<Duration>(
              valueListenable: player.duration,
              builder: (context, duration, _) {
                return SliderTheme(
                  data: SliderThemeData(
                    trackHeight: height,
                    activeTrackColor: activeColor,
                    inactiveTrackColor: inactiveColor,
                    thumbColor: activeColor,
                    overlayColor: activeColor.withOpacity(0.3),
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: thumbRadius,
                      pressedElevation: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble(),
                    min: 0,
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      player.seekTo(Duration(milliseconds: value.round()));
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
