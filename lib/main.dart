import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:developer' as developer;
import 'core/theme/app_theme.dart';
import 'core/services/sound_config_service.dart';
import 'features/audio/screens/home_screen.dart';

/// 应用初始化状态
final initializationProvider = StateProvider<bool>((ref) => false);

/// 应用启动初始化
Future<void> _initializeApp() async {
  final stopwatch = Stopwatch()..start();

  try {
    // 确保Flutter绑定初始化
    WidgetsFlutterBinding.ensureInitialized();
    developer.log('Flutter绑定初始化完成: ${stopwatch.elapsedMilliseconds}ms');

    // 设置首选方向为竖屏
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    developer.log('屏幕方向设置完成: ${stopwatch.elapsedMilliseconds}ms');

    // 设置系统UI样式
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
    developer.log('系统UI样式设置完成: ${stopwatch.elapsedMilliseconds}ms');

    // 预加载音频配置
    await SoundConfigService().loadSoundConfig();
    developer.log('音频配置加载完成: ${stopwatch.elapsedMilliseconds}ms');

    // 预热音频引擎
    // final warmupPlayer = AudioPlayer();
    // try {
    //   // 使用最小的音频文件进行预热
    //   await warmupPlayer.setAsset('assets/sounds/wind.ogg');
    //   await warmupPlayer.setVolume(0); // 设置音量为0，避免播放声音
    //   await warmupPlayer.play();
    //   await warmupPlayer.stop();
    //   developer.log('音频引擎预热完成: ${stopwatch.elapsedMilliseconds}ms');
    // } catch (e) {
    //   developer.log('音频引擎预热失败: $e');
    // } finally {
    //   await warmupPlayer.dispose();
    // }
  } catch (e, stackTrace) {
    developer.log('应用初始化失败', error: e, stackTrace: stackTrace);
    rethrow;
  } finally {
    stopwatch.stop();
    developer.log('应用初始化总耗时: ${stopwatch.elapsedMilliseconds}ms');
  }
}

void main() async {
  // 捕获所有未处理的错误
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log(
      '未捕获的Flutter错误',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // 捕获所有未处理的异步错误
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      '未捕获的平台错误',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _initializeApp();
      if (mounted) {
        ref.read(initializationProvider.notifier).state = true;
      }
    } catch (e) {
      developer.log('初始化失败', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = ref.watch(initializationProvider);

    return MaterialApp(
      title: 'Sleepy Sounds',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          // 避免系统字体大小影响应用
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      home: isInitialized
          ? const HomeScreen()
          : const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '正在启动',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
