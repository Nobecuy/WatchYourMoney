import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/saving_rate_model.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

/// State for the Saving Rate analysis.
class SavingRateState {
  final SavingRateAnalysis? monthlyAnalysis;
  final SavingRateAnalysis? weeklyAnalysis;
  final SavingRateAnalysis? allTimeAnalysis;
  final bool isLoading;
  final String? error;

  const SavingRateState({
    this.monthlyAnalysis,
    this.weeklyAnalysis,
    this.allTimeAnalysis,
    this.isLoading = false,
    this.error,
  });

  SavingRateState copyWith({
    SavingRateAnalysis? monthlyAnalysis,
    SavingRateAnalysis? weeklyAnalysis,
    SavingRateAnalysis? allTimeAnalysis,
    bool? isLoading,
    String? error,
  }) {
    return SavingRateState(
      monthlyAnalysis: monthlyAnalysis ?? this.monthlyAnalysis,
      weeklyAnalysis: weeklyAnalysis ?? this.weeklyAnalysis,
      allTimeAnalysis: allTimeAnalysis ?? this.allTimeAnalysis,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Riverpod StateNotifier for Saving Rate calculation and analysis.
/// Performs offline-first calculation locally from Hive transactions.
class SavingRateNotifier extends StateNotifier<SavingRateState> {
  final Ref ref;
  final CurrencyFormatter _formatter;

  SavingRateNotifier(this.ref) : _formatter = CurrencyFormatter.from(ref.read(appSettingsProvider)), super(const SavingRateState());

  /// Calculate saving rate analysis for all periods.
  Future<void> calculateAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final transactions = await ref.read(transactionsProvider.future);

      final monthly = _calculateForPeriod(transactions, 'month');
      final weekly = _calculateForPeriod(transactions, 'week');
      final allTime = _calculateForPeriod(transactions, 'all');

      state = state.copyWith(
        monthlyAnalysis: monthly,
        weeklyAnalysis: weekly,
        allTimeAnalysis: allTime,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Calculate saving rate for a specific period.
  Future<SavingRateAnalysis> calculateForPeriod(String period) async {
    final transactions = await ref.read(transactionsProvider.future);
    return _calculateForPeriod(transactions, period);
  }

  /// Core calculation logic.
  SavingRateAnalysis _calculateForPeriod(List<TransactionModel> transactions, String period) {
    final filtered = _filterByPeriod(transactions, period);

    final totalIncome = filtered
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount)
        .toInt();

    final totalExpense = filtered
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount)
        .toInt();

    // Top expense categories
    final expenseByCategory = <String, double>{};
    for (final t in filtered.where((t) => t.type == 'expense')) {
      expenseByCategory[t.categoryId] = (expenseByCategory[t.categoryId] ?? 0) + t.amount;
    }
    final sortedExpenses = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topExpenseCategories = <String, int>{};
    for (final e in sortedExpenses.take(5)) {
      topExpenseCategories[e.key] = e.value.toInt();
    }

    // Top income categories
    final incomeByCategory = <String, double>{};
    for (final t in filtered.where((t) => t.type == 'income')) {
      incomeByCategory[t.categoryId] = (incomeByCategory[t.categoryId] ?? 0) + t.amount;
    }
    sortedExpenses.clear();
    final sortedIncomes = incomeByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topIncomeCategories = <String, int>{};
    for (final e in sortedIncomes.take(5)) {
      topIncomeCategories[e.key] = e.value.toInt();
    }

    return SavingRateAnalysis.fromCalculation(
      period: period,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      topExpenseCategories: topExpenseCategories,
      topIncomeCategories: topIncomeCategories,
    );
  }

  /// Filter transactions by period.
  List<TransactionModel> _filterByPeriod(List<TransactionModel> transactions, String period) {
    final now = DateTime.now();
    return transactions.where((t) {
      if (period == 'week') {
        return t.date.isAfter(now.subtract(const Duration(days: 7)));
      }
      if (period == 'month') {
        return t.date.month == now.month && t.date.year == now.year;
      }
      return true; // 'all'
    }).toList();
  }

  /// Get formatted analysis text for AI context or direct display.
  String getFormattedAnalysis(SavingRateAnalysis analysis) {
    final lines = <String>[
      'Analisis Saving Rate (${_periodLabel(analysis.period)})',
      '',
      '📊 Ringkasan Angka:',
      '- Total Pemasukan: ${analysis.formattedTotalIncome}',
      '- Total Pengeluaran: ${analysis.formattedTotalExpense}',
      '- Sisa Tabungan Bersih: ${analysis.formattedNetSavings}',
      '- Saving Rate: ${analysis.formattedSavingRate}',
      '',
      '🏷️ Status & Diagnosa:',
      '- Kategori: ${analysis.statusLabel}',
      '- ${analysis.category.description}',
      '',
      '💡 Rekomendasi Aksi:',
    ];

    for (int i = 0; i < analysis.category.recommendedActions.length; i++) {
      lines.add('${i + 1}. ${analysis.category.recommendedActions[i]}');
    }

    if (analysis.topExpenseCategories.isNotEmpty) {
      lines.add('');
      lines.add('📈 Kategori Pengeluaran Terbesar:');
      for (final entry in analysis.topExpenseCategories.entries) {
        lines.add('- ${entry.key}: ${_formatter.format(entry.value.toDouble())}');
      }
    }

    if (analysis.topIncomeCategories.isNotEmpty) {
      lines.add('');
      lines.add('💰 Sumber Pemasukan Utama:');
      for (final entry in analysis.topIncomeCategories.entries) {
        lines.add('- ${entry.key}: ${_formatter.format(entry.value.toDouble())}');
      }
    }

    return lines.join('\n');
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'week':
        return 'Mingguan';
      case 'month':
        return 'Bulanan';
      case 'all':
        return 'Seluruh Waktu';
      default:
        return period;
    }
  }

  /// Get AI-ready context for the current period.
  Map<String, dynamic>? getAiContext(String period) {
    final analysis = switch (period) {
      'week' => state.weeklyAnalysis,
      'month' => state.monthlyAnalysis,
      'all' => state.allTimeAnalysis,
      _ => null,
    };
    return analysis?.toAiContext();
  }
}

/// Riverpod provider for SavingRateNotifier.
final savingRateNotifierProvider = StateNotifierProvider<SavingRateNotifier, SavingRateState>((ref) {
  return SavingRateNotifier(ref);
});

/// Convenience provider for monthly analysis.
final monthlySavingRateProvider = FutureProvider<SavingRateAnalysis?>((ref) async {
  await ref.read(savingRateNotifierProvider.notifier).calculateAll();
  return ref.read(savingRateNotifierProvider).monthlyAnalysis;
});

/// Convenience provider for weekly analysis.
final weeklySavingRateProvider = FutureProvider<SavingRateAnalysis?>((ref) async {
  await ref.read(savingRateNotifierProvider.notifier).calculateAll();
  return ref.read(savingRateNotifierProvider).weeklyAnalysis;
});

/// Convenience provider for all-time analysis.
final allTimeSavingRateProvider = FutureProvider<SavingRateAnalysis?>((ref) async {
  await ref.read(savingRateNotifierProvider.notifier).calculateAll();
  return ref.read(savingRateNotifierProvider).allTimeAnalysis;
});