import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hypnetic/features/audio/screens/video_page.dart';

/// 主屏幕
///
/// 使用 [ConsumerStatefulWidget] 以支持状态管理和依赖注入
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0; // 当前选中的导航项

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            // 视频页面
            const HomePage(),
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
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          border: Border(
            top: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // _buildNavItem(context, Icons.music_note, 0),
            _buildNavItem(context, Icons.music_note, 0),
            _buildNavItem(context, Icons.settings, 1),
          ],
        ),
      ),
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
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
