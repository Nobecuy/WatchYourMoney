// AI Assistant screen header widget.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';

class AIHeader extends StatelessWidget {
  final bool isDev;
  final bool isOllamaHealthy;
  final bool hasMessages;
  final AnimationController pulseController;
  final VoidCallback onBackPressed;
  final VoidCallback onClearChat;

  const AIHeader({
    super.key,
    required this.isDev,
    required this.isOllamaHealthy,
    required this.hasMessages,
    required this.pulseController,
    required this.onBackPressed,
    required this.onClearChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0CFFFFFF), width: 1)),
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop()) ...[
            GestureDetector(
              onTap: onBackPressed,
              child: const NeumorphicContainer(
                width: 36,
                height: 36,
                borderRadius: 10,
                padding: EdgeInsets.zero,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final glow = 0.3 + 0.2 * pulseController.value;
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.positive.withValues(alpha: glow),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.positive,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Noir AI',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildStatusBadge(),
                  ],
                ),
                Text(
                  isDev && isOllamaHealthy
                      ? 'Ollama aktif - mode lanjut'
                      : 'Analisis lokal - tanpa internet',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (hasMessages)
            GestureDetector(
              onTap: onClearChat,
              child: const NeumorphicContainer(
                width: 36,
                height: 36,
                borderRadius: 10,
                padding: EdgeInsets.zero,
                child: Center(
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildStatusBadge() {
    final online = isDev && isOllamaHealthy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: online
            ? AppColors.positive.withValues(alpha: 0.12)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: online
              ? AppColors.positive.withValues(alpha: 0.3)
              : const Color(0x10FFFFFF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? AppColors.positive : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            online ? 'ONLINE' : 'LOCAL',
            style: TextStyle(
              color: online ? AppColors.positive : AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}