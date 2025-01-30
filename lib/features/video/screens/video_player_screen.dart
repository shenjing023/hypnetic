import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_model.dart';
import '../../../core/providers/timer_provider.dart';
import '../widgets/video_player_widget.dart';
import 'dart:async';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final VideoModel video;
  final Duration initialPosition;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.initialPosition,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  bool _isFullScreen = false;
  bool _isPlaying = false;
  bool _showControls = true;
  double _volume = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;
  final GlobalKey<VideoPlayerWidgetState> _playerKey = GlobalKey();
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    // 设置横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 设置全屏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    // 恢复竖屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // 恢复系统UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: [SystemUiOverlay.top],
        );
      }
    });
  }

  void _togglePlayPause() {
    final player = _playerKey.currentState;
    if (player != null) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
      player.togglePlay();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _handleVolumeChange(double value) {
    setState(() {
      _volume = value;
    });
    final player = _playerKey.currentState;
    if (player != null) {
      player.setVolume(value);
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _handleTapVideo() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _isPlaying) {
      _startHideControlsTimer();
    }
  }

  void _handlePlayPause() {
    final player = _playerKey.currentState;
    if (player != null) {
      if (_isPlaying) {
        player.pause();
      } else {
        player.play();
      }
    }
  }

  void _handleSeek(double value) {
    final duration = _duration;
    if (duration.inSeconds > 0) {
      final position = duration * value;
      _playerKey.currentState?.seekTo(position);
      setState(() {
        _currentPosition = position;
      });
      if (_isPlaying) {
        _startHideControlsTimer();
      }
    }
  }

  void _showTimerDialog() {
    final timerState = ref.read(timerProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置定时'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('15分钟'),
              onTap: () => _setTimer(15),
            ),
            ListTile(
              title: const Text('30分钟'),
              onTap: () => _setTimer(30),
            ),
            ListTile(
              title: const Text('60分钟'),
              onTap: () => _setTimer(60),
            ),
          ],
        ),
      ),
    );
  }

  void _setTimer(int minutes) {
    ref.read(timerProvider.notifier).setDuration(
          Duration(minutes: minutes),
        );
    if (_isPlaying) {
      ref.read(timerProvider.notifier).start();
    }
    Navigator.pop(context);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return hours > 0
        ? '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}'
        : '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _handleTapVideo,
        child: Stack(
          children: [
            // 视频播放区域
            Center(
              child: VideoPlayerWidget(
                key: _playerKey,
                videoUrl: widget.video.videoUrl,
                autoPlay: true,
                initialPosition: widget.initialPosition,
                onPlayingChanged: (isPlaying) {
                  setState(() {
                    _isPlaying = isPlaying;
                  });
                  if (isPlaying) {
                    _startHideControlsTimer();
                  } else {
                    setState(() {
                      _showControls = true;
                    });
                    _hideControlsTimer?.cancel();
                  }
                },
                onPositionChanged: (position) {
                  setState(() {
                    _currentPosition = position;
                  });
                },
                onDurationChanged: (duration) {
                  setState(() {
                    _duration = duration;
                  });
                },
              ),
            ),
            // 控制层
            if (_showControls)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // 顶部栏
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                color: Colors.white,
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Text(
                                  widget.video.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // 底部控制栏
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // 进度条
                              Row(
                                children: [
                                  Text(
                                    _formatDuration(_currentPosition),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _duration.inSeconds > 0
                                          ? _currentPosition.inSeconds /
                                              _duration.inSeconds
                                          : 0,
                                      onChanged: _handleSeek,
                                      activeColor: Colors.white,
                                      inactiveColor: Colors.white30,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 控制按钮
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    color: Colors.white,
                                    onPressed: _handlePlayPause,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
