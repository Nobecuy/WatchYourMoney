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

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.note,
    required this.date,
    required this.paymentMethod,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] as String,
        categoryId: (json['category_id'] as String?) ?? 'uncategorized',
        note: (json['note'] as String?) ?? '',
        date: DateTime.parse(json['transaction_date'] as String),
        paymentMethod: (json['payment_method'] as String?) ?? 'cash',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'note': note,
        'transaction_date': date.toIso8601String(),
        'payment_method': paymentMethod,
      };
}
