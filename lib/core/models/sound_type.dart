// import 'package:flutter/material.dart';

// class SoundType {
//   final String id;
//   final String name;
//   final IconData icon;

//   const SoundType({
//     required this.id,
//     required this.name,
//     required this.icon,
//   });

//   factory SoundType.fromJson(Map<String, dynamic> json) {
//     return SoundType(
//       id: json['id'] as String,
//       name: json['name'] as String,
//       icon: _getIconData(json['icon'] as String),
//     );
//   }

//   static IconData _getIconData(String iconName) {
//     switch (iconName) {
//       case 'water_drop':
//         return Icons.water_drop;
//       case 'waves':
//         return Icons.waves;
//       case 'noise_aware':
//         return Icons.noise_aware;
//       case 'water':
//         return Icons.water;
//       case 'air':
//         return Icons.air;
//       default:
//         return Icons.music_note;
//     }
//   }
// }
