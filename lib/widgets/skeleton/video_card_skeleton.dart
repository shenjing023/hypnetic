import 'package:flutter/material.dart';

class VideoCardSkeleton extends StatelessWidget {
  const VideoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 封面图骨架
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey[800]!,
                  Colors.grey[700]!,
                  Colors.grey[800]!,
                ],
                stops: const [0.1, 0.5, 0.9],
              ),
            ),
          ),
          // 信息区域骨架
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题骨架
                Container(
                  height: 16,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[700]!,
                        Colors.grey[800]!,
                      ],
                      stops: const [0.1, 0.5, 0.9],
                    ),
                  ),
                ),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[700]!,
                        Colors.grey[800]!,
                      ],
                      stops: const [0.1, 0.5, 0.9],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 作者和播放量骨架
                Row(
                  children: [
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.grey[800]!,
                            Colors.grey[700]!,
                            Colors.grey[800]!,
                          ],
                          stops: const [0.1, 0.5, 0.9],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.grey[800]!,
                            Colors.grey[700]!,
                            Colors.grey[800]!,
                          ],
                          stops: const [0.1, 0.5, 0.9],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
