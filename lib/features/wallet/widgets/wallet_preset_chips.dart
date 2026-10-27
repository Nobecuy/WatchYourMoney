// Preset chips widget for quick amount selection in Adjust Balance modal.

import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/widgets/app_chip.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';

class WalletPresetChips extends StatelessWidget {
  final double currentBalance;
  final TextEditingController controller;
  final CurrencyFormatter fmt;

  const WalletPresetChips({
    super.key,
    required this.currentBalance,
    required this.controller,
    required this.fmt,
  });

  static List<(String, double Function(double))> getPresets(double current) {
    return [
      ('Set ke 0', (_) => 0),
      ('+100rb', (c) => c + 100000),
      ('+500rb', (c) => c + 500000),
      ('+1jt', (c) => c + 1000000),
      ('+5jt', (c) => c + 5000000),
    ];
  }

  void _applyPreset(double value) {
    final amountText = value.toInt().toString();
    if (amountText.isNotEmpty) {
      final formatted = ThousandsSeparatorInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: amountText),
      );
      controller.text = formatted.text;
      controller.selection = formatted.selection;
    } else {
      controller.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = getPresets(currentBalance);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: presets.map((preset) {
            final (label, calculator) = preset;
            final value = calculator(currentBalance);
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppChip(
                label: label,
                onTap: () => _applyPreset(value),
                unselectedColor: AppColors.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}