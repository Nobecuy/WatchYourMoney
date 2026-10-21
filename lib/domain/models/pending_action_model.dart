import 'package:hive/hive.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';

part 'pending_action_model.g.dart';

@HiveType(typeId: 13)
class PendingActionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'transaction_create' | 'transaction_update' | 'transaction_delete'

  @HiveField(2)
  final Map<String, dynamic> payload;

  @HiveField(3)
  final String status; // 'proposed' | 'confirmed' | 'rejected' | 'expired'

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? confirmedAt;

  @HiveField(6)
  final String idempotencyKey;

  @HiveField(7)
  final String? sessionId;

  PendingActionModel({
    required this.id,
    required this.type,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    required this.idempotencyKey,
    this.sessionId,
  });

  factory PendingActionModel.fromJson(Map<String, dynamic> json) => PendingActionModel(
        id: json['id'] as String,
        type: json['type'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        confirmedAt: json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at'] as String) : null,
        idempotencyKey: json['idempotency_key'] as String,
        sessionId: json['session_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'confirmed_at': confirmedAt?.toIso8601String(),
        'idempotency_key': idempotencyKey,
        'session_id': sessionId,
      };

  // Helper to extract transaction from payload for create/update
  TransactionModel? get transaction {
    if (type == 'transaction_create' || type == 'transaction_update') {
      try {
        return TransactionModel(
          id: payload['id'] as String? ?? '',
          amount: (payload['amount'] as num?)?.toDouble() ?? 0.0,
          type: payload['type'] as String? ?? 'expense',
          categoryId: payload['category_id'] as String? ?? '',
          note: payload['note'] as String? ?? '',
          date: payload['date'] != null ? DateTime.parse(payload['date'] as String) : DateTime.now(),
          paymentMethod: payload['payment_method'] as String? ?? 'cash',
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  PendingActionModel copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? payload,
    String? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
    String? idempotencyKey,
    String? sessionId,
  }) =>
      PendingActionModel(
        id: id ?? this.id,
        type: type ?? this.type,
        payload: payload ?? this.payload,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        confirmedAt: confirmedAt ?? this.confirmedAt,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        sessionId: sessionId ?? this.sessionId,
      );
}

// Idempotency key generator
String generateIdempotencyKey(String actionType, String sessionId) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${actionType}_${sessionId}_$timestamp';
}