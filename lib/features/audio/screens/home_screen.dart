import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../../core/providers/sound_provider.dart';
import '../../../core/providers/timer_provider.dart';
import '../widgets/timer_widget.dart';
import '../widgets/sound_mixer.dart';
import 'dart:math';
import '../../../core/models/sound_model.dart';
import '../../video/screens/video_screen.dart';

/// 主屏幕
///
/// 使用 [ConsumerStatefulWidget] 以支持状态管理和依赖注入
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _hours = 0;
  int _minutes = 30;
  bool _isInitialized = false;
  int _selectedIndex = 0; // 当前选中的导航项

  // 缓存当前播放的声音
  SoundModel? _currentSound;
  // 缓存图标组件
  late final Map<String, Icon> _cachedIcons = {};

  @override
  void initState() {
    super.initState();
    // 使用 microtask 延迟初始化，避免阻塞UI
    Future.microtask(() async {
      try {
        await ref.read(soundProvider.notifier).initializeSounds();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        developer.log('声音初始化失败', error: e);
        // 显示错误提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('加载声音失败，请重试'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  // 获取或创建缓存的图标
  Icon _getIconForSound(SoundModel sound, BuildContext context) {
    return _cachedIcons.putIfAbsent(
      sound.id,
      () => Icon(
        sound.type.icon,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _handlePlayButtonPress(String soundId) {
    ref.read(soundProvider.notifier).toggleSound(soundId);
  }

  void _showTimePickerDialog() {
    final sounds = ref.read(soundProvider);
    final hasPlayingSound = sounds.any((sound) => sound.isPlaying);

    showDialog(
      context: context,
      builder: (context) => _buildTimePickerDialog(hasPlayingSound),
    );
  }

  Widget _buildTimePickerDialog(bool hasPlayingSound) {
    return AlertDialog(
      title: const Text('设置定时'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeOption('15分钟', 15, hasPlayingSound),
          _buildTimeOption('30分钟', 30, hasPlayingSound),
          _buildTimeOption('60分钟', 60, hasPlayingSound),
          ListTile(
            title: const Text('自定义时间'),
            onTap: () {
              Navigator.pop(context);
              _showCustomTimePicker(hasPlayingSound);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(String label, int minutes, bool hasPlayingSound) {
    return ListTile(
      title: Text(label),
      onTap: () {
        ref.read(timerProvider.notifier).setDuration(
              Duration(minutes: minutes),
            );
        if (hasPlayingSound) {
          ref.read(timerProvider.notifier).start();
        }
        Navigator.pop(context);
      },
    );
  }

  void _showCustomTimePicker(bool hasPlayingSound) {
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
                    onChanged: (hours) => setState(() => _hours = hours),
                  ),
                  const SizedBox(width: 16),
                  _TimePickerSpinner(
                    maxValue: 59,
                    label: '分钟',
                    onChanged: (minutes) => setState(() => _minutes = minutes),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _handleCustomTimeSet(hasPlayingSound),
                child: const Text('确定'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCustomTimeSet(bool hasPlayingSound) {
    final duration = Duration(
      hours: _hours,
      minutes: _minutes,
    );
    if (duration.inMinutes > 0) {
      ref.read(timerProvider.notifier).setDuration(duration);
      if (hasPlayingSound) {
        ref.read(timerProvider.notifier).start();
      }
    }
    Navigator.pop(context);
  }

  void _shuffleSound() {
    final sounds = ref.read(soundProvider);
    if (sounds.isEmpty) return;

    final notPlayingSounds = sounds.where((s) => !s.isPlaying).toList();
    if (notPlayingSounds.isEmpty) {
      // 如果所有声音都在播放，则随机停止一些声音
      for (var sound in sounds) {
        if (sound.isPlaying && Random().nextBool()) {
          ref.read(soundProvider.notifier).toggleSound(sound.id);
        }
      }
    } else {
      // 随机播放一个未播放的声音
      final randomSound =
          notPlayingSounds[Random().nextInt(notPlayingSounds.length)];
      ref.read(soundProvider.notifier).toggleSound(randomSound.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                '加载声音中...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sounds = ref.watch(soundProvider);
    final timerState = ref.watch(timerProvider);

    // 更新缓存的当前声音
    _currentSound = sounds.isEmpty
        ? null
        : sounds.where((sound) => sound.isPlaying).firstOrNull ?? sounds.first;

    return _buildScaffold(context, _currentSound, timerState);
  }

  Widget _buildScaffold(
      BuildContext context, SoundModel? sound, TimerState timerState) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            // 声音页面
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Sleepy Sounds',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  const Expanded(
                    flex: 2,
                    child: TimerWidget(),
                  ),
                  if (sound != null) ...[
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: () => _showSoundSelector(context),
                      child: _getIconForSound(sound, context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sound.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildControlButtons(context, sound),
                    const SizedBox(height: 20),
                  ],
                  const Spacer(),
                ],
              ),
            ),
            // 视频页面
            const VideoScreen(),
            // 设置页面（待实现）
            const Center(
              child: Text('设置功能即将推出'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, Icons.music_note, 0),
            _buildNavItem(context, Icons.video_library, 1),
            _buildNavItem(context, Icons.settings, 2),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, SoundModel sound) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            ref
                    .watch(soundProvider)
                    .firstWhere((s) => s.id == sound.id)
                    .isPlaying
                ? Icons.pause
                : Icons.play_arrow,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => _handlePlayButtonPress(sound.id),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            Icons.shuffle,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _shuffleSound,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            Icons.timer,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _showTimePickerDialog,
        ),
      ],
    );
  }

  void _showSoundSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const SoundSelector(),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index) {
    final isSelected = index == _selectedIndex;
    return IconButton(
      icon: Icon(
        icon,
        size: 28,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.5),
      ),
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
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
    _controller = FixedExtentScrollController();
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
                widget.onChanged(index);
              });
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
