import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/video_info.dart';
import '../services/video/video_service_manager.dart';
import '../services/error/app_error.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'audio_player_provider.dart';

part 'video_provider.g.dart';

@riverpod
class VideoState extends _$VideoState {
  static const int maxResults = 20;
  static const int fetchResults = 50;

  @override
  FutureOr<List<VideoInfo>> build() async {
    return const [];
  }

  Future<void> searchVideos(String keyword) async {
    state = const AsyncLoading();
    try {
      final videos = await VideoServiceManager.instance.currentService
          .searchVideos(keyword, pageSize: fetchResults);

      // 随机抽取20条数据
      if (videos.length > maxResults) {
        final random = Random();
        final selectedVideos = <VideoInfo>[];
        final tempVideos = List<VideoInfo>.from(videos);

        while (selectedVideos.length < maxResults && tempVideos.isNotEmpty) {
          final index = random.nextInt(tempVideos.length);
          selectedVideos.add(tempVideos[index]);
          tempVideos.removeAt(index);
        }

        state = AsyncData(selectedVideos);
      } else {
        state = AsyncData(videos);
      }
    } catch (e, stack) {
      state = AsyncError(ErrorHandler.handle(e), stack);
    }
  }
}

@riverpod
class CurrentVideo extends _$CurrentVideo {
  @override
  VideoInfo? build() => null;

  void setCurrentVideo(VideoInfo video) {
    state = video;
  }

  void clear() {
    state = null;
  }
}

@riverpod
class StreamState extends _$StreamState {
  @override
  FutureOr<StreamInfo?> build() => null;

  Future<void> loadStreamInfo(String videoId) async {
    state = const AsyncLoading();
    try {
      final streamInfo = await VideoServiceManager.instance.currentService
          .getStreamInfo(videoId);
      state = AsyncData(streamInfo);
    } catch (e, stack) {
      state = AsyncError(ErrorHandler.handle(e), stack);
    }
  }

  void clear() {
    state = const AsyncData(null);
  }
}

@riverpod
class PlaybackState extends _$PlaybackState {
  @override
  ({bool isPlaying, Duration position, Duration duration}) build() {
    return (
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
    );
  }

  void setPlaying(bool playing) {
    state = (
      isPlaying: playing,
      position: state.position,
      duration: state.duration,
    );
  }

  void setPosition(Duration position) {
    state = (
      isPlaying: state.isPlaying,
      position: position,
      duration: state.duration,
    );
  }

  void setDuration(Duration duration) {
    state = (
      isPlaying: state.isPlaying,
      position: state.position,
      duration: duration,
    );
  }

  void setVolume(double volume) {
    ref.read(audioPlayerProvider.notifier).setVolume(volume);
  }

  void reset() {
    state = (
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
    );
  }
}
