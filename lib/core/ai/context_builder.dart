import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/noir_settings_model.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

/// Builds structured context for the LLM based on user query and available data.
class ContextBuilder {
  final Ref ref;
  final NoirSettingsModel settings;

  ContextBuilder(this.ref, this.settings);

  /// Build context for the current query.
  /// Returns a map with relevant financial data, limited by token budget.
  Future<Map<String, dynamic>> buildContext({
    required String userQuery,
    required List<Map<String, dynamic>> recentMessages,
  }) async {
    final context = <String, dynamic>{};
    int estimatedTokens = _estimateSystemPromptTokens();

    // 1. Add current financial summary (always included)
    final summary = await _getFinancialSummary('month');
    context['financial_summary'] = summary;
    estimatedTokens += _estimateJsonTokens(summary);

    // 2. Add recent transactions (last 10)
    if (estimatedTokens < settings.contextTokenBudget - 1000) {
      final transactions = await _getRecentTransactions(10);
      context['recent_transactions'] = transactions;
      estimatedTokens += _estimateJsonTokens(transactions);
    }

    // 3. Add spending analysis if query suggests it
    if (_querySuggestsAnalysis(userQuery) && estimatedTokens < settings.contextTokenBudget - 500) {
      final analysis = await _getSpendingAnalysis('month', 'category');
      context['spending_analysis'] = analysis;
      estimatedTokens += _estimateJsonTokens(analysis);
    }

    // 4. Add available categories for transaction proposals
    if (_querySuggestsTransaction(userQuery) && estimatedTokens < settings.contextTokenBudget - 300) {
      final categories = _getDefaultCategories();
      context['categories'] = categories;
      estimatedTokens += _estimateJsonTokens(categories);
    }

    // 5. Add currency info
    context['currency'] = {
      'code': ref.read(currencyCodeProvider),
      'symbol': CurrencyFormatter.from(ref.read(appSettingsProvider)).symbol,
    };

    // 6. Add conversation history (last 5 exchanges)
    if (estimatedTokens < settings.contextTokenBudget - 500) {
      context['conversation_history'] = recentMessages.take(5).toList();
    }

    context['_meta'] = {
      'estimated_tokens': estimatedTokens,
      'token_budget': settings.contextTokenBudget,
      'model': settings.modelName,
    };

    return context;
  }

  /// Get financial summary for a period.
  Future<Map<String, dynamic>> _getFinancialSummary(String period) async {
    final transactions = await ref.read(transactionRepositoryProvider).getTransactions();
    final filtered = _filterByPeriod(transactions, period);

    final totalIncome = filtered
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = filtered
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;

    final cardIncome = filtered
        .where((t) => t.type == 'income' && t.paymentMethod == 'card')
        .fold(0.0, (sum, t) => sum + t.amount);
    final cardExpense = filtered
        .where((t) => t.type == 'expense' && t.paymentMethod == 'card')
        .fold(0.0, (sum, t) => sum + t.amount);
    final cashIncome = filtered
        .where((t) => t.type == 'income' && t.paymentMethod == 'cash')
        .fold(0.0, (sum, t) => sum + t.amount);
    final cashExpense = filtered
        .where((t) => t.type == 'expense' && t.paymentMethod == 'cash')
        .fold(0.0, (sum, t) => sum + t.amount);

    final formatter = CurrencyFormatter.from(ref.read(appSettingsProvider));

    return {
      'period': period,
      'total_income': totalIncome.toInt(),
      'total_expense': totalExpense.toInt(),
      'balance': balance.toInt(),
      'card_balance': (cardIncome - cardExpense).toInt(),
      'cash_balance': (cashIncome - cashExpense).toInt(),
      'formatted': {
        'total_income': formatter.format(totalIncome),
        'total_expense': formatter.format(totalExpense),
        'balance': formatter.format(balance),
        'card_balance': formatter.format(cardIncome - cardExpense),
        'cash_balance': formatter.format(cashIncome - cashExpense),
      },
    };
  }

