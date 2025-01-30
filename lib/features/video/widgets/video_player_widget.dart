import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/timer_provider.dart';
import 'dart:developer' as developer;

class VideoPlayerWidget extends ConsumerStatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final double aspectRatio;
  final void Function(bool isPlaying)? onPlayingChanged;
  final void Function(Duration position)? onPositionChanged;
  final void Function(Duration duration)? onDurationChanged;
  final Duration? initialPosition;
  final VoidCallback? onError;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = true,
    this.aspectRatio = 16 / 9,
    this.onPlayingChanged,
    this.onPositionChanged,
    this.onDurationChanged,
    this.initialPosition,
    this.onError,
  });

  @override
  VideoPlayerWidgetState createState() => VideoPlayerWidgetState();
}

class VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _error;
  bool _isPlaying = false;
  bool _hasSetInitialPosition = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      developer.log('开始初始化视频播放器: ${widget.videoUrl}');

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController.initialize();

      if (!mounted) return;

      widget.onDurationChanged?.call(_videoPlayerController.value.duration);

      if (widget.initialPosition != null && !_hasSetInitialPosition) {
        await _videoPlayerController.seekTo(widget.initialPosition!);
        _hasSetInitialPosition = true;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoInitialize: true,
        showControls: false,
        allowFullScreen: false,
        allowMuting: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          widget.onError?.call();
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 42,
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _initializePlayer,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        },
      );

      _videoPlayerController.addListener(_onVideoPlayerChanged);

      setState(() {
        _isInitialized = true;
        _error = null;
      });

      if (widget.autoPlay) {
        _videoPlayerController.play().then((_) {
          if (mounted) {
            setState(() {
              _isPlaying = true;
            });
            widget.onPlayingChanged?.call(true);
          }
        });
      }
    } catch (e, stack) {
      developer.log('视频播放器初始化失败', error: e, stackTrace: stack);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitialized = false;
        });
        widget.onError?.call();
      }
    }
  }

  void _onVideoPlayerChanged() {
    final value = _videoPlayerController.value;
    final newIsPlaying = value.isPlaying;

    if (_isPlaying != newIsPlaying) {
      _isPlaying = newIsPlaying;
      widget.onPlayingChanged?.call(newIsPlaying);
    }

    if (value.isPlaying) {
      widget.onPositionChanged?.call(value.position);
    }
  }

  @override
  void dispose() {
    developer.log('销毁视频播放器');
    _videoPlayerController.removeListener(_onVideoPlayerChanged);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void play() {
    _videoPlayerController.play().then((_) {
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
        widget.onPlayingChanged?.call(true);
      }
    });
  }

  void pause() {
    _videoPlayerController.pause().then((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        widget.onPlayingChanged?.call(false);
      }
    });
  }

  void togglePlay() =>
      _videoPlayerController.value.isPlaying ? pause() : play();
  void seekTo(Duration position) => _videoPlayerController.seekTo(position);
  void setVolume(double volume) => _videoPlayerController.setVolume(volume);
  bool get isPlaying => _videoPlayerController.value.isPlaying;
  Duration get position => _videoPlayerController.value.position;
  Duration get duration => _videoPlayerController.value.duration;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '视频加载失败',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializePlayer,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                '加载中...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoPlayerController.value.aspectRatio,
      child: Chewie(
        controller: _chewieController!,
      ),
    );
  }
}
