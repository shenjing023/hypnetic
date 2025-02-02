import 'package:flutter/material.dart';

class CountdownWidget extends StatefulWidget {
  final Duration duration;
  final Duration position;

  const CountdownWidget({
    super.key,
    required this.duration,
    required this.position,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
  }

  @override
  void didUpdateWidget(CountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _updateRemainingTime();
    }
  }

  void _updateRemainingTime() {
    _remainingTime = widget.duration - widget.position;
    if (_remainingTime.isNegative) {
      _remainingTime = Duration.zero;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_remainingTime),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    );
  }
}