  /// Get recent transactions.
  Future<List<Map<String, dynamic>>> _getRecentTransactions(int limit) async {
    final transactions = await ref.read(transactionRepositoryProvider).getTransactions();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    final formatter = CurrencyFormatter.from(ref.read(appSettingsProvider));

    return transactions.take(limit).map((t) => {
          'id': t.id,
          'amount': t.amount.toInt(),
          'type': t.type,
          'category': t.categoryId,
          'note': t.note,
          'date': t.date.toIso8601String().split('T').first,
          'payment_method': t.paymentMethod,
          'formatted_amount': formatter.format(t.amount),
        }).toList();
  }

  /// Get spending analysis.
  Future<Map<String, dynamic>> _getSpendingAnalysis(String period, String groupBy) async {
    final transactions = await ref.read(transactionRepositoryProvider).getTransactions();
    final filtered = _filterByPeriod(transactions.where((t) => t.type == 'expense').toList(), period);

    final Map<String, double> groups = {};
    for (final t in filtered) {
      final key = groupBy == 'category' ? t.categoryId : t.paymentMethod;
      groups[key] = (groups[key] ?? 0) + t.amount;
    }

    final total = groups.values.fold(0.0, (sum, v) => sum + v);
    final sortedEntries = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final formatter = CurrencyFormatter.from(ref.read(appSettingsProvider));

    return {
      'period': period,
      'group_by': groupBy,
      'total_expense': total.toInt(),
      'formatted_total': formatter.format(total),
      'breakdown': sortedEntries.map((e) => {
            'key': e.key,
            'amount': e.value.toInt(),
            'percentage': total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0.0',
            'formatted_amount': formatter.format(e.value),
          }).toList(),
    };
  }

  /// Check if query suggests analysis.
  bool _querySuggestsAnalysis(String query) {
    final lower = query.toLowerCase();
    const analysisKeywords = [
      'analisis', 'analysis', 'polanya', 'pattern', 'tren', 'trend',
      'kategori', 'category', 'paling banyak', 'most', 'terbesar',
      'breakdown', 'rincian', 'detail', 'proporsi', 'percentage',
    ];
    return analysisKeywords.any((kw) => lower.contains(kw));
  }

  /// Check if query suggests transaction creation.
  bool _querySuggestsTransaction(String query) {
    final lower = query.toLowerCase();
    const transactionKeywords = [
      'catat', 'record', 'simpan', 'save', 'tambah', 'add',
      'beli', 'buy', 'bayar', 'pay', 'belanja', 'shop',
      'pengeluaran', 'expense', 'pemasukan', 'income',
      'transaksi', 'transaction',
    ];
    return transactionKeywords.any((kw) => lower.contains(kw));
  }

  /// Get default categories from the app.
  List<String> _getDefaultCategories() {
    return [
      // Expense categories
      'Makanan', 'Transportasi', 'Belanja', 'Tagihan',
      'Hiburan', 'Kesehatan', 'Edukasi', 'Lainnya',
      // Income categories
      'Gaji', 'Bonus/Freelance', 'Investasi', 'Hadiah', 'Penjualan', 'Lainnya',
    ];
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
      return true;
    }).toList();
  }

  /// Estimate system prompt tokens.
  int _estimateSystemPromptTokens() {
    // Rough estimate: system prompt + tool definitions ~ 2000 tokens
    return 2000;
  }

  /// Rough token estimation for JSON.
  int _estimateJsonTokens(dynamic json) {
    final str = json.toString();
    // Rough: 1 token ≈ 4 characters for JSON
    return (str.length / 4).ceil();
  }
}

/// Riverpod provider for ContextBuilder.
final contextBuilderProvider = Provider.family<ContextBuilder, NoirSettingsModel>((ref, settings) {
  return ContextBuilder(ref, settings);
});