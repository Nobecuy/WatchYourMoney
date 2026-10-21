import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/domain/models/pending_action_model.dart';
import 'package:watch_your_money/domain/repositories/transaction_repository.dart';
import 'package:watch_your_money/domain/repositories/pending_action_repository.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

/// Tool handlers execute the actual finance operations.
/// They use the existing repository/provider infrastructure.
class ToolHandlers {
  final Ref ref;
  final TransactionRepository _transactionRepo;
  final PendingActionRepository _pendingActionRepo;
  final CurrencyFormatter _formatter;

  ToolHandlers(this.ref)
      : _transactionRepo = ref.read(transactionRepositoryProvider),
        _pendingActionRepo = ref.read(pendingActionRepositoryProvider),
        _formatter = CurrencyFormatter.from(ref.read(appSettingsProvider));

  /// Get financial summary for a period.
  Future<Map<String, dynamic>> handleGetFinancialSummary(String period) async {
    final transactions = await _transactionRepo.getTransactions();
    final filtered = _filterByPeriod(transactions, period);

    final totalIncome = filtered
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = filtered
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;
    final savingRate = totalIncome > 0 ? (balance / totalIncome * 100) : 0.0;

    // Card vs cash breakdown
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

    return {
      'period': period,
      'total_income': totalIncome.toInt(),
      'total_expense': totalExpense.toInt(),
      'balance': balance.toInt(),
      'saving_rate': savingRate.toStringAsFixed(1),
      'card_balance': (cardIncome - cardExpense).toInt(),
      'cash_balance': (cashIncome - cashExpense).toInt(),
      'card_income': cardIncome.toInt(),
      'card_expense': cardExpense.toInt(),
      'cash_income': cashIncome.toInt(),
      'cash_expense': cashExpense.toInt(),
      'formatted': {
        'total_income': _formatter.format(totalIncome),
        'total_expense': _formatter.format(totalExpense),
        'balance': _formatter.format(balance),
        'card_balance': _formatter.format(cardIncome - cardExpense),
        'cash_balance': _formatter.format(cashIncome - cashExpense),
      },
      'transaction_count': filtered.length,
    };
  }

  /// Get transactions with filters.
  Future<List<Map<String, dynamic>>> handleGetTransactions({
    String? dateFrom,
    String? dateTo,
    String? category,
    String? type,
    String? paymentMethod,
    int limit = 50,
  }) async {
    final transactions = await _transactionRepo.getTransactions();
    var filtered = transactions;

    if (dateFrom != null) {
      final from = DateTime.parse(dateFrom);
      filtered = filtered.where((t) => t.date.isAfter(from.subtract(const Duration(days: 1)))).toList();
    }
    if (dateTo != null) {
      final to = DateTime.parse(dateTo).add(const Duration(days: 1));
      filtered = filtered.where((t) => t.date.isBefore(to)).toList();
    }
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((t) => t.categoryId.toLowerCase() == category.toLowerCase()).toList();
    }
    if (type != null) {
      filtered = filtered.where((t) => t.type == type).toList();
    }
    if (paymentMethod != null) {
      filtered = filtered.where((t) => t.paymentMethod == paymentMethod).toList();
    }

    // Sort by date descending
    filtered.sort((a, b) => b.date.compareTo(a.date));

    // Limit
    if (filtered.length > limit) {
      filtered = filtered.take(limit).toList();
    }

