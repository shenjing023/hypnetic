import 'package:flutter/material.dart';
import 'package:hypnetic/core/services/player/player_interface.dart';

class TimeDisplay extends StatelessWidget {
  final Player player;
  final TextStyle? textStyle;

  const TimeDisplay({
    super.key,
    required this.player,
    this.textStyle,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<Duration>(
          valueListenable: player.position,
          builder: (context, position, _) {
            return Text(
              _formatDuration(position),
              style: textStyle ?? defaultStyle,
            );
          },
        ),
        Text(
          ' / ',
          style: textStyle ?? defaultStyle,
        ),
        ValueListenableBuilder<Duration>(
          valueListenable: player.duration,
          builder: (context, duration, _) {
            return Text(
              _formatDuration(duration),
              style: textStyle ?? defaultStyle,
            );
          },
        ),
      ],
    );
  }
}
