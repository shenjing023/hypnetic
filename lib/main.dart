import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'core/theme/app_theme.dart';
import 'features/audio/screens/home_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/network/network_state.dart';
import 'core/services/cache/audio_cache_manager.dart';
import 'core/services/video/video_service_manager.dart';

/// 应用初始化状态
final initializationProvider = StateProvider<bool>((ref) => false);

/// 应用启动初始化
Future<void> _initializeApp() async {
  final stopwatch = Stopwatch()..start();

  try {
    // 确保Flutter绑定初始化
    WidgetsFlutterBinding.ensureInitialized();

    // 初始化各个服务
    await Future.wait([
      NetworkState.instance.initialize(),
      AudioCacheManager.instance.initialize(),
    ]);

    // 初始化视频服务管理器
    VideoServiceManager.instance.initialize();

    // 设置首选方向为竖屏
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 设置系统UI样式
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  } catch (e, stackTrace) {
    // 记录关键错误，这个错误日志需要保留
    developer.log('应用初始化失败', error: e, stackTrace: stackTrace);
    rethrow;
  } finally {
    stopwatch.stop();
    if (kDebugMode) {
      developer.log('应用初始化总耗时: ${stopwatch.elapsedMilliseconds}ms');
    }
  }
}

void main() async {
  // 捕获所有未处理的错误
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 保留关键错误日志
    developer.log(
      '未捕获的Flutter错误',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // 捕获所有未处理的异步错误
  PlatformDispatcher.instance.onError = (error, stack) {
    // 保留关键错误日志
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
      if (kDebugMode) {
        developer.log('初始化失败', error: e);
      }
      // TODO: 在生产环境中显示用户友好的错误提示
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = ref.watch(initializationProvider);

    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Sleepy Sounds',
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          // 避免系统字体大小影响应用
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
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
