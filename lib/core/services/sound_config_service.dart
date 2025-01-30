import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import '../models/sound_model.dart';

/// 声音配置加载异常
class SoundConfigException implements Exception {
  final String message;
  final dynamic error;

  SoundConfigException(this.message, [this.error]);

  @override
  String toString() =>
      'SoundConfigException: $message${error != null ? ' - $error' : ''}';
}

/// 声音配置服务
///
/// 负责管理应用中的声音配置，包括：
/// - 从配置文件加载声音列表
/// - 管理声音集合
/// - 提供声音查询和添加功能
class SoundConfigService {
  static final SoundConfigService _instance = SoundConfigService._internal();
  factory SoundConfigService() => _instance;
  SoundConfigService._internal();

  List<SoundModel> _sounds = [];

  /// 获取所有可用的声音列表
  List<SoundModel> get sounds => List.unmodifiable(_sounds);

  /// 从配置文件加载声音配置
  ///
  /// 从 assets/config/sounds.json 文件中加载声音配置。
  /// 如果加载失败，将抛出 [SoundConfigException]。
  Future<void> loadSoundConfig() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/config/sounds.json');

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      if (!jsonMap.containsKey('sounds')) {
        throw SoundConfigException('配置文件格式错误：缺少 sounds 字段');
      }

      final List<dynamic> soundsList = jsonMap['sounds'] as List<dynamic>;
      _sounds = soundsList
          .map((json) => SoundModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      throw SoundConfigException('JSON 解析错误', e);
    } on PlatformException catch (e) {
      throw SoundConfigException('配置文件读取失败', e);
    } catch (e) {
      throw SoundConfigException('加载音频配置出错', e);
    }
  }

  /// 根据ID查找声音
  ///
  /// [id] 声音的唯一标识符
  /// 返回找到的声音模型，如果未找到返回 null
  SoundModel? getSoundById(String id) {
    return _sounds.firstWhereOrNull((sound) => sound.id == id);
  }

  /// 添加新的声音
  ///
  /// [sound] 要添加的声音模型
  /// 如果声音ID已存在，将更新现有声音
  void addSound(SoundModel sound) {
    final index = _sounds.indexWhere((s) => s.id == sound.id);
    if (index != -1) {
      _sounds[index] = sound;
    } else {
      _sounds.add(sound);
    }
  }

  /// 移除声音
  ///
  /// [id] 要移除的声音ID
  /// 返回是否成功移除
  bool removeSound(String id) {
    final initialLength = _sounds.length;
    _sounds.removeWhere((sound) => sound.id == id);
    return _sounds.length < initialLength;
  }

  /// 清空所有声音配置
  void clear() {
    _sounds.clear();
  }
}
