import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<TransactionModel> transactions;

  const RecentTransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length.clamp(0, 5),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return NeumorphicContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 12,
          child: Row(
            children: [
              Icon(tx.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward, 
                   color: tx.type == 'income' ? Colors.green : Colors.redAccent),
              const SizedBox(width: 15),
              Expanded(child: Text(tx.note, style: const TextStyle(color: AppColors.textColor))),
              Text(CurrencyFormatter.format(tx.amount), 
                   style: TextStyle(color: tx.type == 'income' ? Colors.green : Colors.redAccent)),
            ],
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, delay: (index * 100).ms);
      },
    );
  }
}
