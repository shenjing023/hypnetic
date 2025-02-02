import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hypnetic/core/providers/video_provider.dart';
import 'package:hypnetic/widgets/skeleton/video_card_skeleton.dart';
import 'package:hypnetic/widgets/skeleton/shimmer_loading.dart';
import 'package:hypnetic/core/services/error/app_error.dart';
import 'package:hypnetic/core/services/video/video_service_manager.dart';
import 'package:hypnetic/core/models/video_info.dart';
import 'package:hypnetic/widgets/player/audio/audio_player_widget.dart';
import 'package:hypnetic/widgets/common/keep_alive_wrapper.dart';
import 'package:hypnetic/core/providers/timer_provider.dart';

/// 页面常量配置
class _HomePageConfig {
  static const double cardElevation = 4.0;
  static const double cardBorderRadius = 16.0;
  static const double coverHeight = 200.0;
  static const double progressBarHeight = 10.0;
  static const double titleFontSize = 16.0;
  static const double authorFontSize = 14.0;
  static const double playCountFontSize = 12.0;
  static const double cardMarginBottom = 16.0;
  static const double contentPadding = 12.0;
  static const Duration switchDuration = Duration(milliseconds: 300);
  static const Duration playerUpdateDelay = Duration(milliseconds: 100);
}

