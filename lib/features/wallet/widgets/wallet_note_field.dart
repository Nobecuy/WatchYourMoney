// Note field widget for Adjust Balance modal.

import 'package:flutter/material.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/widgets/app_card.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletNoteField extends ConsumerWidget {
  final TextEditingController controller;

  const WalletNoteField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final t = AppTranslations.of(settings.languageCode);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      borderRadius: AppRadii.pill,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: t.adjustmentNoteHint,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
          border: InputBorder.none,
          icon: const Icon(
            Icons.edit_note_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}