/// Header widget for Statistics screen with period selector.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';

class StatisticsHeader extends ConsumerWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const StatisticsHeader({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final t = AppTranslations.of(settings.languageCode);

    final periods = [
      {'key': 'WEEK', 'label': t.weekLabel},
      {'key': 'MONTH', 'label': t.monthLabel},
      {'key': 'ALL', 'label': t.allLabel},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.analyticsTitle,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  t.analyticsSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Period Filter Selector using AppSegmentedControl
          NeumorphicContainer(
            isPressed: true,
            padding: const EdgeInsets.all(3),
            borderRadius: AppRadii.md,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: periods
                  .map((p) => _buildPeriodBtn(p['key']!, p['label']!))
                  .toList(),
            ),
          ),
        ],
      ).animate().fadeIn(duration: AppDurations.normal),
    );
  }

  Widget _buildPeriodBtn(String key, String label) {
    final active = selectedPeriod == key;
    return GestureDetector(
      onTap: () => onPeriodChanged(key),
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.accentWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accentBlack : AppColors.textMuted,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
