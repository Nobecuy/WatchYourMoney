/// Pie chart widget for Statistics screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';
import 'package:watch_your_money/features/analytics/widgets/chart_data_service.dart';

class StatisticsPieChart extends ConsumerWidget {
  final List<CategoryDataPoint> categoryData;
  final AppTranslations t;

  const StatisticsPieChart({
    super.key,
    required this.categoryData,
    required this.t,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryData.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            t.noSpendingData,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return NeumorphicContainer(
      borderRadius: AppRadii.xxl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.spendingByCat,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 46,
                sections: categoryData.map((data) {
                  final pct = data.percentage.toStringAsFixed(0);
                  return PieChartSectionData(
                    value: data.amount,
                    color: data.color,
                    title: '$pct%',
                    radius: 46,
                    titleStyle: const TextStyle(
                      color: AppColors.accentWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: categoryData.map((data) {
              return _buildDotLegend(data.category, data.color);
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: AppDurations.normal, duration: AppDurations.slow);
  }

  Widget _buildDotLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}