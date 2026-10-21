import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/domain/repositories/transaction_repository.dart';
import 'package:watch_your_money/data/repositories/hive_transaction_repository.dart';
import 'package:watch_your_money/data/repositories/supabase_transaction_repository.dart';
import 'package:watch_your_money/features/auth/auth_provider.dart';

/// Provider repository — memilih Hive (guest) atau Supabase (authenticated)
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.isGuest) {
    return HiveTransactionRepository();
  }
  return SupabaseTransactionRepository(Supabase.instance.client);
});

/// Provider daftar transaksi
final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactions();
});
