import 'package:hive_flutter/hive_flutter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/domain/repositories/transaction_repository.dart';

/// A Hive-backed transaction repository that scopes data per user.
///
/// Each user gets their own Hive box so that guest data and logged-in
/// user data are never mixed:
///   - Guest  : box name is "transactions_guest"
///   - User   : box name is "transactions_{userId}"
class HiveTransactionRepository implements TransactionRepository {
  /// Pass [userId] as the Supabase user ID for logged-in users,
  /// or null/empty string for the guest box.
  HiveTransactionRepository({String? userId})
    : boxName = (userId == null || userId.isEmpty)
          ? 'transactions_guest'
          : 'transactions_$userId';

  final String boxName;

  /// Open the scoped box if it isn't already open.
  Future<Box<TransactionModel>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<TransactionModel>(boxName);
    }
    return Hive.openBox<TransactionModel>(boxName);
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final box = await _openBox();
    return box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Calculate current balance for a payment method from existing transactions
  double _calculateCurrentBalance(List<TransactionModel> transactions, String paymentMethod) {
    double income = 0;
    double expense = 0;
    for (final tx in transactions) {
      if (tx.paymentMethod == paymentMethod) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }
    }
    return income - expense;
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final box = await _openBox();

    // Calculate balance before this transaction
    final existingTransactions = box.values.toList();
    final balanceBefore = _calculateCurrentBalance(existingTransactions, transaction.paymentMethod);

    // Calculate balance after
    final balanceAfter = transaction.type == 'income'
        ? balanceBefore + transaction.amount
        : balanceBefore - transaction.amount;

    // Create new transaction with balance info
    final txWithBalance = TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      note: transaction.note,
      date: transaction.date,
      paymentMethod: transaction.paymentMethod,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
    );

    await box.put(txWithBalance.id, txWithBalance);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final box = await _openBox();
    await box.put(transaction.id, transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
