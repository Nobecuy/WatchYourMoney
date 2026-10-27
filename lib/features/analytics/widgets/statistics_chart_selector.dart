/// Chart type selector widget for Statistics screen (Bar/Pie).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/widgets/app_chip.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';

class StatisticsChartSelector extends ConsumerWidget {
  final String selectedChartType;
  final ValueChanged<String> onChartTypeChanged;

  const StatisticsChartSelector({
    super.key,
    required this.selectedChartType,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final t = AppTranslations.of(settings.languageCode);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              t.chartStats,
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
          // Using AppSegmentedControl for cleaner code
          AppSegmentedControl<String>(
            value: selectedChartType,
            segments: [
              AppSegment(
                value: 'BAR',
                label: 'Batang',
                icon: Icons.bar_chart_rounded,
              ),
              AppSegment(
                value: 'PIE',
                label: 'Lingkaran',
                icon: Icons.pie_chart_outline_rounded,
              ),
            ],
            onChanged: onChartTypeChanged,
            dense: true,
          ),
        ],
      ),
    );
  }
}