/// 主页面
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // 视频服务管理器
  final _videoManager = VideoServiceManager.instance;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// 初始化数据
  void _initializeData() {
    _videoManager.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoStateProvider.notifier).searchVideos('助眠音乐');
    });
  }

  /// 播放视频
  Future<void> _playVideo(VideoInfo video) async {
    final currentVideo = ref.read(currentVideoProvider);
    final streamState = ref.read(streamStateProvider);

    // 如果正在播放同一个视频，则不重复加载
    if (currentVideo?.id == video.id && streamState.hasValue) {
      _togglePlayPause();
      return;
    }

    // 2. 重置播放状态
    ref.read(playbackStateProvider.notifier).reset();
    await Future.delayed(_HomePageConfig.playerUpdateDelay);

    // 3. 设置当前视频并加载
    ref.read(currentVideoProvider.notifier).setCurrentVideo(video);
    try {
      await ref.read(streamStateProvider.notifier).loadStreamInfo(video.id);
      ref.read(playbackStateProvider.notifier).setPlaying(true);

      // 4. 处理定时器
      final timerState = ref.read(timerProvider);
      if (timerState.duration.inSeconds == 0) {
        // 如果没有设置定时器，设置默认15分钟
        ref.read(timerProvider.notifier).setDuration(
              const Duration(minutes: 15),
            );
      }
      ref.read(timerProvider.notifier).start();
    } catch (e) {
      _handlePlayError(e);
    }
  }

  /// 处理播放错误
  void _handlePlayError(dynamic error) {
    ref.read(currentVideoProvider.notifier).clear();
    ref.read(streamStateProvider.notifier).clear();
    ref.read(playbackStateProvider.notifier).reset();

    final appError = ErrorHandler.handle(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('播放失败: ${appError.message}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 切换播放/暂停状态
  void _togglePlayPause() {
    final currentVideo = ref.read(currentVideoProvider);
    final streamState = ref.read(streamStateProvider);
    final playbackState = ref.read(playbackStateProvider);

    if (currentVideo != null && streamState.hasValue) {
      final willPlay = !playbackState.isPlaying;
      ref.read(playbackStateProvider.notifier).setPlaying(willPlay);

      // 处理定时器状态
      // if (willPlay) {
      //   // 如果要开始播放，先停止所有音频
      //   final sounds = ref.read(soundProvider);
      //   for (var sound in sounds.where((s) => s.isPlaying)) {
      //     ref.read(soundProvider.notifier).toggleSound(sound.id);
      //   }
      //   ref.read(timerProvider.notifier).start();
      // } else {
      //   ref.read(timerProvider.notifier).pause();
      // }
    }
  }

  /// 格式化数字（将大于10000的数字转换为万单位）
  String _formatCount(int? count) {
    if (count == null) return '0';
    if (count > 10000) {
      final double wan = count / 10000;
      return '${wan > 10 ? wan.toStringAsFixed(0) : wan.toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  /// 构建视频卡片
  Widget _buildVideoCard(VideoInfo video) {
    final currentVideo = ref.watch(currentVideoProvider);
    final isSelected = currentVideo?.id == video.id;

    return RepaintBoundary(
      child: KeepAliveWrapper(
        keepAlive: isSelected, // 只保持当前播放的视频卡片存活
        child: Card(
          key: ValueKey(video.id),
          margin:
              const EdgeInsets.only(bottom: _HomePageConfig.cardMarginBottom),
          elevation: _HomePageConfig.cardElevation,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(_HomePageConfig.cardBorderRadius),
          ),
          color: Colors.black87,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVideoPreview(video, isSelected),
              _buildVideoInfo(video),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建视频预览部分
  Widget _buildVideoPreview(VideoInfo video, bool isSelected) {
    return Stack(
      children: [
        // 视频封面图
        _buildVideoCover(video),
        // 播放控制层
        _buildPlayControls(video, isSelected),
        // 时长显示
        _buildDurationDisplay(video),
        // 进度条
        if (isSelected) _buildProgressBar(),
      ],
    );
  }

  /// 构建视频封面
  Widget _buildVideoCover(VideoInfo video) {
    return Image.network(
      video.cover,
      height: _HomePageConfig.coverHeight,
      width: MediaQuery.of(context).size.width,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: _HomePageConfig.switchDuration,
          child: frame != null
              ? child
              : Container(
                  height: _HomePageConfig.coverHeight,
                  color: Colors.black12,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
        );
      },
    );
  }

  /// 构建播放控制层
  Widget _buildPlayControls(VideoInfo video, bool isSelected) {
    final streamState = ref.watch(streamStateProvider);
    final playbackState = ref.watch(playbackStateProvider);

    return Positioned.fill(
      child: Stack(
        children: [
          // 半透明黑色背景
          Container(
            color: isSelected ? Colors.transparent : Colors.black38,
          ),
          // 播放/暂停按钮
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _playVideo(video),
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black38,
                  ),
                  child: Icon(
                    isSelected && streamState.hasValue
                        ? (playbackState.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow)
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建时长显示
  Widget _buildDurationDisplay(VideoInfo video) {
    final currentVideo = ref.watch(currentVideoProvider);
    final playbackState = ref.watch(playbackStateProvider);
    final isSelected = currentVideo?.id == video.id;

    final duration =
        isSelected ? video.duration - playbackState.position : video.duration;

    return Positioned(
      right: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatDuration(duration),
          style: const TextStyle(
            color: Colors.white,
            fontSize: _HomePageConfig.playCountFontSize,
          ),
        ),
      ),
    );
  }

  /// 构建进度条
  Widget _buildProgressBar() {
    final streamState = ref.watch(streamStateProvider);
    final playbackState = ref.watch(playbackStateProvider);

    if (!streamState.hasValue || streamState.value == null)
      return const SizedBox();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: _HomePageConfig.progressBarHeight,
      child: Container(
        color: Colors.black38,
        child: AudioPlayerWidget(
          streamInfo: streamState.value!,
          isPlaying: playbackState.isPlaying,
          onPositionChanged: (position) {
            ref.read(playbackStateProvider.notifier).setPosition(position);
          },
        ),
      ),
    );
  }

  /// 构建视频信息
  Widget _buildVideoInfo(VideoInfo video) {
    return Padding(
      padding: const EdgeInsets.all(_HomePageConfig.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: _HomePageConfig.titleFontSize,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  video.author,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: _HomePageConfig.authorFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.play_circle_outline,
                color: Colors.grey.shade400,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(video.playCount),
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: _HomePageConfig.playCountFontSize,
                ),
              ),
              if (video.platform != _videoManager.currentService.platform)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.platform.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建加载状态界面
  Widget _buildLoadingState() {
    return ShimmerLoading(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(_HomePageConfig.contentPadding),
        itemCount: 5,
        itemBuilder: (context, index) => const VideoCardSkeleton(),
      ),
    );
  }

  /// 构建错误状态界面
  Widget _buildErrorState(AppError error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            error.message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(videoStateProvider.notifier).searchVideos('助眠音乐');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建视频列表界面
  Widget _buildVideoList() {
    final videoState = ref.watch(videoStateProvider);

    return videoState.when(
      data: (videos) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.purple.shade900.withOpacity(0.8),
                Colors.purple.shade900,
              ],
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(videoStateProvider.notifier)
                    .searchVideos('助眠音乐');
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                cacheExtent: 1000,
                slivers: [
                  SliverPadding(
                    padding:
                        const EdgeInsets.all(_HomePageConfig.contentPadding),
                    sliver: SliverList.builder(
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        return _buildVideoCard(videos[index]);
                      },
                    ),
                  ),
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error as AppError),
    );
  }

  /// 构建平台选择菜单
  Widget _buildPlatformMenu() {
    final platforms = _videoManager.supportedPlatforms;
    if (platforms.length <= 1) return const SizedBox();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (platform) {
        if (platform != _videoManager.currentService.platform) {
          ref.read(currentVideoProvider.notifier).clear();
          ref.read(streamStateProvider.notifier).clear();
          ref.read(playbackStateProvider.notifier).reset();
          _videoManager.setCurrentService(platform);
          ref.read(videoStateProvider.notifier).searchVideos('助眠音乐');
        }
      },
      itemBuilder: (context) => platforms.map((platform) {
        final isSelected = platform == _videoManager.currentService.platform;
        return PopupMenuItem<String>(
          value: platform,
          child: Row(
            children: [
              if (isSelected)
                const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.green,
                )
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(platform.toUpperCase()),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('轻松助眠'),
        elevation: 0,
        backgroundColor: Colors.purple.shade900,
        actions: [
          _buildTimerButton(context),
          _buildPlatformMenu(),
        ],
      ),
      body: _buildVideoList(),
    );
  }

  Widget _buildTimerButton(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final shouldShowTimer = timerState.source == TimerSource.homePage ||
        timerState.source == TimerSource.none;

    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.timer),
          if (shouldShowTimer && timerState.duration.inSeconds > 0) ...[
            CircularProgressIndicator(
              value: timerState.progress,
              strokeWidth: 2,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
            if (timerState.remaining.inMinutes > 0)
              Positioned(
                bottom: 10,
                child: Text(
                  '${timerState.remaining.inMinutes}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
          ],
        ],
      ),
      onPressed: _showTimerDialog,
    );
  }

  void _showTimerDialog() {
    // 检查是否有视频正在播放
    final playbackState = ref.read(playbackStateProvider);
    final hasPlayingVideo = playbackState.isPlaying;

    showDialog(
      context: context,
      builder: (context) => _buildTimerPickerDialog(hasPlayingVideo),
    );
  }

  Widget _buildTimerPickerDialog(bool hasPlayingVideo) {
    return AlertDialog(
      title: const Text('设置定时'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeOption('15分钟', 15, hasPlayingVideo),
          _buildTimeOption('30分钟', 30, hasPlayingVideo),
          _buildTimeOption('60分钟', 60, hasPlayingVideo),
          ListTile(
            title: const Text('自定义时间'),
            onTap: () {
              Navigator.pop(context);
              _showCustomTimePicker(hasPlayingVideo);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(String label, int minutes, bool hasPlayingVideo) {
    return ListTile(
      title: Text(label),
      onTap: () {
        // 重新检查播放状态
        final playbackState = ref.read(playbackStateProvider);
        final isPlaying = playbackState.isPlaying;

        ref.read(timerProvider.notifier).setDuration(
              Duration(minutes: minutes),
            );
        if (isPlaying) {
          ref.read(timerProvider.notifier).start();
        }
        Navigator.pop(context);
      },
    );
  }

  void _showCustomTimePicker(bool hasPlayingVideo) {
    int hours = 0;
    int minutes = 30;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义时间'),
        content: SizedBox(
          height: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimePickerSpinner(
                    maxValue: 23,
                    label: '小时',
                    onChanged: (value) => hours = value,
                  ),
                  const SizedBox(width: 16),
                  _TimePickerSpinner(
                    maxValue: 59,
                    label: '分钟',
                    onChanged: (value) => minutes = value,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final duration = Duration(
                    hours: hours,
                    minutes: minutes,
                  );
                  if (duration.inMinutes > 0) {
                    // 重新检查播放状态
                    final playbackState = ref.read(playbackStateProvider);
                    final isPlaying = playbackState.isPlaying;

                    ref.read(timerProvider.notifier).setDuration(duration);
                    if (isPlaying) {
                      ref.read(timerProvider.notifier).start();
                    }
                  }
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePickerSpinner extends StatefulWidget {
  final int maxValue;
  final String label;
  final ValueChanged<int> onChanged;

  const _TimePickerSpinner({
    required this.maxValue,
    required this.label,
    required this.onChanged,
  });

  @override
  _TimePickerSpinnerState createState() => _TimePickerSpinnerState();
}

class _TimePickerSpinnerState extends State<_TimePickerSpinner> {
  late final FixedExtentScrollController _controller;
  int _selectedValue = 0;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.label == '分钟' ? 30 : 0;
    _controller = FixedExtentScrollController(initialItem: _selectedValue);
    // 使用 addPostFrameCallback 确保在构建完成后再通知父组件
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(_selectedValue);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          width: 60,
          child: ListWheelScrollView(
            controller: _controller,
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedValue = index;
              });
              widget.onChanged(index);
            },
            children: List.generate(
              widget.maxValue + 1,
              (index) => Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: _selectedValue == index ? 20 : 16,
                    fontWeight: _selectedValue == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
