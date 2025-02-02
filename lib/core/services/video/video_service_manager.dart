import 'video_service.dart';
import 'bilibili_service.dart';

/// 视频服务管理器
/// 用于管理和切换不同平台的视频服务
class VideoServiceManager {
  VideoServiceManager._();
  static final _instance = VideoServiceManager._();

  /// 获取单例实例
  static VideoServiceManager get instance => _instance;

  /// 当前支持的服务列表
  final Map<String, VideoService> _services = {};

  /// 当前使用的服务
  VideoService? _currentService;

  /// 初始化服务
  void initialize() {
    // 注册B站服务
    registerService(BilibiliService());
    // 默认使用B站服务
    setCurrentService('bilibili');
  }

  /// 注册新的视频服务
  void registerService(VideoService service) {
    _services[service.platform] = service;
  }

  /// 设置当前使用的服务
  /// [platform] 平台标识
  /// 如果平台不存在，将抛出异常
  void setCurrentService(String platform) {
    final service = _services[platform];
    if (service == null) {
      throw Exception('未找到平台 $platform 的服务实现');
    }
    _currentService = service;
  }

  /// 获取当前服务
  VideoService get currentService {
    if (_currentService == null) {
      throw Exception('视频服务未初始化');
    }
    return _currentService!;
  }

  /// 获取所有支持的平台
  List<String> get supportedPlatforms => _services.keys.toList();

  /// 释放资源
  Future<void> dispose() async {
    for (final service in _services.values) {
      await service.dispose();
    }
    _services.clear();
    _currentService = null;
  }
}
