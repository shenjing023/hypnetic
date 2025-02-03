import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bilibili_models.dart';
import '../../models/video_info.dart';
import 'video_service.dart';

/// B站视频服务实现
class BilibiliService implements VideoService {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.bilibili.com',
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Referer': 'https://www.bilibili.com',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Origin': 'https://www.bilibili.com',
      'Cookie':
          'buvid3=randomstring; i-wanna-go-back=-1; b_ut=7; _uuid=randomstring;',
    },
  ));

  @override
  String get platform => 'bilibili';

  String _cleanHtmlTags(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .trim();
  }

  Duration _parseDuration(dynamic value) {
    if (value == null) return Duration.zero;
    if (value is int) return Duration(seconds: value);
    if (value is String) {
      if (value.contains(':')) {
        final parts = value.split(':');
        if (parts.length == 2) {
          final minutes = int.tryParse(parts[0]) ?? 0;
          final seconds = int.tryParse(parts[1]) ?? 0;
          return Duration(minutes: minutes, seconds: seconds);
        }
      }
      return Duration(seconds: int.tryParse(value) ?? 0);
    }
    return Duration.zero;
  }

  String _formatImageUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('//')) return 'https:$url';
    return 'https://$url';
  }

  @override
  Future<List<VideoInfo>> searchVideos(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/x/web-interface/search/type',
        queryParameters: {
          'keyword': keyword,
          'search_type': 'video',
          'order': 'stow',
          'page': page,
          'platform': 'pc',
          'single_column': 0,
          'highlight': 1,
          'qv_id': DateTime.now().millisecondsSinceEpoch.toString(),
          '__refresh__': true,
          '_extra': '',
          'context': '',
          'page_size': pageSize,
          'from_source': '',
          'from_spmid': '333.337',
          'category_id': '',
          'timeline': '',
          'order_sort': 0,
        },
      );

      if (response.data['code'] != 0) {
        throw Exception(response.data['message'] ?? '搜索失败');
      }

      final data = response.data['data'];
      if (data == null) return [];

      final List<dynamic> results = data['result'] ?? [];
      if (results.isEmpty) return [];

      return results.map((json) {
        try {
          return BilibiliVideoInfo(
            bvid: json['bvid']?.toString() ?? '',
            title: _cleanHtmlTags(json['title']?.toString() ?? ''),
            author: (json['author'] ?? json['uploader'])?.toString() ?? '',
            cover: _formatImageUrl(json['pic']?.toString() ?? ''),
            duration: _parseDuration(json['duration']),
            playCount: json['play'] ?? json['view'] ?? 0,
          );
        } catch (e) {
          debugPrint('解析视频信息失败: $e');
          rethrow;
        }
      }).toList();
    } catch (e) {
      throw Exception('搜索视频失败: $e');
    }
  }

  String _extractBvid(String input) {
    if (input.contains('bilibili.com')) {
      final uri = Uri.parse(input);
      final pathSegments = uri.pathSegments;
      for (final segment in pathSegments) {
        if (segment.startsWith('BV')) {
          return segment;
        }
      }
    }
    if (input.startsWith('BV')) {
      return input;
    }
    throw FormatException('无效的B站视频ID或链接');
  }

  @override
  Future<StreamInfo> getStreamInfo(String videoId) async {
    try {
      final bvid = _extractBvid(videoId);

      final videoInfoResponse = await _dio.get(
        '/x/web-interface/view',
        queryParameters: {'bvid': bvid},
      );

      if (videoInfoResponse.data['code'] != 0) {
        throw Exception(videoInfoResponse.data['message']);
      }

      if (videoInfoResponse.data['data'] == null) {
        throw Exception('获取视频信息失败：返回数据为空');
      }

      final cid = videoInfoResponse.data['data']['cid'];
      final playUrlResponse = await _dio.get(
        '/x/player/playurl',
        queryParameters: {
          'bvid': bvid,
          'cid': cid,
          'qn': 80,
          'fnval': 16,
        },
      );

      if (playUrlResponse.data['code'] != 0) {
        throw Exception(playUrlResponse.data['message']);
      }

      final data = playUrlResponse.data['data'];
      if (data == null) {
        throw Exception('获取视频播放地址失败：返回数据为空');
      }

      final dash = data['dash'];
      if (dash != null) {
        final videos = dash['video'] as List?;
        final audios = dash['audio'] as List?;

        if (audios == null || audios.isEmpty) {
          throw Exception('无法获取音频流地址');
        }

        // 选择最佳质量的音频流
        final audio = audios.reduce((a, b) {
          final qualityA = a['id'] as int? ?? 0;
          final qualityB = b['id'] as int? ?? 0;
          return qualityA > qualityB ? a : b;
        });

        final audioUrl = audio['baseUrl'] as String;
        String? videoUrl;
        String? quality;

        // 确保使用 HTTPS
        final processedAudioUrl = audioUrl.startsWith('http:')
            ? 'https${audioUrl.substring(4)}'
            : audioUrl;

        if (videos != null && videos.isNotEmpty) {
          videoUrl = videos[0]['baseUrl'] as String;
          quality = '${videos[0]['width']}x${videos[0]['height']}';
        }

        return BilibiliStreamInfo(
          audioUrl: processedAudioUrl,
          videoUrl: videoUrl,
          quality: quality,
          id: bvid,
          title: videoInfoResponse.data['data']['title'],
          author: videoInfoResponse.data['data']['owner']['name'],
          cover: videoInfoResponse.data['data']['pic'],
          duration: _parseDuration(videoInfoResponse.data['data']['duration']),
          playCount: videoInfoResponse.data['data']['stat']['view'],
        );
      }

      final durl = data['durl'];
      if (durl == null || durl is! List || durl.isEmpty) {
        throw Exception('无法获取视频播放地址：数据格式错误');
      }

      final url = durl[0]['url'];
      if (url == null || url.toString().isEmpty) {
        throw Exception('视频地址为空');
      }

      return BilibiliStreamInfo(
        audioUrl: url.toString(),
        videoUrl: url.toString(),
        id: bvid,
        title: videoInfoResponse.data['data']['title'],
        author: videoInfoResponse.data['data']['owner']['name'],
        cover: videoInfoResponse.data['data']['pic'],
        duration: _parseDuration(videoInfoResponse.data['data']['duration']),
        playCount: videoInfoResponse.data['data']['stat']['view'],
      );
    } catch (e) {
      throw Exception('获取视频播放地址失败: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _dio.close();
  }
}
