import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:hypnetic/core/models/video_info.dart';

class AudioTimeDisplay extends StatefulWidget {
  final Duration duration;
  final StreamInfo streamInfo;

  const AudioTimeDisplay({
    super.key,
    required this.duration,
    required this.streamInfo,
  });

  @override
  State<AudioTimeDisplay> createState() => _AudioTimeDisplayState();
}

class _AudioTimeDisplayState extends State<AudioTimeDisplay> {
  late VideoPlayerController _controller;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(AudioTimeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamInfo.audioUrl != widget.streamInfo.audioUrl) {
      _controller.dispose();
      _initializeController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeController() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.streamInfo.audioUrl),
    );

    await _controller.initialize();
    _controller.addListener(_updatePosition);
  }

  void _updatePosition() {
    if (mounted) {
      setState(() {
        _position = _controller.value.position;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final remainingTime = widget.duration - _position;
    return Text(
      _formatDuration(remainingTime.isNegative ? Duration.zero : remainingTime),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    );
  }
}
