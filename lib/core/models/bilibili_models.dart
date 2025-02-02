import 'video_info.dart';

/// B站视频信息实现类
class BilibiliVideoInfo implements VideoInfo {
  final String bvid;
  final String title;
  final String author;
  final String cover;
  final Duration duration;
  final int? playCount;

  const BilibiliVideoInfo({
    required this.bvid,
    required this.title,
    required this.author,
    required this.cover,
    required this.duration,
    this.playCount,
  });

  @override
  String get id => bvid;

  @override
  String get coverUrl => cover;

  @override
  String get platform => 'bilibili';
}

/// B站视频流信息实现类
class BilibiliStreamInfo implements StreamInfo {
  @override
  final String id;
  @override
  final String title;
  @override
  final String author;
  @override
  final String cover;
  @override
  final Duration duration;
  @override
  final int? playCount;
  @override
  final String platform;
  @override
  final String audioUrl;
  @override
  final String? videoUrl;
  @override
  final String? quality;

  BilibiliStreamInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.duration,
    required this.audioUrl,
    this.playCount,
    this.videoUrl,
    this.quality,
  }) : platform = 'bilibili';

  @override
  StreamInfo copyWith({
    String? id,
    String? title,
    String? author,
    String? cover,
    Duration? duration,
    int? playCount,
    String? platform,
    String? audioUrl,
    String? videoUrl,
    String? quality,
  }) =>
      BilibiliStreamInfo(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        cover: cover ?? this.cover,
        duration: duration ?? this.duration,
        playCount: playCount ?? this.playCount,
        audioUrl: audioUrl ?? this.audioUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        quality: quality ?? this.quality,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'cover': cover,
        'platform': platform,
        'duration': duration.inSeconds,
        'play_count': playCount,
        'audio_url': audioUrl,
        'video_url': videoUrl,
        'quality': quality,
      };
}
