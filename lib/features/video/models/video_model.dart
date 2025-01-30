import 'package:flutter/material.dart';

/// 视频模型类
class VideoModel {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String videoUrl;
  final String duration;
  final String viewCount;
  final String publishDate;
  final bool isPlaying;

  const VideoModel({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.viewCount,
    required this.publishDate,
    this.isPlaying = false,
  });

  /// 创建视频模型的副本
  VideoModel copyWith({
    String? id,
    String? title,
    String? author,
    String? thumbnailUrl,
    String? videoUrl,
    String? duration,
    String? viewCount,
    String? publishDate,
    bool? isPlaying,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      viewCount: viewCount ?? this.viewCount,
      publishDate: publishDate ?? this.publishDate,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
