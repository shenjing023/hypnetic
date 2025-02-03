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

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget>
    with AutomaticKeepAliveClientMixin {
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  int _retryCount = 0;
  static const int maxRetries = 3;
  static const Duration timeoutDuration = Duration(seconds: 15);
  bool _isDisposed = false;
  String? _currentUrl;
  Completer<void>? _setupCompleter;

  AudioPlayer? get _player => ref.read(audioPlayerProvider).player;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '🔵 [AudioPlayer] initState - URL: ${widget.streamInfo.audioUrl}');
    _setupPlayer();
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🔄 [AudioPlayer] didUpdateWidget called');

    if (_isDisposed) {
      debugPrint('⚠️ [AudioPlayer] Widget is disposed, ignoring update');
      return;
    }

    // 检查音频URL是否发生变化
    if (widget.streamInfo.audioUrl != oldWidget.streamInfo.audioUrl) {
      debugPrint(
          '🔄 [AudioPlayer] URL changed - Old: ${oldWidget.streamInfo.audioUrl}, New: ${widget.streamInfo.audioUrl}');
      _setupPlayer();
    } else if (widget.isPlaying != oldWidget.isPlaying) {
      debugPrint(
          '🎵 [AudioPlayer] Play state changed - Old: ${oldWidget.isPlaying}, New: ${widget.isPlaying}');
      _updatePlayState();
    }
  }

  void _updatePlayState() {
    if (_player == null || _isDisposed) {
      debugPrint(
          '⚠️ [AudioPlayer] Cannot update play state - player is null or disposed');
      return;
    }

    debugPrint('🎮 [AudioPlayer] Updating play state to: ${widget.isPlaying}');
    if (widget.isPlaying) {
      _player?.play().then((_) {
        if (!_isDisposed) {
          debugPrint('✅ [AudioPlayer] Play succeeded');
        }
      }).catchError((e) {
        if (!_isDisposed) {
          debugPrint('❌ [AudioPlayer] Play failed: $e');
        }
      });
    } else {
      _player?.pause().then((_) {
        if (!_isDisposed) {
          debugPrint('✅ [AudioPlayer] Pause succeeded');
        }
      }).catchError((e) {
        if (!_isDisposed) {
          debugPrint('❌ [AudioPlayer] Pause failed: $e');
        }
      });
    }
  }

  Future<void> _setupPlayer() async {
    if (_isDisposed) {
      debugPrint('⚠️ [AudioPlayer] Cannot setup - widget is disposed');
      return;
    }

    debugPrint('🎯 [AudioPlayer] Setting up player');

    if (_setupCompleter != null) {
      debugPrint('⏳ [AudioPlayer] Setup already in progress, waiting...');
      await _setupCompleter!.future;
      return;
    }

    _setupCompleter = Completer<void>();

    try {
      debugPrint('🧹 [AudioPlayer] Starting cleanup');
      await _cleanupSubscriptions();

      if (_isDisposed) {
        debugPrint('⚠️ [AudioPlayer] Widget disposed after cleanup');
        return;
      }

      // 通知 provider 设置新的音频源
      await ref.read(audioPlayerProvider.notifier).setupAudioSource(
            widget.streamInfo.audioUrl,
            id: widget.streamInfo.id,
            platform: widget.streamInfo.platform,
            title: widget.streamInfo.title,
            author: widget.streamInfo.author,
            cover: widget.streamInfo.cover,
            duration: widget.streamInfo.duration,
          );

      if (_isDisposed) {
        debugPrint('⚠️ [AudioPlayer] Widget disposed after setup');
        return;
      }

      debugPrint('🔄 [AudioPlayer] Setting up listeners');
      await _setupListeners();

      if (_isDisposed || !mounted) return;

      if (widget.isPlaying && !_isDisposed) {
        debugPrint('▶️ [AudioPlayer] Starting playback');
        await _player?.play();
      }

      _retryCount = 0;
      debugPrint('✅ [AudioPlayer] Player setup completed successfully');
    } catch (e) {
      debugPrint('❌ [AudioPlayer] Player setup failed: $e');
      if (_retryCount < maxRetries && !_isDisposed) {
        _retryCount++;
        debugPrint('🔄 [AudioPlayer] Scheduling retry #$_retryCount');
        Future.delayed(Duration(seconds: _retryCount), _setupPlayer);
      }
    } finally {
      if (!_isDisposed &&
          _setupCompleter != null &&
          !_setupCompleter!.isCompleted) {
        _setupCompleter!.complete();
      }
      _setupCompleter = null;
    }
  }

  Future<void> _cleanupSubscriptions() async {
    debugPrint('🔌 [AudioPlayer] Cancelling subscriptions');
    await Future.wait([
      _positionSubscription?.cancel() ?? Future.value(),
      _playerStateSubscription?.cancel() ?? Future.value(),
    ]);

    _positionSubscription = null;
    _playerStateSubscription = null;
  }

  Future<void> _setupListeners() async {
    if (_isDisposed || !mounted || _player == null) {
      debugPrint('⚠️ [AudioPlayer] Cannot setup listeners - invalid state');
      return;
    }

    debugPrint('👂 [AudioPlayer] Setting up state listener');
    _playerStateSubscription = _player!.playerStateStream.listen(
      (state) {
        if (_isDisposed) return;
        debugPrint(
            '🎵 [AudioPlayer] State changed: ${state.processingState} - Playing: ${state.playing}');
        if (state.processingState == ProcessingState.completed) {
          debugPrint('🔁 [AudioPlayer] Playback completed, restarting');
          _player!.seek(Duration.zero);
          if (widget.isPlaying) {
            _player!.play();
          }
        }
      },
      onError: (error) {
        if (!_isDisposed) {
          debugPrint('❌ [AudioPlayer] State listener error: $error');
        }
      },
    );

    if (_isDisposed) return;

    debugPrint('⏱️ [AudioPlayer] Setting up position listener');
    _positionSubscription = _player!.positionStream.listen(
      (position) {
        if (_isDisposed) return;
        widget.onPositionChanged(position);
      },
      onError: (error) {
        if (!_isDisposed) {
          debugPrint('❌ [AudioPlayer] Position listener error: $error');
        }
      },
    );
  }

  @override
  void dispose() {
    debugPrint('👋 [AudioPlayer] Disposing widget');
    _isDisposed = true;
    _cleanupSubscriptions();
    super.dispose();
  }

  Map<String, String> _getPlatformHeaders() {
    switch (widget.streamInfo.platform) {
      case 'bilibili':
        return {
          'Referer': 'https://www.bilibili.com',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        };
      default:
        return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
