// Current balance info card widget for Adjust Balance modal.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/widgets/app_card.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';

class WalletCurrentBalanceCard extends StatelessWidget {
  final String method; // 'card' | 'cash'
  final double currentBalance;
  final CurrencyFormatter fmt;

  const WalletCurrentBalanceCard({
    super.key,
    required this.method,
    required this.currentBalance,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final isCard = method == 'card';

    return AppInfoCard(
      label: 'SALDO SAAT INI DI APLIKASI',
      value: fmt.format(currentBalance),
      valueColor: currentBalance >= 0
          ? AppColors.textPrimary
          : AppColors.negativeLight,
      badgeText: isCard ? 'DOMPET KARTU' : 'DOMPOT KAS',
      badgeColor: isCard ? const Color(0xFF818CF8) : const Color(0xFF34D399),
    ).animate().fadeIn(duration: 200.ms);
  }
}