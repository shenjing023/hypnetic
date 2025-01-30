import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/sound_provider.dart';
import '../../../core/models/sound_model.dart';

/// 声音列表项组件
class SoundListItem extends StatelessWidget {
  final SoundModel sound;
  final VoidCallback onToggle;
  final Color? iconColor;

  const SoundListItem({
    super.key,
    required this.sound,
    required this.onToggle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        sound.type.icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        sound.name,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: IconButton(
        icon: Icon(
          sound.isPlaying ? Icons.pause : Icons.play_arrow,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        onPressed: onToggle,
      ),
    );
  }
}

/// 声音选择器组件
///
/// 显示可用的声音列表，并允许用户选择和控制声音的播放状态。
/// 支持：
/// - 显示声音列表
/// - 播放/暂停控制
/// - 自动处理声音冲突（同时只能播放一个声音）
class SoundSelector extends ConsumerWidget {
  const SoundSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sounds = ref.watch(soundProvider);

    if (sounds.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          Expanded(
            child: _buildSoundList(context, ref, sounds),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '选择声音',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }

  Widget _buildSoundList(
      BuildContext context, WidgetRef ref, List<SoundModel> sounds) {
    return ListView.builder(
      itemCount: sounds.length,
      itemBuilder: (context, index) {
        final sound = sounds[index];
        return SoundListItem(
          sound: sound,
          onToggle: () => _handleSoundToggle(ref, sound, sounds),
          iconColor: Theme.of(context).colorScheme.primary,
        );
      },
    );
  }

  void _handleSoundToggle(
      WidgetRef ref, SoundModel sound, List<SoundModel> sounds) {
    // 如果有其他声音在播放，先停止它
    final playingSound = sounds.where((s) => s.isPlaying).firstOrNull;
    if (playingSound != null && playingSound.id != sound.id) {
      ref.read(soundProvider.notifier).toggleSound(playingSound.id);
    }
    ref.read(soundProvider.notifier).toggleSound(sound.id);
  }
}
