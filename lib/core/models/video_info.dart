/// 视频信息基础接口
abstract class VideoInfo {
  /// 视频唯一标识
  String get id;

  /// 视频标题
  String get title;

  /// 视频作者
  String get author;

  /// 视频封面图片URL
  String get cover;

  /// 视频时长
  Duration get duration;

  /// 播放次数
  int? get playCount;

  /// 视频来源平台
  String get platform;
}

/// 视频流信息
class StreamInfo implements VideoInfo {
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

  /// 音频URL
  final String audioUrl;

  /// 视频URL（如果有）
  final String? videoUrl;

  /// 视频质量（如果有）
  final String? quality;

  StreamInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.platform,
    required this.audioUrl,
    required this.duration,
    this.playCount,
    this.videoUrl,
    this.quality,
  });

  factory StreamInfo.fromJson(Map<String, dynamic> json) {
    return StreamInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      cover: json['cover'] as String,
      platform: json['platform'] as String,
      audioUrl: json['audio_url'] as String,
      duration: Duration(seconds: json['duration'] as int),
      playCount: json['play_count'] as int?,
      videoUrl: json['video_url'] as String?,
      quality: json['quality'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover': cover,
      'platform': platform,
      'audio_url': audioUrl,
      'duration': duration.inSeconds,
      'play_count': playCount,
      'video_url': videoUrl,
      'quality': quality,
    };
  }

  StreamInfo copyWith({
    String? id,
    String? title,
    String? author,
    String? cover,
    String? platform,
    String? audioUrl,
    Duration? duration,
    int? playCount,
    String? videoUrl,
    String? quality,
  }) {
    return StreamInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      cover: cover ?? this.cover,
      platform: platform ?? this.platform,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      playCount: playCount ?? this.playCount,
      videoUrl: videoUrl ?? this.videoUrl,
      quality: quality ?? this.quality,
    );
  }

  @override
  String toString() {
    return 'StreamInfo(id: $id, title: $title, author: $author, platform: $platform)';
  }
}
