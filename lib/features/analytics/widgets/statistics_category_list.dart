/// Category breakdown list widget for Statistics screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';
import 'package:watch_your_money/features/analytics/widgets/chart_data_service.dart';

class StatisticsCategoryList extends ConsumerWidget {
  final List<CategoryDataPoint> categoryData;
  final double totalExpense;
  final CurrencyFormatter fmt;
  final AppTranslations t;

  const StatisticsCategoryList({
    super.key,
    required this.categoryData,
    required this.totalExpense,
    required this.fmt,
    required this.t,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryData.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: NeumorphicContainer(
        borderRadius: AppRadii.xxl,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    t.spendingDetail,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${categoryData.length} ${t.categoriesCount}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ...categoryData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index == categoryData.length - 1 ? 0 : AppSpacing.lg),
                child: _buildCategoryRow(data, fmt)
                    .animate()
                    .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                    .slideX(begin: 0.1, delay: (index * 50).ms, duration: 300.ms),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: AppDurations.slow, duration: AppDurations.slow);
  }

  Widget _buildCategoryRow(CategoryDataPoint data, CurrencyFormatter fmt) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      data.category,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fmt.format(data.amount),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '(${data.percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: data.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: data.percentage / 100,
            backgroundColor: AppColors.surfaceDim,
            valueColor: AlwaysStoppedAnimation<Color>(data.color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}