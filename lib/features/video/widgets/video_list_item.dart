import 'package:flutter/material.dart';
import 'dart:async';
import '../models/video_model.dart';
import 'video_player_widget.dart';
import '../screens/video_player_screen.dart';

class VideoListItem extends StatefulWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const VideoListItem({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  State<VideoListItem> createState() => _VideoListItemState();
}

class _VideoListItemState extends State<VideoListItem> {
  bool _showThumbnail = true;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  final _playerKey = GlobalKey<VideoPlayerWidgetState>();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _showControls = false;
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
    if (_showThumbnail) {
      setState(() {
        _showThumbnail = false;
        _showControls = true;
      });
      widget.onTap();
    } else {
      setState(() {
        _showControls = !_showControls;
      });
      if (_showControls && _isPlaying) {
        _startHideControlsTimer();
      }
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

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 缩略图/视频区域
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: GestureDetector(
                    onTap: _handleTapVideo,
                    child: _showThumbnail
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                widget.video.thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.error_outline),
                                    ),
                                  );
                                },
                              ),
                              // 播放图标遮罩
                              Container(
                                color: Colors.black26,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : VideoPlayerWidget(
                            key: _playerKey,
                            videoUrl: widget.video.videoUrl,
                            autoPlay: true,
                            onError: () {
                              setState(() {
                                _showThumbnail = true;
                                _showControls = false;
                                _isPlaying = false;
                              });
                              _hideControlsTimer?.cancel();
                            },
                            onPlayingChanged: (isPlaying) {
                              setState(() {
                                _isPlaying = isPlaying;
                                if (isPlaying) {
                                  _startHideControlsTimer();
                                } else {
                                  _showControls = true;
                                  _hideControlsTimer?.cancel();
                                }
                              });
                            },
                          ),
                  ),
                ),
              ),
              // 控制层
              if (!_showThumbnail)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _handleTapVideo,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // 播放/暂停按钮
                            Center(
                              child: IconButton(
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  size: 64,
                                  color: Colors.white,
                                ),
                                onPressed: _handlePlayPause,
                              ),
                            ),
                            // 全屏和时长显示
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.video.duration,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            // 全屏按钮
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: GestureDetector(
                                onTap: () {
                                  final player = _playerKey.currentState;
                                  if (player != null) {
                                    final position = player.position;
                                    player.pause();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VideoPlayerScreen(
                                          video: widget.video,
                                          initialPosition: position,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // 视频信息
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  widget.video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: widget.video.isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                ),
                const SizedBox(height: 4),
                // UP主信息
                Text(
                  widget.video.author,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                // 播放量和发布时间
                Row(
                  children: [
                    Text(
                      '${widget.video.viewCount}次观看',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.video.publishDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
