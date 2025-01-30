import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timer_provider.dart';

final playStateProvider = StateNotifierProvider<PlayStateNotifier, bool>((ref) {
  return PlayStateNotifier(ref);
});

class PlayStateNotifier extends StateNotifier<bool> {
  final Ref _ref;

  PlayStateNotifier(this._ref) : super(false);

  void play() {
    state = true;
    // 如果定时器有剩余时间，启动定时器
    final timerState = _ref.read(timerProvider);
    if (timerState.remaining.inSeconds > 0) {
      _ref.read(timerProvider.notifier).start();
    }
  }

  void pause() {
    state = false;
    // 暂停定时器
    final timerState = _ref.read(timerProvider);
    if (timerState.isRunning) {
      _ref.read(timerProvider.notifier).pause();
    }
  }

  void toggle() {
    if (state) {
      pause();
    } else {
      play();
    }
  }
}