    return filtered.map((t) => {
          'id': t.id,
          'amount': t.amount.toInt(),
          'type': t.type,
          'category': t.categoryId,
          'note': t.note,
          'date': t.date.toIso8601String().split('T').first,
          'payment_method': t.paymentMethod,
          'formatted_amount': _formatter.format(t.amount),
        }).toList();
  }

  /// Get spending analysis grouped by category or payment method.
  Future<Map<String, dynamic>> handleGetSpendingAnalysis({
    required String period,
    String groupBy = 'category',
  }) async {
    final transactions = await _transactionRepo.getTransactions();
    final filtered = _filterByPeriod(transactions.where((t) => t.type == 'expense').toList(), period);

    final Map<String, double> groups = {};
    for (final t in filtered) {
      final key = groupBy == 'category' ? t.categoryId : t.paymentMethod;
      groups[key] = (groups[key] ?? 0) + t.amount;
    }

    final total = groups.values.fold(0.0, (sum, v) => sum + v);
    final sortedEntries = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'period': period,
      'group_by': groupBy,
      'total_expense': total.toInt(),
      'formatted_total': _formatter.format(total),
      'breakdown': sortedEntries.map((e) => {
            'key': e.key,
            'amount': e.value.toInt(),
            'percentage': total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0.0',
            'formatted_amount': _formatter.format(e.value),
          }).toList(),
    };
  }

  /// Calculate savings plan.
  Future<Map<String, dynamic>> handleCalculateSavingsPlan({
    required int targetAmount,
    required int monthlySaving,
    int currentSavings = 0,
  }) async {
    if (monthlySaving <= 0) {
      return {'error': 'Monthly saving must be positive'};
    }

    final remaining = targetAmount - currentSavings;
    if (remaining <= 0) {
      return {
        'target_reached': true,
        'months_needed': 0,
        'message': 'Target sudah tercapai!',
      };
    }

    final monthsNeeded = (remaining / monthlySaving).ceil();
    final years = monthsNeeded ~/ 12;
    final months = monthsNeeded % 12;

    String timeStr;
    if (years > 0 && months > 0) {
      timeStr = '$years tahun $months bulan';
    } else if (years > 0) {
      timeStr = '$years tahun';
    } else {
      timeStr = '$months bulan';
    }

    return {
      'target_amount': targetAmount,
      'current_savings': currentSavings,
      'monthly_saving': monthlySaving,
      'remaining': remaining,
      'months_needed': monthsNeeded,
      'time_estimate': timeStr,
      'formatted': {
        'target': _formatter.format(targetAmount.toDouble()),
        'current': _formatter.format(currentSavings.toDouble()),
        'monthly': _formatter.format(monthlySaving.toDouble()),
        'remaining': _formatter.format(remaining.toDouble()),
      },
    };
  }

  /// Propose a new transaction (creates pending action).
  Future<Map<String, dynamic>> handleProposeTransaction({
    required String type,
    required int amount,
    required String categoryId,
    String? note,
    String? date,
    String paymentMethod = 'cash',
  }) async {
    final id = const Uuid().v4();
    final idempotencyKey = generateIdempotencyKey('transaction_create', id);
    final txDate = date != null ? DateTime.parse(date) : DateTime.now();

    final payload = {
      'id': id,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'note': note ?? '',
      'date': txDate.toIso8601String(),
      'payment_method': paymentMethod,
    };

    final action = PendingActionModel(
      id: id,
      type: 'transaction_create',
      payload: payload,
      status: 'proposed',
      createdAt: DateTime.now(),
      idempotencyKey: idempotencyKey,
    );

    await _pendingActionRepo.addPendingAction(action);

    return {
      'action_id': id,
      'idempotency_key': idempotencyKey,
      'status': 'proposed',
      'transaction': {
        'type': type,
        'amount': amount,
        'formatted_amount': _formatter.format(amount.toDouble()),
        'category': categoryId,
        'note': note ?? '',
        'date': txDate.toIso8601String().split('T').first,
        'payment_method': paymentMethod,
      },
      'message': 'Transaksi siap dikonfirmasi. Tekan "Konfirmasi" untuk menyimpan, "Batal" untuk membatalkan, atau "Ubah" untuk mengedit.',
    };
  }

  /// Confirm a proposed transaction.
  Future<Map<String, dynamic>> handleConfirmTransaction(String idempotencyKey) async {
    // Check idempotency - prevent duplicate
    final existing = await _pendingActionRepo.getByIdempotencyKey(idempotencyKey);
    if (existing != null && existing.status == 'confirmed') {
      return {
        'success': true,
        'message': 'Transaksi sudah dikonfirmasi sebelumnya (idempotent).',
        'duplicate': true,
      };
    }

    final action = await _pendingActionRepo.getByIdempotencyKey(idempotencyKey);
    if (action == null) {
      return {'success': false, 'error': 'Proposal tidak ditemukan atau sudah kedaluwarsa'};
    }
    if (action.status != 'proposed') {
      return {'success': false, 'error': 'Proposal tidak dapat dikonfirmasi (status: ${action.status})'};
    }

    final tx = action.transaction;
    if (tx == null) {
      return {'success': false, 'error': 'Data transaksi tidak valid'};
    }

    // Validate
    if (tx.amount <= 0) {
      return {'success': false, 'error': 'Nominal harus lebih dari 0'};
    }
    if (tx.categoryId.isEmpty) {
      return {'success': false, 'error': 'Kategori harus diisi'};
    }

    // Create and save transaction
    final transaction = TransactionModel(
      id: tx.id,
      amount: tx.amount.toDouble(),
      type: tx.type,
      categoryId: tx.categoryId,
      note: tx.note,
      date: tx.date,
      paymentMethod: tx.paymentMethod,
    );

    await _transactionRepo.addTransaction(transaction);

    // Update pending action status
    await _pendingActionRepo.updatePendingAction(action.copyWith(
      status: 'confirmed',
      confirmedAt: DateTime.now(),
    ));

    // Invalidate providers to refresh UI
    ref.invalidate(transactionsProvider);

    return {
      'success': true,
      'transaction_id': transaction.id,
      'message': 'Transaksi berhasil disimpan: ${_formatter.format(transaction.amount)} untuk ${transaction.categoryId}',
    };
  }

  /// Propose a transaction update.
  Future<Map<String, dynamic>> handleProposeTransactionUpdate({
    required String transactionId,
    int? amount,
    String? categoryId,
    String? note,
    String? date,
    String? paymentMethod,
  }) async {
    // Get existing transaction
    final transactions = await _transactionRepo.getTransactions();
    final existing = transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );

    final id = const Uuid().v4();
    final idempotencyKey = generateIdempotencyKey('transaction_update', id);

    final payload = {
      'transaction_id': transactionId,
      'amount': amount ?? existing.amount.toInt(),
      'category_id': categoryId ?? existing.categoryId,
      'note': note ?? existing.note,
      'date': date ?? existing.date.toIso8601String(),
      'payment_method': paymentMethod ?? existing.paymentMethod,
    };

    final action = PendingActionModel(
      id: id,
      type: 'transaction_update',
      payload: payload,
      status: 'proposed',
      createdAt: DateTime.now(),
      idempotencyKey: idempotencyKey,
    );

    await _pendingActionRepo.addPendingAction(action);

    return {
      'action_id': id,
      'idempotency_key': idempotencyKey,
      'status': 'proposed',
      'transaction': {
        'id': transactionId,
        'amount': payload['amount'],
        'formatted_amount': _formatter.format((payload['amount'] as int).toDouble()),
        'category': payload['category_id'],
        'note': payload['note'],
        'date': (payload['date'] as String).split('T').first,
        'payment_method': payload['payment_method'],
      },
      'message': 'Perubahan siap dikonfirmasi. Tekan "Konfirmasi" untuk menyimpan, "Batal" untuk membatalkan.',
    };
  }

  /// Confirm a transaction update.
  Future<Map<String, dynamic>> handleConfirmTransactionUpdate(String idempotencyKey) async {
    final existing = await _pendingActionRepo.getByIdempotencyKey(idempotencyKey);
    if (existing != null && existing.status == 'confirmed') {
      return {
        'success': true,
        'message': 'Perubahan sudah dikonfirmasi sebelumnya (idempotent).',
        'duplicate': true,
      };
    }

    final action = await _pendingActionRepo.getByIdempotencyKey(idempotencyKey);
    if (action == null) {
      return {'success': false, 'error': 'Proposal tidak ditemukan atau sudah kedaluwarsa'};
    }
    if (action.status != 'proposed') {
      return {'success': false, 'error': 'Proposal tidak dapat dikonfirmasi (status: ${action.status})'};
    }

    final payload = action.payload;
    final transactionId = payload['transaction_id'] as String;

    // Get existing transaction
    final transactions = await _transactionRepo.getTransactions();
    final existingTx = transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );

    // Create updated transaction
    final updatedTx = TransactionModel(
      id: transactionId,
      amount: (payload['amount'] as int).toDouble(),
      type: existingTx.type, // Type cannot be changed
      categoryId: payload['category_id'] as String,
      note: payload['note'] as String,
      date: DateTime.parse(payload['date'] as String),
      paymentMethod: payload['payment_method'] as String,
    );

    await _transactionRepo.updateTransaction(updatedTx);

    // Update pending action status
    await _pendingActionRepo.updatePendingAction(action.copyWith(
      status: 'confirmed',
      confirmedAt: DateTime.now(),
    ));

    // Invalidate providers
    ref.invalidate(transactionsProvider);

    return {
      'success': true,
      'transaction_id': transactionId,
      'message': 'Transaksi berhasil diperbarui: ${_formatter.format(updatedTx.amount)} untuk ${updatedTx.categoryId}',
    };
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
}

/// Riverpod provider for ToolHandlers.
final toolHandlersProvider = Provider<ToolHandlers>((ref) => ToolHandlers(ref));