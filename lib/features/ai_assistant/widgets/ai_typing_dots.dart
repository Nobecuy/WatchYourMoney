// Typing indicator dots for AI streaming response.

import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';

class AITypingDots extends StatefulWidget {
  const AITypingDots({super.key});

  @override
  State<AITypingDots> createState() => _AITypingDotsState();
}

class _AITypingDotsState extends State<AITypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.22;
            final raw = (_ctrl.value - delay) % 1.0;
            final v = raw.clamp(0.0, 1.0);
            final scale = 0.55 +
                0.45 * (1.0 - (v - 0.5).abs() * 2.0).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.positive.withValues(
                      alpha: 0.4 + 0.5 * scale,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}