import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

enum _Intent {
  greeting,
  summary,
  spendingAnalysis,
  incomeAnalysis,
  savingTip,
  recordTransaction,
  unknown,
}

class LocalFinancialEngine {
  final WidgetRef _ref;
  const LocalFinancialEngine(this._ref);

  static const _summaryKw = [
    'saldo',
    'balance',
    'total',
    'ringkasan',
    'summary',
    'berapa',
    'jumlah',
  ];
  static const _spendingKw = [
    'pengeluaran',
    'belanja',
    'keluar',
    'expense',
    'habis',
    'terbesar',
    'spending',
    'boros',
  ];
  static const _incomeKw = [
    'pemasukan',
    'masuk',
    'income',
    'gaji',
    'penghasilan',
    'pendapatan',
  ];
  static const _tipKw = [
    'tips',
    'saran',
    'hemat',
    'advice',
    'rekomendasi',
    'nabung',
    'simpan',
  ];

  static const _greetingKw = [
    'halo',
    'hai',
    'hi',
    'hello',
    'help',
    'bantuan',
    'siapa kamu',
    'bisa apa',
    'fitur',
    'kemampuan',
    'kapabilitas',
  ];

  _Intent _classifyIntent(String msg) {
    final lower = msg.toLowerCase();
    if (_greetingKw.any(lower.contains)) return _Intent.greeting;
    if (_summaryKw.any(lower.contains)) return _Intent.summary;
    if (_spendingKw.any(lower.contains)) return _Intent.spendingAnalysis;
    if (_incomeKw.any(lower.contains)) return _Intent.incomeAnalysis;
    if (_tipKw.any(lower.contains)) return _Intent.savingTip;
    return _Intent.unknown;
  }

  String _generateResponse(
    _Intent intent,
    List<TransactionModel> transactions,
    CurrencyFormatter fmt,
  ) {
    switch (intent) {
      case _Intent.greeting:
        return 'Halo! Saya Noir, asisten keuangan pribadi kamu.\n\n'
            'Berikut beberapa hal yang bisa saya bantu secara otomatis:\n\n'
            '- Mencatat Pengeluaran: Ketik "Beli Kopi 25rb" atau "Makan siang 15000"\n'
            '- Mencatat Pemasukan: Ketik "Gaji 5jt" atau "Bonus proyek 500rb"\n'
            '- Cek Sisa Saldo: Tanya "Berapa sisa uangku?" atau "Sisa saldo"\n'
            '- Rekap Pengeluaran: Tanya "Berapa total pengeluaranku?"\n'
            '- Rekap Pemasukan: Tanya "Berapa total pemasukanku?"\n\n'
            'Kamu bisa ketik langsung di kolom chat atau tekan tombol shortcut di bawah.';

      case _Intent.summary:
        final income = transactions
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount);
        final expense = transactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);
        final balance = income - expense;
        final rate = income > 0
            ? ((balance / income) * 100).toStringAsFixed(1)
            : '0.0';
        return 'Ringkasan Keuangan\n\n'
            '- Pemasukan: ${fmt.format(income)}\n'
            '- Pengeluaran: ${fmt.format(expense)}\n'
            '- Saldo bersih: ${fmt.format(balance)}\n'
            '- Saving rate: $rate%';

      case _Intent.spendingAnalysis:
        final expenses = transactions.where((t) => t.type == 'expense');
        if (expenses.isEmpty) return 'Belum ada pengeluaran yang tercatat.';
        final total = expenses.fold(0.0, (s, t) => s + t.amount);
        final grouped = <String, double>{};
        for (final t in expenses) {
          grouped[t.categoryId] = (grouped[t.categoryId] ?? 0) + t.amount;
        }
        final sorted = grouped.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = sorted
            .take(3)
            .map((e) {
              final pct = ((e.value / total) * 100).toStringAsFixed(1);
              return '- ${e.key}: ${fmt.format(e.value)} ($pct%)';
            })
            .join('\n');
        return 'Top Pengeluaran\n\n$top\n\nTotal: ${fmt.format(total)}';

      case _Intent.incomeAnalysis:
        final incomes = transactions.where((t) => t.type == 'income');
        if (incomes.isEmpty) return 'Belum ada pemasukan yang tercatat.';
        final total = incomes.fold(0.0, (s, t) => s + t.amount);
        final grouped = <String, double>{};
        for (final t in incomes) {
          grouped[t.categoryId] = (grouped[t.categoryId] ?? 0) + t.amount;
        }
        final breakdown = grouped.entries
            .map((e) => '- ${e.key}: ${fmt.format(e.value)}')
            .join('\n');
        return 'Sumber Pemasukan\n\n$breakdown\n\nTotal: ${fmt.format(total)}';

      case _Intent.savingTip:
        final income = transactions
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount);
        final expense = transactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);
        if (income == 0) {
          return 'Info: Catat pemasukan kamu dulu agar saya bisa memberi saran yang tepat.';
        }
        final ratio = expense / income;
        if (ratio < 0.5) {
          return 'Luar biasa! Rasio pengeluaranmu sangat sehat (${(ratio * 100).toStringAsFixed(0)}%). Pertahankan!';
        }
        if (ratio < 0.7) {
          return 'Bagus! Pengeluaran di ${(ratio * 100).toStringAsFixed(0)}% dari pemasukan. Masih aman.';
        }
        if (ratio < 0.9) {
          return 'Perhatian! Pengeluaranmu ${(ratio * 100).toStringAsFixed(0)}% dari pemasukan. Cari kategori terbesar dan coba efisiensi.';
        }
        return 'Peringatan! Pengeluaran mencapai ${(ratio * 100).toStringAsFixed(0)}% dari pemasukan. Segera review anggaranmu!';

      case _Intent.recordTransaction:
        return 'Untuk mencatat transaksi, gunakan tombol + di layar utama.';

      case _Intent.unknown:
        return 'Maaf, saya belum mengerti pertanyaanmu. Coba tanyakan tentang:\n'
            '- Saldo atau ringkasan\n'
            '- Pengeluaran terbesar\n'
            '- Pemasukan\n'
            '- Tips hemat';
    }
  }

  Stream<String> streamResponse({
    required String userMessage,
    required String sessionId,
  }) async* {
    final transactions = await _ref.read(transactionsProvider.future);
    final settings = _ref.read(settingsProvider);
    final fmt = CurrencyFormatter.from(settings);
    final intent = _classifyIntent(userMessage);
    yield _generateResponse(intent, transactions, fmt);
  }
}
