import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/domain/repositories/transaction_repository.dart';

class SupabaseTransactionRepository implements TransactionRepository {
  final SupabaseClient _client;
  SupabaseTransactionRepository(this._client);

  Box<TransactionModel> get _localBox => Hive.box<TransactionModel>('transactions');

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _localBox.values.toList();

    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('transaction_date', ascending: false);

      final remoteList = (response as List).map((e) => TransactionModel.fromJson(e)).toList();

      // Sync remote transactions to local cache
      for (final tx in remoteList) {
        await _localBox.put(tx.id, tx);
      }
      return remoteList;
    } catch (e) {
      // Fallback to local storage if Supabase table is not created yet or offline
      return _localBox.values.toList();
    }
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    // Save to local storage first
    await _localBox.put(transaction.id, transaction);

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final json = transaction.toJson();
      json['user_id'] = userId;
      await _client.from('transactions').insert(json);
    } catch (e) {
      // Local box has already stored it; will be synced once table exists
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    // Update local storage first
    await _localBox.put(transaction.id, transaction);

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final json = transaction.toJson();
      json['user_id'] = userId;
      await _client.from('transactions').update(json).eq('id', transaction.id);
    } catch (e) {
      // Local box has already stored it
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _localBox.delete(id);
    try {
      await _client.from('transactions').delete().eq('id', id);
    } catch (e) {
      // Table may not exist yet
    }
  }
}
