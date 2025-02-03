# Hypnetic

Hypnos + Hypnotic = Hypnetic, help you to sleep better.

## 项目架构

```
lib/
├── core/                     # 核心功能模块
│   ├── models/             # 核心数据模型
│   │   ├── audio_manager.dart     # 音频管理器
│   │   ├── stream_info.dart       # 流媒体信息
│   │   └── video_info.dart        # 视频信息
│   ├── providers/           # 全局状态管理
│   │   ├── timer_provider.dart      # 定时器状态管理
│   │   ├── audio_player_provider.dart # 音频播放器状态管理
│   │   └── video_provider.dart      # 视频播放状态管理
│   ├── services/           # 核心服务
│   │   ├── error/         # 错误处理
│   │   ├── video/         # 视频服务
│   │   └── audio/         # 音频服务
│   └── utils/             # 工具类
│       ├── constants.dart  # 常量定义
│       └── extensions.dart # 扩展方法
│
├── features/               # 功能模块
│   ├── audio/             # 音频相关功能
│   │   ├── models/       # 音频数据模型
│   │   ├── widgets/      # 音频相关组件
│   │   └── screens/      # 音频相关页面
│   └── video/            # 视频相关功能
│       ├── models/       # 视频数据模型
│       ├── widgets/      # 视频相关组件
│       └── screens/      # 视频相关页面
│
├── widgets/               # 通用组件
│   ├── common/           # 基础组件
│   │   ├── keep_alive_wrapper.dart # 保活包装器
│   │   └── loading_indicator.dart  # 加载指示器
│   ├── player/           # 播放器组件
│   │   ├── audio/        # 音频播放器
│   │   └── video/        # 视频播放器
│   └── skeleton/         # 骨架屏组件
│
├── l10n/                 # 国际化资源
│   └── arb/             # 语言文件
│
└── main.dart            # 应用入口文件
```

## 核心功能模块说明

### 状态管理 (Provider)

- **AudioPlayerProvider**: 音频播放器状态管理
  - 单例播放器实例管理
  - 音频源设置和切换
  - 播放状态控制
  - 音量调节
  - 资源释放管理

- **VideoProvider**: 视频播放状态管理
  - 视频信息管理
  - 播放列表控制
  - 搜索功能
  - 播放状态同步

- **TimerProvider**: 定时器状态管理
  - 定时器状态控制
  - 倒计时管理
  - 自动关闭功能
  - 状态持久化

### 主要功能模块

1. **音频播放模块**
   - 音频源管理
   - 播放控制
   - 进度条控制
   - 音量调节
   - 资源释放

2. **视频播放模块**
   - 视频列表管理
   - 视频信息获取
   - 播放控制
   - 进度显示
   - 错误处理

3. **定时器模块**
   - 倒计时功能
   - 自动停止播放
   - 状态持久化
   - 定时关闭应用

## 技术栈

- Flutter 3.19.0
- Riverpod 2.4.10 (状态管理)
- just_audio 0.9.36 (音频播放)
- just_audio_background 0.0.1-beta.11 (后台播放)
- video_player 2.9.2 (视频播放)

## 开发指南

1. **状态管理**
   - 使用 Riverpod 进行状态管理
   - 遵循单一职责原则
   - 确保状态同步和资源释放
   - 处理生命周期事件

2. **音频播放**
   - 使用单例播放器实例
   - 正确处理音频源切换
   - 管理播放状态和进度
   - 确保资源正确释放

3. **视频播放**
   - 管理视频列表和信息
   - 处理播放状态变化
   - 实现视频搜索功能
   - 错误处理和重试机制

4. **定时器功能**
   - 实现精确的倒计时
   - 处理后台运行状态
   - 保存和恢复定时设置
   - 确保正确退出应用

## 注意事项

1. 音频播放器使用单例模式，确保资源正确管理
2. 状态更新操作应在正确的生命周期中执行
3. 播放器状态变化需要同步更新 UI 和定时器
4. 确保在组件销毁时正确释放资源
5. 处理后台播放和前台切换的状态同步
6. 注意错误处理和用户体验优化


