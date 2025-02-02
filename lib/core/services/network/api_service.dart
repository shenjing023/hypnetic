import 'package:dio/dio.dart';
import 'http_client.dart';
import 'api_response.dart';
import '../../models/video_info.dart';

class ApiService {
  static final ApiService instance = ApiService._();
  final _client = HttpClient.instance;

  ApiService._();

  // B站相关接口
  Future<ApiResponse<StreamInfo>> getBilibiliAudioInfo(String bvid) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        'https://api.bilibili.com/x/web-interface/view',
        queryParameters: {'bvid': bvid},
        options: Options(
          headers: {
            'Referer': 'https://www.bilibili.com',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      // 解析视频信息
      final data = response['data'];
      if (data == null) {
        return ApiResponse.error('获取视频信息失败');
      }

      return ApiResponse.success(
        StreamInfo(
          id: bvid,
          title: data['title'],
          author: data['owner']['name'],
          cover: data['pic'],
          platform: 'bilibili',
          audioUrl: '', // 需要进一步处理获取音频URL
          duration: Duration(seconds: data['duration']),
          playCount: data['stat']['view'],
        ),
      );
    } on DioException catch (e) {
      return ApiResponse.error(e.error?.toString() ?? '网络请求失败');
    } catch (e) {
      return ApiResponse.error('解析数据失败: $e');
    }
  }

  // 获取B站音频流URL
  Future<ApiResponse<String>> getBilibiliAudioUrl(String bvid, int cid) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        'https://api.bilibili.com/x/player/playurl',
        queryParameters: {
          'bvid': bvid,
          'cid': cid,
          'fnval': 16,
        },
        options: Options(
          headers: {
            'Referer': 'https://www.bilibili.com',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      final data = response['data'];
      if (data == null) {
        return ApiResponse.error('获取音频地址失败');
      }

      final audioUrl = data['dash']['audio']?[0]?['baseUrl'];
      if (audioUrl == null) {
        return ApiResponse.error('未找到音频地址');
      }

      return ApiResponse.success(audioUrl);
    } on DioException catch (e) {
      return ApiResponse.error(e.error?.toString() ?? '网络请求失败');
    } catch (e) {
      return ApiResponse.error('解析数据失败: $e');
    }
  }

  // 搜索B站视频
  Future<ApiResponse<List<StreamInfo>>> searchBilibiliVideos(
      String keyword) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        'https://api.bilibili.com/x/web-interface/search/all/v2',
        queryParameters: {
          'keyword': keyword,
          'page': 1,
          'pagesize': 20,
        },
        options: Options(
          headers: {
            'Referer': 'https://www.bilibili.com',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      final data = response['data'];
      if (data == null) {
        return ApiResponse.error('搜索失败');
      }

      final results = data['result'] as List?;
      if (results == null) {
        return ApiResponse.success([]);
      }

      final videos = results
          .where((item) => item['type'] == 'video')
          .map((item) => StreamInfo(
                id: item['bvid'],
                title: item['title'],
                author: item['author'],
                cover: item['pic'],
                platform: 'bilibili',
                audioUrl: '', // 需要进一步获取
                duration: Duration(seconds: item['duration']),
                playCount: item['play'],
              ))
          .toList();

      return ApiResponse.success(videos);
    } on DioException catch (e) {
      return ApiResponse.error(e.error?.toString() ?? '网络请求失败');
    } catch (e) {
      return ApiResponse.error('解析数据失败: $e');
    }
  }

  // 可以添加其他平台的API接口...
}
