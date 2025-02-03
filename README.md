# Hypnetic

Hypnos + Hypnotic = Hypnetic, help you to sleep better.

## 项目架构

```
lib/
├── core/                     # 核心功能模块
│   ├── providers/           # 全局状态管理
│   │   ├── timer_provider.dart      # 定时器状态管理
│   │   ├── audio_player_provider.dart # 音频播放器状态管理
│   │   └── video_provider.dart      # 视频播放状态管理
│   ├── services/           # 核心服务
│   └── utils/             # 工具类
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
│   └── player/           # 播放器组件
│
├── l10n/                 # 国际化资源
│   └── arb/             # 语言文件
│
└── main.dart            # 应用入口文件
```

## 核心功能模块说明

### 状态管理 (Provider)

- **TimerNotifier**: 定时器状态管理
  - 控制定时器的启动、暂停、重置
  - 管理定时器来源（本地音频/轻松助眠）
  - 实现音频淡出效果
  - 自动退出应用功能

- **AudioPlayerProvider**: 音频播放器状态管理
  - 音频播放控制
  - 音量调节
  - 播放状态监听

- **VideoProvider**: 视频播放状态管理
  - 视频播放控制
  - 播放列表管理
  - 播放状态同步

### 主要功能模块

1. **音频播放模块**
   - 本地音频播放
   - 音量渐变控制
   - 定时停止功能

2. **视频播放模块**
   - 视频流播放
   - 播放列表管理
   - 播放状态控制

3. **定时器模块**
   - 倒计时功能
   - 自动停止播放
   - 音量渐弱效果
   - 定时关闭应用

## 技术栈

- Flutter
- Riverpod (状态管理)
- just_audio (音频播放)
- video_player (视频播放)

## 开发指南

1. **状态管理**
   - 使用Riverpod进行状态管理
   - 遵循单一职责原则
   - 保持状态同步

2. **音频播放**
   - 使用just_audio处理音频播放
   - 实现音量渐变效果
   - 处理播放状态变化

3. **视频播放**
   - 使用video_player处理视频播放
   - 管理播放列表
   - 同步播放状态

4. **定时器功能**
   - 实现精确的倒计时
   - 处理后台运行
   - 确保正确退出应用

## 注意事项

1. 所有状态更新操作应使用`Future.microtask`确保在正确的时机执行
2. 播放器状态变化需要同步更新定时器状态
3. 退出应用时需要正确释放所有资源
4. 确保在后台运行时正常工作


