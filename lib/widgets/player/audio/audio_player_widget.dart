import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:hypnetic/core/models/video_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hypnetic/core/providers/audio_player_provider.dart';
import 'dart:async';

/// 音频播放器组件
class AudioPlayerWidget extends ConsumerStatefulWidget {
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
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  AudioPlayer? _player;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _volumeSubscription;
  int _retryCount = 0;
  static const int maxRetries = 3;
  static const Duration timeoutDuration = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 确保在构建完成后初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果音频URL发生变化，重新初始化播放器
    if (widget.streamInfo.audioUrl != oldWidget.streamInfo.audioUrl) {
      _disposePlayer().then((_) {
        if (mounted) {
          // 使用 addPostFrameCallback 确保在构建完成后初始化
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializePlayer();
          });
        }
      });
    }
    // 当播放状态改变时，控制播放器
    else if (widget.isPlaying != oldWidget.isPlaying && _player != null) {
      // 使用 addPostFrameCallback 确保在构建完成后更新状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.isPlaying) {
          _player?.play();
        } else {
          _player?.pause();
        }
      });
    }
  }

  Future<void> _disposePlayer() async {
    // 在销毁播放器之前清除 provider 中的引用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(audioPlayerProvider.notifier).setPlayer(null);
      }
    });

    await _positionSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _volumeSubscription?.cancel();
    await _player?.dispose();
    _player = null;
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
      final audioUrl = widget.streamInfo.audioUrl;
      if (audioUrl.isEmpty) {
        throw Exception('音频 URL 为空');
      }

      // 验证 URL 格式
      final uri = Uri.parse(audioUrl);
      if (!uri.isAbsolute) {
        throw Exception('无效的音频 URL: $audioUrl');
      }

      debugPrint('开始初始化播放器，URL: $audioUrl');
      final player = AudioPlayer();
      _player = player;

      // 使用 Future.microtask 确保在下一个微任务中更新 provider
      Future.microtask(() {
        if (mounted) {
          ref.read(audioPlayerProvider.notifier).setPlayer(player);
        }
      });

      // 设置音频源
      final headers = _getPlatformHeaders();
      debugPrint('使用 headers: $headers');

      final audioSource = AudioSource.uri(
        uri,
        headers: {
          ...headers,
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Range': 'bytes=0-',
        },
        tag: MediaItem(
          id: widget.streamInfo.id,
          album: widget.streamInfo.platform,
          title: widget.streamInfo.title,
          artist: widget.streamInfo.author,
          artUri: Uri.parse(widget.streamInfo.cover),
          duration: widget.streamInfo.duration,
        ),
      );

      // 添加加载状态监听
      player.playerStateStream.listen(
        (state) {
          debugPrint('播放器状态: ${state.processingState}');
        },
        onError: (error) {
          debugPrint('播放器状态错误: $error');
        },
      );

      // 使用 catchError 处理加载错误
      await player
          .setAudioSource(
        audioSource,
        initialPosition: Duration.zero,
        preload: true,
      )
          .timeout(
        timeoutDuration,
        onTimeout: () {
          throw TimeoutException('音频加载超时');
        },
      ).catchError((error) async {
        debugPrint('音频加载失败: $error');
        if (_retryCount < maxRetries) {
          _retryCount++;
          debugPrint('尝试重新加载 (${_retryCount}/$maxRetries)');
          await Future.delayed(Duration(seconds: _retryCount));
          return _retryLoadAudio(player, audioSource);
        } else {
          throw Exception('音频加载失败，已达到最大重试次数');
        }
      });

      debugPrint('音频源设置成功');
      _retryCount = 0; // 重置重试计数

      // 设置循环播放
      await player.setLoopMode(LoopMode.one);

      // 监听播放位置
      _positionSubscription = player.positionStream.listen(
        (position) {
          widget.onPositionChanged(position);
        },
        onError: (error) {
          debugPrint('播放位置监听错误: $error');
        },
      );

      // 监听播放状态
      _playerStateSubscription = player.playerStateStream.listen(
        (state) {
          debugPrint('播放状态变化: ${state.processingState}');
          if (state.processingState == ProcessingState.completed) {
            player.seek(Duration.zero);
            if (widget.isPlaying) {
              player.play();
            }
          }
        },
        onError: (error) {
          debugPrint('播放状态监听错误: $error');
        },
      );

      if (widget.isPlaying) {
        await player.play();
      }
    } catch (e, stack) {
      debugPrint('音频播放器初始化失败: $e');
      debugPrint('错误堆栈: $stack');
      await _disposePlayer();
      // 如果还有重试次数，则重试
      if (_retryCount < maxRetries) {
        _retryCount++;
        debugPrint('尝试重新初始化 (${_retryCount}/$maxRetries)');
        await Future.delayed(Duration(seconds: _retryCount));
        return _initializePlayer();
      }
    }
  }

  Future<void> _retryLoadAudio(
      AudioPlayer player, AudioSource audioSource) async {
    try {
      await player
          .setAudioSource(
        audioSource,
        initialPosition: Duration.zero,
        preload: true,
      )
          .timeout(
        timeoutDuration,
        onTimeout: () {
          throw TimeoutException('音频重试加载超时');
        },
      );
      return;
    } catch (e) {
      debugPrint('重试加载失败: $e');
      rethrow;
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player?.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('设置音量失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_player == null) {
      return Container();
    }

    return SizedBox(
      height: 10,
      child: Center(
        child: StreamBuilder<Duration?>(
          stream: _player?.durationStream,
          builder: (context, snapshot) {
            final duration = snapshot.data ?? Duration.zero;
            return StreamBuilder<Duration>(
              stream: _player?.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return Stack(
                  children: [
                    // 进度条
                    LinearProgressIndicator(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    // 透明的点击层，提供更大的点击区域
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragStart: (details) {
                          _player?.pause();
                        },
                        onHorizontalDragUpdate: (details) {
                          final box = context.findRenderObject() as RenderBox;
                          final double position = details.localPosition.dx;
                          final double maxWidth = box.size.width;
                          final double percent = position / maxWidth;
                          final double targetSeconds =
                              (duration.inSeconds * percent)
                                  .clamp(0, duration.inSeconds)
                                  .toDouble();
                          _player
                              ?.seek(Duration(seconds: targetSeconds.toInt()));
                        },
                        onHorizontalDragEnd: (details) {
                          if (widget.isPlaying) {
                            _player?.play();
                          }
                        },
                        onTapDown: (details) {
                          final box = context.findRenderObject() as RenderBox;
                          final double position = details.localPosition.dx;
                          final double maxWidth = box.size.width;
                          final double percent = position / maxWidth;
                          final double targetSeconds =
                              (duration.inSeconds * percent)
                                  .clamp(0, duration.inSeconds)
                                  .toDouble();
                          _player
                              ?.seek(Duration(seconds: targetSeconds.toInt()));
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
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
