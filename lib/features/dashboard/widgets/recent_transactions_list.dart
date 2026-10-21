import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final CurrencyFormatter formatter;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length.clamp(0, 5),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == 'income';
        return NeumorphicContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 12,
              child: Row(
                children: [
                  Icon(
                    isIncome
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: isIncome
                        ? Colors.green
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      tx.note,
                      style: const TextStyle(color: AppColors.textColor),
                    ),
                  ),
                  Text(
                    formatter.format(tx.amount),
                    style: TextStyle(
                      color: isIncome
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: (index * 100).ms)
            .slideY(begin: 0.1, delay: (index * 100).ms);
      },
    );
  }
}
