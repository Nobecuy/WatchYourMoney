// AI Assistant input widget for developer mode.

import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';

class AIInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final bool isStreaming;
  final VoidCallback onSend;
  final ValueChanged<String> onSubmitted;

  const AIInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.isStreaming,
    required this.onSend,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasText && !isStreaming) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasText
                      ? AppColors.positive.withValues(alpha: 0.35)
                      : const Color(0x10FFFFFF),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !isStreaming,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: isStreaming
                            ? 'Memproses...'
                            : 'Tanya Noir tentang keuanganmu...',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: isStreaming ? null : onSubmitted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: (hasText && !isStreaming) ? onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (hasText && !isStreaming)
                    ? AppColors.positive
                    : AppColors.surfaceContainerHigh,
                boxShadow: (hasText && !isStreaming)
                    ? [
                        BoxShadow(
                          color: AppColors.positive.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isStreaming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: AppColors.positive,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: (hasText && !isStreaming)
                            ? Colors.black
                            : AppColors.textMuted,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}