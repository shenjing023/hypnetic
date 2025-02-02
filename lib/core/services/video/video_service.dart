import '../../models/video_info.dart';

/// 视频服务基础接口
abstract class VideoService {
  /// 搜索视频
  Future<List<VideoInfo>> searchVideos(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  });

  /// 获取视频流信息
  Future<StreamInfo> getStreamInfo(String videoId);

  /// 获取服务平台名称
  String get platform;

  /// 释放资源
  Future<void> dispose() async {}
}
