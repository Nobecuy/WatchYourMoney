import 'package:watch_your_money/domain/models/pending_action_model.dart';

abstract class PendingActionRepository {
  Future<List<PendingActionModel>> getPendingActions({String? sessionId});
  Future<PendingActionModel?> getPendingAction(String id);
  Future<void> addPendingAction(PendingActionModel action);
  Future<void> updatePendingAction(PendingActionModel action);
  Future<void> deletePendingAction(String id);
  Future<void> clearExpiredActions();
  Future<PendingActionModel?> getByIdempotencyKey(String idempotencyKey);
}