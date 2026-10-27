// AI chat bubble widget for rendering user and AI messages.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_chat_formatter.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_chat_message.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_typing_dots.dart';

class AIChatBubble extends StatelessWidget {
  final AIChatMessage message;
  final int index;

  const AIChatBubble({
    super.key,
    required this.message,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    if (!message.isAI) {
      return _buildUserBubble(context);
    }
    return _buildAIBubble(context);
  }

  Widget _buildUserBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      )
          .animate()
          .fadeIn(delay: (index * 20).ms, duration: 200.ms)
          .slideX(begin: 0.05),
    );
  }

  Widget _buildAIBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.positive.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.positive,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Noir',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16, right: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: message.isStreaming
                  ? AppColors.surfaceContainerLow
                  : AppColors.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: message.isStreaming
                    ? AppColors.positive.withValues(alpha: 0.18)
                    : const Color(0x0AFFFFFF),
              ),
            ),
            child: message.isStreaming && message.text.isEmpty
                ? const AITypingDots()
                : AIChatFormatter.buildFormattedText(message.text),
          ),
        ],
      )
          .animate()
          .fadeIn(delay: (index * 20).ms, duration: 200.ms)
          .slideX(begin: -0.04),
    );
  }
}