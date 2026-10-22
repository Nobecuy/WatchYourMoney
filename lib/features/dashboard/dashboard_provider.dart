import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/core/ai/tool_handlers.dart';
import 'package:watch_your_money/data/repositories/hive_chat_message_repository.dart';
import 'package:watch_your_money/data/repositories/hive_noir_settings_repository.dart';
import 'package:watch_your_money/data/repositories/hive_pending_action_repository.dart';
import 'package:watch_your_money/data/repositories/hive_transaction_repository.dart';
import 'package:watch_your_money/data/repositories/supabase_transaction_repository.dart';
import 'package:watch_your_money/domain/models/noir_settings_model.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/domain/repositories/chat_message_repository.dart';
import 'package:watch_your_money/domain/repositories/noir_settings_repository.dart';
import 'package:watch_your_money/domain/repositories/pending_action_repository.dart';
import 'package:watch_your_money/domain/repositories/transaction_repository.dart';
import 'package:watch_your_money/features/auth/auth_provider.dart';

/// Provider repository — memilih Hive (guest) atau Supabase (authenticated)
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.isGuest) {
    // Guest: scoped to 'transactions_guest' box
    return HiveTransactionRepository();
  }
  // Logged-in: always try Supabase first (dual-write with per-user Hive cache)
  return SupabaseTransactionRepository(Supabase.instance.client);
});

/// Provider daftar transaksi
final transactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactions();
});

/// Chat message repository provider
final chatMessageRepositoryProvider = Provider<ChatMessageRepository>((ref) {
  return HiveChatMessageRepository();
});

/// Pending action repository provider
final pendingActionRepositoryProvider = Provider<PendingActionRepository>((
  ref,
) {
  return HivePendingActionRepository();
});

/// Noir settings repository provider
final noirSettingsRepositoryProvider = Provider<NoirSettingsRepository>((ref) {
  return HiveNoirSettingsRepository();
});

/// Noir settings (current config)
final noirSettingsProvider = FutureProvider<NoirSettingsModel>((ref) async {
  final repo = ref.watch(noirSettingsRepositoryProvider);
  await repo.init();
  return repo.getSettings();
});

/// Tool handlers provider
final toolHandlersProvider = Provider<ToolHandlers>((ref) => ToolHandlers(ref));
