import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String type; // 'income' | 'expense'

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final String note;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final String paymentMethod; // 'card' | 'cash'

  // NEW: Balance tracking fields (optional for backward compatibility)
  @HiveField(7)
  final double balanceBefore;

  @HiveField(8)
  final double balanceAfter;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.note,
    required this.date,
    required this.paymentMethod,
    this.balanceBefore = 0.0,
    this.balanceAfter = 0.0,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] as String,
        categoryId: (json['category_id'] as String?) ?? 'uncategorized',
        note: (json['note'] as String?) ?? '',
        date: DateTime.parse(json['transaction_date'] as String),
        paymentMethod: (json['payment_method'] as String?) ?? 'cash',
        balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0.0,
        balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'note': note,
        'transaction_date': date.toIso8601String(),
        'payment_method': paymentMethod,
        'balance_before': balanceBefore,
        'balance_after': balanceAfter,
      };

  /// Serializes to JSON for Supabase (includes balance fields).
  /// Requires the Supabase migration to have added `balance_before` and `balance_after` columns.
  /// Run the migration in supabase_migration_add_balance_columns.sql before enabling this.
  Map<String, dynamic> toSupabaseJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'note': note,
        'transaction_date': date.toIso8601String(),
        'payment_method': paymentMethod,
        'balance_before': balanceBefore,
        'balance_after': balanceAfter,
      };
}
