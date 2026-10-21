import 'package:hive/hive.dart';
import 'package:watch_your_money/domain/models/pending_action_model.dart';
import 'package:watch_your_money/domain/repositories/pending_action_repository.dart';

class HivePendingActionRepository implements PendingActionRepository {
  static const String _boxName = 'pending_actions';
  late Box<PendingActionModel> _box;

  Future<void> init() async {
    _box = await Hive.openBox<PendingActionModel>(_boxName);
  }

  @override
  Future<List<PendingActionModel>> getPendingActions({String? sessionId}) async {
    final actions = _box.values.where((a) {
      if (sessionId != null && a.sessionId != sessionId) return false;
      return a.status == 'proposed';
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return actions;
  }

  @override
  Future<PendingActionModel?> getPendingAction(String id) async {
    return _box.get(id);
  }

  @override
  Future<void> addPendingAction(PendingActionModel action) async {
    await _box.put(action.id, action);
  }

  @override
  Future<void> updatePendingAction(PendingActionModel action) async {
    await _box.put(action.id, action);
  }

  @override
  Future<void> deletePendingAction(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clearExpiredActions() async {
    final now = DateTime.now();
    final keysToDelete = _box.values
        .where((a) => a.status == 'proposed' && a.createdAt.add(const Duration(hours: 24)).isBefore(now))
        .map((a) => a.key)
        .toList();
    await _box.deleteAll(keysToDelete);
  }

  @override
  Future<PendingActionModel?> getByIdempotencyKey(String idempotencyKey) async {
    try {
      return _box.values.firstWhere((a) => a.idempotencyKey == idempotencyKey);
    } catch (_) {
      return null;
    }
  }
}