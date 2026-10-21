import 'package:flutter_test/flutter_test.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';

void main() {
  group('TransactionModel Unit Tests', () {
    test(
      'TransactionModel instantiates and serializes to/from JSON correctly',
      () {
        final now = DateTime.now();
        final model = TransactionModel(
          id: 'test-123',
          amount: 50000,
          type: 'expense',
          categoryId: 'Food',
          paymentMethod: 'card',
          date: now,
          note: 'Lunch at cafe',
        );

        expect(model.id, 'test-123');
        expect(model.amount, 50000.0);
        expect(model.type, 'expense');
        expect(model.categoryId, 'Food');
        expect(model.paymentMethod, 'card');
        expect(model.note, 'Lunch at cafe');

        final json = model.toJson();
        expect(json['id'], 'test-123');
        expect(json['amount'], 50000.0);
        expect(json['type'], 'expense');
        expect(json['payment_method'], 'card');

        final fromJson = TransactionModel.fromJson(json);
        expect(fromJson.id, model.id);
        expect(fromJson.amount, model.amount);
        expect(fromJson.type, model.type);
      },
    );

    test('CurrencyFormatter formats IDR correctly', () {
      final formatted = CurrencyFormatter.formatStatic(150000);
      expect(formatted, contains('150.000'));
    });
  });
}
