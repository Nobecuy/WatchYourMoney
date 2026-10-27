import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/data/repositories/hive_transaction_repository.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/domain/repositories/transaction_repository.dart';

/// Dual-write repository: writes to Supabase (cloud) and a per-user Hive box
/// (local cache). Falls back to the local cache when offline.
class SupabaseTransactionRepository implements TransactionRepository {
  final SupabaseClient _client;

  SupabaseTransactionRepository(this._client);

  /// Scoped local cache — uses the logged-in user's Hive box, never the guest box.
  HiveTransactionRepository get _local =>
      HiveTransactionRepository(userId: _client.auth.currentUser?.id);

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _local.getTransactions();

    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('transaction_date', ascending: false);

      final remoteList = (response as List)
          .map((e) => TransactionModel.fromJson(e))
          .toList();

      // Keep local cache in sync with remote.
      for (final tx in remoteList) {
        await _local.addTransaction(tx);
      }
      return remoteList;
    } catch (_) {
      // Offline or Supabase table not ready — fall back to local cache.
      return _local.getTransactions();
    }
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    // Write to local cache immediately (offline-first).
    await _local.addTransaction(transaction);

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final json = transaction.toSupabaseJson();
      json['user_id'] = userId;
      await _client.from('transactions').insert(json);
    } catch (_) {
      // Already in local cache; will be pushed next time online.
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _local.updateTransaction(transaction);

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final json = transaction.toSupabaseJson();
      json['user_id'] = userId;
      await _client.from('transactions').update(json).eq('id', transaction.id);
    } catch (_) {}
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _local.deleteTransaction(id);

    try {
      await _client.from('transactions').delete().eq('id', id);
    } catch (_) {}
  }
}
