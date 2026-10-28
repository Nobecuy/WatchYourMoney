/// Summary cards widget for Statistics screen (Income/Expense).
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';

class StatisticsSummaryCards extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final CurrencyFormatter fmt;
  final AppTranslations t;

  const StatisticsSummaryCards({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.fmt,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child:
          Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      label: t.income.toUpperCase(),
                      amount: totalIncome,
                      color: AppColors.positive,
                      icon: Icons.arrow_downward_rounded,
                      fmt: fmt,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildSummaryCard(
                      label: t.expense.toUpperCase(),
                      amount: totalExpense,
                      color: AppColors.negative,
                      icon: Icons.arrow_upward_rounded,
                      fmt: fmt,
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: AppDurations.fast, duration: AppDurations.slow)
              .slideY(begin: 0.1),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required CurrencyFormatter fmt,
  }) {
    return NeumorphicContainer(
      borderRadius: AppRadii.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            fmt.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
