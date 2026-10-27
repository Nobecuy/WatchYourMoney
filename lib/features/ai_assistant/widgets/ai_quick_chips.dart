// AI quick chips widget for preset analysis shortcuts.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/ai/local_financial_engine.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';

class AIQuickChips extends StatelessWidget {
  final bool isStreaming;
  final void Function(AnalysisType type, String label) onChipTap;

  const AIQuickChips({
    super.key,
    required this.isStreaming,
    required this.onChipTap,
  });

  static const List<(String, AnalysisType)> quickChips = [
    ('Ringkasan Keuangan', AnalysisType.financialOverview),
    ('Analisis Pengeluaran', AnalysisType.spendingAnalysis),
    ('Cek Anggaran', AnalysisType.budgetIntelligence),
    ('Pola Transaksi', AnalysisType.transactionInsights),
    ('Kesehatan Keuangan', AnalysisType.financialHealthCheck),
    ('Hitung Saving Rate', AnalysisType.savingRate),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: List.generate(quickChips.length, (idx) {
              final (label, type) = quickChips[idx];
              return GestureDetector(
                onTap: isStreaming ? null : () => onChipTap(type, label),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isStreaming ? 0.4 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x12FFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowDark,
                          offset: Offset(2, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 250.ms).slideY(begin: 0.05);
  }
}