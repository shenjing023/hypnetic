import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../core/providers/timer_provider.dart';
import '../../../core/providers/sound_provider.dart';
import 'timer_styles/timer_style.dart';
import 'timer_styles/circle_timer.dart';
import 'timer_styles/wave_timer.dart';
import 'timer_styles/starry_timer.dart';
import 'package:flutter/services.dart';

/// 定时器组件
class TimerWidget extends ConsumerStatefulWidget {
  const TimerWidget({super.key});

  @override
  ConsumerState<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends ConsumerState<TimerWidget> {
  late final TimerStyleType _selectedStyle;

  @override
  void initState() {
    super.initState();
    // 随机选择一个样式
    final styles = TimerStyleType.values;
    _selectedStyle = styles[math.Random().nextInt(styles.length)];
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);

    // 只有在定时器被设置过且倒计时结束时才退出应用
    if (timerState.duration.inSeconds > 0 &&
        timerState.remaining.inSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemNavigator.pop();
      });
      return const SizedBox.shrink();
    }
    // 监听定时器状态，处理音量渐弱
    else if (timerState.remaining.inSeconds <= 30) {
      final volumeRatio = timerState.remaining.inSeconds / 30;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(soundProvider.notifier).setGlobalVolume(volumeRatio);
      });
    }

    // 根据选择的样式返回对应的定时器
    switch (_selectedStyle) {
      case TimerStyleType.circle:
        return CircleTimer(
          timerState: timerState,
        );
      case TimerStyleType.wave:
        return WaveTimer(
          timerState: timerState,
        );
      case TimerStyleType.starry:
        return StarryTimer(
          timerState: timerState,
        );
    }
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
