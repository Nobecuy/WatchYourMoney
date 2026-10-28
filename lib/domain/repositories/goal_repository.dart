import 'package:watch_your_money/features/goals/models/goal_model.dart';

abstract class GoalRepository {
  Future<List<GoalModel>> getGoals();
  Future<void> addGoal(GoalModel goal);
  Future<void> updateGoal(GoalModel goal);
  Future<void> deleteGoal(String id);
  Future<void> addSavings(String goalId, double amount);
}