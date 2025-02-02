import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class AudioCacheManager {
  static final AudioCacheManager instance = AudioCacheManager._();
  final _dio = Dio();
  late final Directory _cacheDir;
  final _downloadProgress = <String, double>{};
  final _downloadCompleters = <String, Completer<String>>{};
  final _maxCacheSize = 500 * 1024 * 1024; // 500MB
  bool _initialized = false;

  AudioCacheManager._();

  Future<void> initialize() async {
    if (_initialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/audio_cache');
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }

    await _cleanupCache();
    _initialized = true;
  }

  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<void> _cleanupCache() async {
    try {
      var totalSize = 0;
      final files = await _cacheDir.list().toList();
      files.sort(
          (a, b) => a.statSync().accessed.compareTo(b.statSync().accessed));

      for (var file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      // 如果缓存超过限制，删除最旧的文件
      if (totalSize > _maxCacheSize) {
        for (var file in files) {
          if (file is File) {
            await file.delete();
            totalSize -= await file.length();
            if (totalSize <= _maxCacheSize) break;
          }
        }
      }
    } catch (e) {
      print('清理缓存失败: $e');
    }
  }

  Future<String> getCachedFile(String url,
      {Map<String, String>? headers}) async {
    if (!_initialized) await initialize();

    final cacheKey = _generateCacheKey(url);
    final cacheFile = File('${_cacheDir.path}/$cacheKey');

    // 如果已经在下载中，等待下载完成
    if (_downloadCompleters.containsKey(cacheKey)) {
      return _downloadCompleters[cacheKey]!.future;
    }

    // 如果缓存存在且未过期，直接返回
    if (await cacheFile.exists()) {
      // 更新访问时间
      await cacheFile.setLastAccessed(DateTime.now());
      return cacheFile.path;
    }

    // 开始新的下载
    final completer = Completer<String>();
    _downloadCompleters[cacheKey] = completer;
    _downloadProgress[cacheKey] = 0;

    try {
      await _dio.download(
        url,
        cacheFile.path,
        options: Options(headers: headers),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress[cacheKey] = received / total;
          }
        },
      );

      completer.complete(cacheFile.path);
    } catch (e) {
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
      completer.completeError(e);
    } finally {
      _downloadCompleters.remove(cacheKey);
      _downloadProgress.remove(cacheKey);
    }

    return completer.future;
  }

  double getDownloadProgress(String url) {
    final cacheKey = _generateCacheKey(url);
    return _downloadProgress[cacheKey] ?? 0;
  }

  Future<void> clearCache() async {
    if (!_initialized) return;

    try {
      final files = await _cacheDir.list().toList();
      for (var file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      print('清除缓存失败: $e');
    }
  }
}
