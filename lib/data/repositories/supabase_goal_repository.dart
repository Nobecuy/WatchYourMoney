import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/data/repositories/hive_goal_repository.dart';
import 'package:watch_your_money/features/goals/models/goal_model.dart';
import 'package:watch_your_money/domain/repositories/goal_repository.dart';

/// Dual-write repository: writes to Supabase (cloud) and a per-user Hive box
/// (local cache). Falls back to the local cache when offline.
class SupabaseGoalRepository implements GoalRepository {
  final SupabaseClient _client;

  SupabaseGoalRepository(this._client);

  /// Scoped local cache — uses the logged-in user's Hive box, never the guest box.
  HiveGoalRepository get _local =>
      HiveGoalRepository(userId: _client.auth.currentUser?.id);

  @override
  Future<List<GoalModel>> getGoals() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _local.getGoals();

    try {
      final response = await _client
          .from('goals')
          .select()
          .eq('user_id', userId)
          .order('target_date', ascending: true);

      final remoteList = (response as List)
          .map((e) => GoalModel.fromJson(e))
          .toList();

      // Keep local cache in sync with remote.
      for (final goal in remoteList) {
        await _local.addGoal(goal);
      }
      return remoteList;
    } catch (_) {
      // Offline or Supabase table not ready — fall back to local cache.
      return _local.getGoals();
    }
  }

  @override
  Future<void> addGoal(GoalModel goal) async {
    // Write to local cache immediately (offline-first).
    await _local.addGoal(goal);

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final json = goal.toSupabaseJson();
      json['user_id'] = userId;
      await _client.from('goals').insert(json);
    } catch (_) {
      // Already in local cache; will be pushed next time online.
    }
  }

  @override
  Future<void> updateGoal(GoalModel goal) async {
    await _local.updateGoal(goal);

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final json = goal.toSupabaseJson();
      json['user_id'] = userId;
      await _client.from('goals').update(json).eq('id', goal.id);
    } catch (_) {}
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _local.deleteGoal(id);

    try {
      await _client.from('goals').delete().eq('id', id);
    } catch (_) {}
  }

  @override
  Future<void> addSavings(String goalId, double amount) async {
    await _local.addSavings(goalId, amount);

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get the updated goal from local cache to sync
      final goal = await _local.getGoals().then((goals) =>
          goals.where((g) => g.id == goalId).firstOrNull);
      if (goal != null) {
        final json = goal.toSupabaseJson();
        json['user_id'] = userId;
        await _client.from('goals').update(json).eq('id', goal.id);
      }
    } catch (_) {}
  }
}