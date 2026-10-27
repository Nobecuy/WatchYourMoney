// Wallet method selector widget (Card vs Cash).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/widgets/app_chip.dart';

class WalletMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;

  const WalletMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppSegmentedControl<String>(
      value: selectedMethod,
      segments: [
        AppSegment(
          value: 'card',
          label: 'Kartu / Kredit',
          icon: Icons.credit_card_rounded,
        ),
        AppSegment(
          value: 'cash',
          label: 'Uang Tunai',
          icon: Icons.payments_rounded,
        ),
      ],
      onChanged: onMethodChanged,
      dense: false,
    ).animate().fadeIn(duration: 200.ms);
  }
}