import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/video/models/video_model.dart';

final videoProvider = StateNotifierProvider<VideoNotifier, List<VideoModel>>(
  (ref) => VideoNotifier(),
);

class VideoNotifier extends StateNotifier<List<VideoModel>> {
  VideoNotifier() : super(_initialVideos);

  static final List<VideoModel> _initialVideos = [
    VideoModel(
      id: '1',
      title: '【白噪音】下雨天在教室自习 | 雨声 | 雷声 | 教室氛围声 | 学习 | 工作 | 助眠',
      author: '白噪音助眠',
      thumbnailUrl:
          'https://i2.hdslb.com/bfs/archive/b1e5e41a22ee5f066d86dd351700ff80e7e2e907.jpg@672w_378h_1c_!web-search-common-cover.avif',
      videoUrl:
          'https://kvideo01.youju.sohu.com/595cccef-2e0a-474b-9ba0-c5504c5517082_0_0.mp4?sign=9dacf23421764729cf813fe58fdafe64&t=1738250348',
      duration: '1:00:00',
      viewCount: '10.5万',
      publishDate: '2024-01-30',
    ),
    VideoModel(
      id: '2',
      title: '【白噪音】432HZ的雨声，能让人体达到极度舒适的频率',
      author: '自然音乐',
      thumbnailUrl:
          'https://i2.hdslb.com/bfs/archive/b1e5e41a22ee5f066d86dd351700ff80e7e2e907.jpg@672w_378h_1c_!web-search-common-cover.avif',
      videoUrl:
          'https://kvideo01.youju.sohu.com/595cccef-2e0a-474b-9ba0-c5504c5517082_0_0.mp4?sign=9dacf23421764729cf813fe58fdafe64&t=1738250348',
      duration: '45:00',
      viewCount: '8.2万',
      publishDate: '2024-01-29',
    ),
    VideoModel(
      id: '3',
      title: '【助眠】深度睡眠白噪音 | 大自然雨声 | 完美睡眠',
      author: '睡眠专家',
      thumbnailUrl:
          'https://i2.hdslb.com/bfs/archive/b1e5e41a22ee5f066d86dd351700ff80e7e2e907.jpg@672w_378h_1c_!web-search-common-cover.avif',
      videoUrl:
          'https://kvideo01.youju.sohu.com/595cccef-2e0a-474b-9ba0-c5504c5517082_0_0.mp4?sign=9dacf23421764729cf813fe58fdafe64&t=1738250348',
      duration: '8:00:00',
      viewCount: '15.7万',
      publishDate: '2024-01-28',
    ),
  ];

  // 获取当前正在播放的视频
  VideoModel? get currentPlayingVideo {
    try {
      return state.firstWhere((video) => video.isPlaying);
    } catch (e) {
      return null;
    }
  }

  void toggleVideoPlayback(String videoId) {
    final currentPlaying = currentPlayingVideo;

    // 如果点击的是当前正在播放的视频，则暂停它
    if (currentPlaying?.id == videoId) {
      state = state.map((video) => video.copyWith(isPlaying: false)).toList();
      return;
    }

    // 如果点击的是其他视频，则停止当前播放的视频，开始播放新视频
    state = state.map((video) {
      if (video.id == videoId) {
        return video.copyWith(isPlaying: true);
      } else {
        return video.copyWith(isPlaying: false);
      }
    }).toList();
  }

  void stopAllVideos() {
    state = state.map((video) => video.copyWith(isPlaying: false)).toList();
  }
}
