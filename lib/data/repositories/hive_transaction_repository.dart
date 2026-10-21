import 'package:hive/hive.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/domain/repositories/transaction_repository.dart';

class HiveTransactionRepository implements TransactionRepository {
  Box<TransactionModel> get _box => Hive.box<TransactionModel>('transactions');

  @override
  Future<List<TransactionModel>> getTransactions() async => _box.values.toList();

  @override
  Future<void> addTransaction(TransactionModel transaction) async =>
      _box.put(transaction.id, transaction);

  @override
  Future<void> deleteTransaction(String id) async => _box.delete(id);
}
