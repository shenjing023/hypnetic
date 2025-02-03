import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/foundation.dart';

// 播放器状态
class AudioPlayerState {
  final AudioPlayer? player;
  final String? currentUrl;
  final bool isInitialized;

  AudioPlayerState({
    this.player,
    this.currentUrl,
    this.isInitialized = false,
  });

  AudioPlayerState copyWith({
    AudioPlayer? player,
    String? currentUrl,
    bool? isInitialized,
  }) {
    return AudioPlayerState(
      player: player ?? this.player,
      currentUrl: currentUrl ?? this.currentUrl,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier();
});

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  bool _isDisposing = false;

  AudioPlayerNotifier() : super(AudioPlayerState()) {
    _initializePlayer();
  }

  void _initializePlayer() {
    if (_isDisposing) return;

    debugPrint('🆕 [AudioPlayerProvider] Initializing new player');
    final player = AudioPlayer();
    state = AudioPlayerState(
      player: player,
      isInitialized: true,
    );
  }

  Future<void> setupAudioSource(
    String url, {
    required String id,
    required String platform,
    required String title,
    required String author,
    required String cover,
    required Duration duration,
  }) async {
    if (_isDisposing) {
      debugPrint(
          '🚫 [AudioPlayerProvider] Provider is disposing, ignoring setup');
      return;
    }

    if (url == state.currentUrl && state.player != null) {
      debugPrint('ℹ️ [AudioPlayerProvider] URL unchanged, skipping setup');
      return;
    }

    debugPrint('🔄 [AudioPlayerProvider] Setting up new audio source: $url');

    // 每次切换音频时都重新创建播放器
    await _resetPlayer();

    final player = state.player;
    if (player == null) {
      debugPrint('❌ [AudioPlayerProvider] Player is null after initialization');
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (!uri.isAbsolute) {
        debugPrint('⚠️ [AudioPlayerProvider] Invalid audio URL: $url');
        return;
      }

      debugPrint('🔧 [AudioPlayerProvider] Creating audio source');
      final audioSource = AudioSource.uri(
        uri,
        headers: {
          ..._getPlatformHeaders(platform),
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Range': 'bytes=0-',
        },
        tag: MediaItem(
          id: id,
          album: platform,
          title: title,
          artist: author,
          artUri: Uri.parse(cover),
          duration: duration,
        ),
      );

      debugPrint('📡 [AudioPlayerProvider] Setting audio source');
      await player
          .setAudioSource(
            audioSource,
            initialPosition: Duration.zero,
            preload: true,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('🔄 [AudioPlayerProvider] Setting loop mode');
      await player.setLoopMode(LoopMode.one);

      // 更新状态
      state = state.copyWith(currentUrl: url);
      debugPrint('✅ [AudioPlayerProvider] Audio source setup completed');
    } catch (e) {
      debugPrint('❌ [AudioPlayerProvider] Error setting up audio source: $e');
      // 如果设置失败，重新初始化播放器
      await _resetPlayer();
    }
  }

  Map<String, String> _getPlatformHeaders(String platform) {
    switch (platform) {
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

  Future<void> _resetPlayer() async {
    if (_isDisposing) return;

    debugPrint('🔄 [AudioPlayerProvider] Resetting player');

    final oldPlayer = state.player;
    if (oldPlayer != null) {
      try {
        await oldPlayer.stop().timeout(
          const Duration(milliseconds: 300),
          onTimeout: () {
            debugPrint('⚠️ [AudioPlayerProvider] Stop timeout');
          },
        );
        await oldPlayer.dispose().timeout(
          const Duration(milliseconds: 300),
          onTimeout: () {
            debugPrint('⚠️ [AudioPlayerProvider] Dispose timeout');
          },
        );
      } catch (e) {
        debugPrint('❌ [AudioPlayerProvider] Error disposing old player: $e');
      }
    }

    if (!_isDisposing) {
      _initializePlayer();
    }
  }

  Future<void> setVolume(double volume) async {
    if (_isDisposing || state.player == null) {
      debugPrint('⚠️ [AudioPlayerProvider] Cannot set volume - invalid state');
      return;
    }

    try {
      debugPrint('🔊 [AudioPlayerProvider] Setting volume to: $volume');
      await state.player!.setVolume(volume.clamp(0.0, 1.0));
      debugPrint('✅ [AudioPlayerProvider] Volume set successfully');
    } catch (e) {
      debugPrint('❌ [AudioPlayerProvider] Error setting volume: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('👋 [AudioPlayerProvider] Disposing provider');
    _isDisposing = true;

    final player = state.player;
    if (player != null) {
      Future(() async {
        try {
          await player.stop().timeout(
            const Duration(milliseconds: 300),
            onTimeout: () {
              debugPrint(
                  '⚠️ [AudioPlayerProvider] Stop timeout during dispose');
            },
          );
          await player.dispose().timeout(
            const Duration(milliseconds: 300),
            onTimeout: () {
              debugPrint(
                  '⚠️ [AudioPlayerProvider] Dispose timeout during dispose');
            },
          );
        } catch (e) {
          debugPrint('❌ [AudioPlayerProvider] Error during dispose: $e');
        }
      });
    }

    state = AudioPlayerState();
    super.dispose();
  }
}
