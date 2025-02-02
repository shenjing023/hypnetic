// import 'sound_type.dart';
// import 'audio_manager.dart';

// class SoundModel {
//   final String id;
//   final SoundType type;
//   final String assetPath;
//   final bool isPlaying;

//   const SoundModel({
//     required this.id,
//     required this.type,
//     required this.assetPath,
//     this.isPlaying = false,
//   });

//   factory SoundModel.fromJson(Map<String, dynamic> json) {
//     return SoundModel(
//       id: json['id'] as String,
//       type: SoundType.fromJson(json),
//       assetPath: json['assetPath'] as String,
//     );
//   }

//   SoundModel copyWith({
//     String? id,
//     SoundType? type,
//     String? assetPath,
//     bool? isPlaying,
//   }) {
//     return SoundModel(
//       id: id ?? this.id,
//       type: type ?? this.type,
//       assetPath: assetPath ?? this.assetPath,
//       isPlaying: isPlaying ?? this.isPlaying,
//     );
//   }

//   String get name => type.name;

//   Future<void> loadAudio() async {
//     try {
//       await AudioManager().loadAudio(id, assetPath);
//     } catch (e) {
//       print('加载音频出错: $e');
//       rethrow;
//     }
//   }
// }
