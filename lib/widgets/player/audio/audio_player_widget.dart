import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:hypnetic/core/models/video_info.dart';
import 'dart:async';

/// 音频播放器组件
class AudioPlayerWidget extends StatefulWidget {
  final StreamInfo streamInfo;
  final Function(Duration) onPositionChanged;
  final bool isPlaying;

  const AudioPlayerWidget({
    super.key,
    required this.streamInfo,
    required this.onPositionChanged,
    required this.isPlaying,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  VideoPlayerController? _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果音频URL发生变化，重新初始化播放器
    if (widget.streamInfo.audioUrl != oldWidget.streamInfo.audioUrl) {
      _disposePlayer().then((_) {
        if (mounted) {
          _initializePlayer();
        }
      });
    }
    // 当播放状态改变时，控制播放器
    else if (widget.isPlaying != oldWidget.isPlaying && _controller != null) {
      if (widget.isPlaying) {
        _controller?.play();
      } else {
        _controller?.pause();
      }
    }
  }

  Future<void> _disposePlayer() async {
    final timer = _timer;
    final controller = _controller;

    _timer = null;
    _controller = null;

    timer?.cancel();
    if (controller != null) {
      try {
        await controller.pause();
        await controller.dispose();
      } catch (e) {
        debugPrint('Error disposing player: $e');
      }
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  /// 获取平台特定的HTTP头
  Map<String, String> _getPlatformHeaders() {
    switch (widget.streamInfo.platform) {
      case 'bilibili':
        return {
          'Referer': 'https://www.bilibili.com',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        };
      // 其他平台可以在这里添加
      default:
        return {};
    }
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.streamInfo.audioUrl),
        httpHeaders: _getPlatformHeaders(),
      );

      _controller = controller;
      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      // 设置循环播放
      controller.setLooping(true);

      setState(() {});

      if (widget.isPlaying) {
        await controller.play();
      }

      // 开始监听进度
      if (mounted) {
        _startPositionTimer();
      }
    } catch (e) {
      debugPrint('音频播放器初始化失败: $e');
      await _disposePlayer();
    }
  }

  void _startPositionTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_controller != null && _controller!.value.isInitialized) {
        widget.onPositionChanged(_controller!.value.position);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }

    return SizedBox(
      height: 10,
      child: Center(
        child: Stack(
          children: [
            // 实际的进度条
            Positioned.fill(
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            // 透明的点击层，提供更大的点击区域
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (details) {
                  _controller?.pause();
                },
                onHorizontalDragUpdate: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final double position = details.localPosition.dx;
                  final double maxWidth = box.size.width;
                  final double percent = position / maxWidth;
                  final Duration duration = _controller!.value.duration;
                  final double targetSeconds = (duration.inSeconds * percent)
                      .clamp(0, duration.inSeconds)
                      .toDouble();
                  _controller?.seekTo(Duration(seconds: targetSeconds.toInt()));
                },
                onHorizontalDragEnd: (details) {
                  if (widget.isPlaying) {
                    _controller?.play();
                  }
                },
                onTapDown: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final double position = details.localPosition.dx;
                  final double maxWidth = box.size.width;
                  final double percent = position / maxWidth;
                  final Duration duration = _controller!.value.duration;
                  final double targetSeconds = (duration.inSeconds * percent)
                      .clamp(0, duration.inSeconds)
                      .toDouble();
                  _controller?.seekTo(Duration(seconds: targetSeconds.toInt()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 自定义进度条形状，移除默认边距
class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
