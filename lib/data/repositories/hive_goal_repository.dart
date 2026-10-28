import 'package:hive_flutter/hive_flutter.dart';
import 'package:watch_your_money/features/goals/models/goal_model.dart';
import 'package:watch_your_money/domain/repositories/goal_repository.dart';

/// A Hive-backed goal repository that scopes data per user.
///
/// Each user gets their own Hive box so that guest data and logged-in
/// user data are never mixed:
///   - Guest  : box name is "goals_guest"
///   - User   : box name is "goals_{userId}"
class HiveGoalRepository implements GoalRepository {
  /// Pass [userId] as the Supabase user ID for logged-in users,
  /// or null/empty string for the guest box.
  HiveGoalRepository({String? userId})
      : boxName = (userId == null || userId.isEmpty)
            ? 'goals_guest'
            : 'goals_$userId';

  final String boxName;

  /// Open the scoped box if it isn't already open.
  Future<Box<GoalModel>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<GoalModel>(boxName);
    }
    return Hive.openBox<GoalModel>(boxName);
  }

  @override
  Future<List<GoalModel>> getGoals() async {
    final box = await _openBox();
    final goals = box.values.toList();
    // Sort by status (active first), then by target date
    goals.sort((a, b) {
      // Active goals first
      if (a.status != b.status) {
        if (a.status == 'active') return -1;
        if (b.status == 'active') return 1;
      }
      // Then by target date (soonest first)
      return a.targetDate.compareTo(b.targetDate);
    });
    return goals;
  }

  @override
  Future<void> addGoal(GoalModel goal) async {
    final box = await _openBox();
    await box.put(goal.id, goal);
  }

  @override
  Future<void> updateGoal(GoalModel goal) async {
    final box = await _openBox();
    final updatedGoal = goal.copyWith(updatedAt: DateTime.now());
    await box.put(updatedGoal.id, updatedGoal);
  }

  @override
  Future<void> deleteGoal(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  @override
  Future<void> addSavings(String goalId, double amount) async {
    final box = await _openBox();
    final goal = box.get(goalId);
    if (goal != null) {
      final updatedGoal = goal.copyWith(
        currentAmount: goal.currentAmount + amount,
        updatedAt: DateTime.now(),
      );
      // Auto-complete if target reached
      if (updatedGoal.isCompleted && updatedGoal.status == 'active') {
        final completedGoal = updatedGoal.copyWith(status: 'completed');
        await box.put(completedGoal.id, completedGoal);
      } else {
        await box.put(updatedGoal.id, updatedGoal);
      }
    }
  }
}