// Difference calculation preview widget for Adjust Balance modal.

import 'package:flutter/material.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletDifferencePreview extends ConsumerWidget {
  final double current;
  final double target;
  final CurrencyFormatter fmt;

  const WalletDifferencePreview({
    super.key,
    required this.current,
    required this.target,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final t = AppTranslations.of(settings.languageCode);

    final diff = target - current;

    if (diff == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                t.balanceUpdated,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isPositive = diff > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isPositive
              ? const Color(0x3310B981)
              : const Color(0x33F43F5E),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 16,
            color: isPositive ? AppColors.positive : AppColors.negativeLight,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isPositive
                  ? '${t.incomeAdjustment}: +${fmt.format(diff)}'
                  : '${t.expenseAdjustment}: -${fmt.format(diff.abs())}',
              style: TextStyle(
                color: isPositive ? AppColors.positive : AppColors.negativeLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}