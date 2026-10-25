import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

/// Analysis types available to non-developer users.
enum AnalysisType {
  financialOverview,
  spendingAnalysis,
  budgetIntelligence,
  transactionInsights,
  financialHealthCheck,
  savingRate,
}

class LocalFinancialEngine {
  final WidgetRef _ref;
  const LocalFinancialEngine(this._ref);

  // ── Keyword lists for developer chat mode ──────────────────────────

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

  // ── Public: run structured analysis by type ─────────────────────────

  Future<String> runAnalysis(AnalysisType type) async {
    final transactions = await _ref.read(transactionsProvider.future);
    final settings = _ref.read(settingsProvider);
    final fmt = CurrencyFormatter.from(settings);

    switch (type) {
      case AnalysisType.financialOverview:
        return _financialOverview(transactions, fmt);
      case AnalysisType.spendingAnalysis:
        return _spendingAnalysis(transactions, fmt);
      case AnalysisType.budgetIntelligence:
        return _budgetIntelligence(transactions, fmt);
      case AnalysisType.transactionInsights:
        return _transactionInsights(transactions, fmt);
      case AnalysisType.financialHealthCheck:
        return _financialHealthCheck(transactions, fmt);
      case AnalysisType.savingRate:
        return _savingRateAnalysis(transactions, fmt);
    }
  }

  // ── A. Financial Overview ───────────────────────────────────────────

  String _financialOverview(List<TransactionModel> txs, CurrencyFormatter fmt) {
    final income = txs
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final balance = income - expense;
    final status = balance >= 0 ? 'Surplus' : 'Defisit';

    // Biggest expense category
    final expByCat = <String, double>{};
    for (final t in txs.where((t) => t.type == 'expense')) {
      expByCat[t.categoryId] = (expByCat[t.categoryId] ?? 0) + t.amount;
    }
    final topCat = expByCat.entries.isEmpty
        ? null
        : expByCat.entries.reduce((a, b) => a.value > b.value ? a : b);

    // This month vs last month comparison
    final now = DateTime.now();
    final thisMonth = txs.where(
      (t) => t.date.month == now.month && t.date.year == now.year,
    );
    final lastMonth = txs.where((t) {
      final lm = DateTime(now.year, now.month - 1);
      return t.date.month == lm.month && t.date.year == lm.year;
    });
    final thisExp = thisMonth
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final lastExp = lastMonth
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final change = lastExp > 0
        ? '${((thisExp - lastExp) / lastExp * 100).toStringAsFixed(1)}% vs bulan lalu'
        : 'N/A (belum ada data bulan lalu)';

    final lines = <String>['Ringkasan Keuangan', ''];
    lines.add('- Total Pemasukan: ${fmt.format(income)}');
    lines.add('- Total Pengeluaran: ${fmt.format(expense)}');
    lines.add('- Selisih ($status): ${fmt.format(balance.abs())}');
    if (topCat != null) {
      lines.add(
        '- Kategori pengeluaran terbesar: ${topCat.key} (${fmt.format(topCat.value)})',
      );
    }
    lines.add('- Pengeluaran bulan ini: ${fmt.format(thisExp)} ($change)');
    return lines.join('\n');
  }

  // ── B. Spending Analysis ─────────────────────────────────────────────

  String _spendingAnalysis(List<TransactionModel> txs, CurrencyFormatter fmt) {
    final expenses = txs.where((t) => t.type == 'expense').toList();
    if (expenses.isEmpty) return 'Belum ada pengeluaran yang tercatat.';

    final total = expenses.fold(0.0, (s, t) => s + t.amount);

    // Category breakdown
    final byCat = <String, double>{};
    for (final t in expenses) {
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
    }
    final sorted = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final lines = <String>['Analisis Pengeluaran', ''];
    lines.add('Total pengeluaran: ${fmt.format(total)}');
    lines.add('');
    lines.add('Rincian per kategori:');
    for (final e in sorted.take(5)) {
      final pct = ((e.value / total) * 100).toStringAsFixed(1);
      lines.add('- ${e.key}: ${fmt.format(e.value)} ($pct%)');
    }

    // Daily trend (last 7 days)
    final now = DateTime.now();
    final dailyTotals = <double>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dayTotal = expenses
          .where(
            (t) =>
                t.date.year == d.year &&
                t.date.month == d.month &&
                t.date.day == d.day,
          )
          .fold(0.0, (s, t) => s + t.amount);
      dailyTotals.add(dayTotal);
    }
    final avgDaily = dailyTotals.reduce((a, b) => a + b) / 7;
    lines.add('');
    lines.add('Rata-rata pengeluaran harian (7 hari): ${fmt.format(avgDaily)}');

    // Recommendation
    if (sorted.isNotEmpty) {
      final top = sorted.first;
      final topPct = ((top.value / total) * 100).round();
      if (topPct > 40) {
        lines.add('');
        lines.add(
          'Rekomendasi: Kategori "${top.key}" mendominasi pengeluaran kamu ($topPct%). Pertimbangkan untuk evaluasi area ini.',
        );
      } else {
        lines.add('');
        lines.add(
          'Rekomendasi: Distribusi pengeluaran kamu cukup merata. Tidak ada kategori yang mendominasi berlebihan.',
        );
      }
    }
    return lines.join('\n');
  }

  // ── C. Budget Intelligence ───────────────────────────────────────────

  String _budgetIntelligence(
    List<TransactionModel> txs,
    CurrencyFormatter fmt,
  ) {
    final now = DateTime.now();
    final monthTxs = txs.where(
      (t) => t.date.month == now.month && t.date.year == now.year,
    );
    final monthExpense = monthTxs
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final monthIncome = monthTxs
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);

    final lines = <String>['Cek Anggaran', ''];
    lines.add('- Pemasukan bulan ini: ${fmt.format(monthIncome)}');
    lines.add('- Pengeluaran bulan ini: ${fmt.format(monthExpense)}');

    if (monthIncome > 0) {
      final usedPct = ((monthExpense / monthIncome) * 100).toStringAsFixed(1);
      lines.add('- Persentase anggaran terpakai: $usedPct%');

      final remaining = monthIncome - monthExpense;
      lines.add('- Sisa anggaran: ${fmt.format(remaining)}');

      // Projection to end of month
      final daysPassed = now.day;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dailyRate = daysPassed > 0 ? monthExpense / daysPassed : 0.0;
      final projected = dailyRate * daysInMonth;
      lines.add('- Proyeksi pengeluaran akhir bulan: ${fmt.format(projected)}');

      final pctNum = double.parse(usedPct);
      if (pctNum >= 90) {
        lines.add('');
        lines.add(
          'Peringatan: Anggaran hampir habis ($usedPct%). Segera kurangi pengeluaran non-esensial.',
        );
      } else if (pctNum >= 70) {
        lines.add('');
        lines.add(
          'Perhatian: Pengeluaran sudah mencapai $usedPct% dari pemasukan. Batasi pengeluaran besar.',
        );
      } else {
        lines.add('');
        lines.add('Status: Anggaran masih dalam batas aman ($usedPct%).');
      }
    } else {
      lines.add(
        '- Belum ada pemasukan bulan ini. Catat pemasukan untuk mendapat analisis anggaran.',
      );
    }
    return lines.join('\n');
  }

  // ── D. Transaction Insights ──────────────────────────────────────────

  String _transactionInsights(
    List<TransactionModel> txs,
    CurrencyFormatter fmt,
  ) {
    if (txs.isEmpty) return 'Belum ada transaksi yang tercatat.';

    final lines = <String>['Pola Transaksi', ''];

    // Largest transaction
    final expenses = txs.where((t) => t.type == 'expense').toList();
    if (expenses.isNotEmpty) {
      final largest = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
      lines.add('Transaksi terbesar:');
      lines.add(
        '- ${largest.categoryId}: ${fmt.format(largest.amount)} (${largest.date.day}/${largest.date.month})',
      );
      lines.add('');
    }

    // Duplicate detection (same amount + same category within 3 days)
    final duplicates = <String>[];
    for (int i = 0; i < expenses.length; i++) {
      for (int j = i + 1; j < expenses.length; j++) {
        final a = expenses[i];
        final b = expenses[j];
        if (a.amount == b.amount &&
            a.categoryId == b.categoryId &&
            (a.date.difference(b.date).inHours).abs() < 72) {
          duplicates.add(
            '- ${a.categoryId}: ${fmt.format(a.amount)} pada ${a.date.day}/${a.date.month} dan ${b.date.day}/${b.date.month}',
          );
        }
      }
    }
    if (duplicates.isNotEmpty) {
      lines.add('Kemungkinan transaksi ganda:');
      lines.addAll(duplicates.take(3));
      lines.add('');
    }

    // Average expense vs outliers
    if (expenses.isNotEmpty) {
      final avg = expenses.fold(0.0, (s, t) => s + t.amount) / expenses.length;
      final outliers = expenses.where((t) => t.amount > avg * 2.5).toList();
      if (outliers.isNotEmpty) {
        lines.add('Transaksi menyimpang dari rata-rata (${fmt.format(avg)}):');
        for (final o in outliers.take(3)) {
          lines.add(
            '- ${o.categoryId}: ${fmt.format(o.amount)} (${o.date.day}/${o.date.month})',
          );
        }
      } else {
        lines.add(
          'Tidak ada transaksi yang menyimpang signifikan dari rata-rata (${fmt.format(avg)}).',
        );
      }
    }

    return lines.join('\n');
  }

  // ── F. Saving Rate Analysis ─────────────────────────────────────────

  String _savingRateAnalysis(
    List<TransactionModel> txs,
    CurrencyFormatter fmt,
  ) {
    if (txs.isEmpty) {
      return 'Belum ada transaksi.\n\nCatat pemasukan dan pengeluaran untuk menghitung saving rate kamu.';
    }

    final now = DateTime.now();

    // ── Hitung per bulan (3 bulan terakhir) ───────────────────────
    final monthlyData = <String, Map<String, double>>{};
    for (int m = 0; m < 3; m++) {
      final month = DateTime(now.year, now.month - m, 1);
      final key = '${_monthName(month.month)} ${month.year}';
      final monthTxs = txs.where(
        (t) => t.date.month == month.month && t.date.year == month.year,
      );
      final inc = monthTxs
          .where((t) => t.type == 'income')
          .fold(0.0, (s, t) => s + t.amount);
      final exp = monthTxs
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);
      if (inc > 0 || exp > 0) {
        monthlyData[key] = {'income': inc, 'expense': exp};
      }
    }

    // ── Total keseluruhan ─────────────────────────────────────────
    final totalIncome = txs
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = txs
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final totalBalance = totalIncome - totalExpense;
    final overallRate = totalIncome > 0
        ? (totalBalance / totalIncome * 100)
        : 0.0;

    final lines = <String>['Hitung Saving Rate', ''];

    // ── Per-bulan breakdown ───────────────────────────────────────
    if (monthlyData.isNotEmpty) {
      lines.add('Saving Rate per Bulan:');
      for (final entry in monthlyData.entries) {
        final inc = entry.value['income']!;
        final exp = entry.value['expense']!;
        final bal = inc - exp;
        final rate = inc > 0 ? (bal / inc * 100) : 0.0;
        final rateStr = rate.toStringAsFixed(1);
        final statusIcon = rate >= 20
            ? '(Sehat)'
            : rate >= 0
            ? '(Cukup)'
            : '(Defisit)';
        lines.add(
          '- ${entry.key}: $rateStr% $statusIcon'
          '\n  Masuk ${fmt.format(inc)}, Keluar ${fmt.format(exp)}, Tabungan ${fmt.format(bal)}',
        );
      }
      lines.add('');
    }

    // ── Ringkasan total ───────────────────────────────────────────
    lines.add('Ringkasan Total:');
    lines.add('- Total Pemasukan: ${fmt.format(totalIncome)}');
    lines.add('- Total Pengeluaran: ${fmt.format(totalExpense)}');
    lines.add('- Total Tabungan: ${fmt.format(totalBalance)}');
    lines.add('- Saving Rate: ${overallRate.toStringAsFixed(1)}%');
    lines.add('');

    // ── Interpretasi ─────────────────────────────────────────────
    lines.add('Interpretasi:');
    if (totalIncome == 0) {
      lines.add(
        '- Belum ada pemasukan tercatat. Catat pemasukan untuk hasil yang akurat.',
      );
    } else if (overallRate >= 30) {
      lines.add(
        '- Saving rate ${overallRate.toStringAsFixed(1)}% — Luar biasa! Jauh di atas standar ideal 20%.',
      );
      lines.add('- Pertimbangkan untuk menginvestasikan kelebihan tabungan.');
    } else if (overallRate >= 20) {
      lines.add(
        '- Saving rate ${overallRate.toStringAsFixed(1)}% — Sehat. Kamu memenuhi standar ideal 20%.',
      );
      lines.add('- Pertahankan kebiasaan ini konsisten setiap bulan.');
    } else if (overallRate >= 10) {
      lines.add(
        '- Saving rate ${overallRate.toStringAsFixed(1)}% — Cukup, tapi masih di bawah ideal 20%.',
      );
      lines.add(
        '- Target: hemat ${fmt.format(totalIncome * 0.20 - totalBalance)} lagi untuk capai 20%.',
      );
    } else if (overallRate > 0) {
      lines.add(
        '- Saving rate ${overallRate.toStringAsFixed(1)}% — Rendah. Perlu evaluasi pengeluaran.',
      );
      lines.add(
        '- Coba terapkan aturan 50/30/20: 50% kebutuhan, 30% keinginan, 20% tabungan.',
      );
    } else {
      lines.add('- Saving rate negatif — pengeluaran melebihi pemasukan.');
      lines.add(
        '- Prioritas: identifikasi dan pangkas pengeluaran tidak esensial segera.',
      );
    }

    return lines.join('\n');
  }

  static String _monthName(int month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return month >= 1 && month <= 12 ? names[month] : '$month';
  }

  // ── E. Financial Health Check ────────────────────────────────────────

  String _financialHealthCheck(
    List<TransactionModel> txs,
    CurrencyFormatter fmt,
  ) {
    final income = txs
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final balance = income - expense;

    final lines = <String>['Cek Kesehatan Keuangan', ''];

    // Status
    if (income == 0 && expense == 0) {
      lines.add(
        'Belum ada transaksi yang tercatat. Mulai catat pemasukan dan pengeluaran untuk mendapat analisis.',
      );
      return lines.join('\n');
    }

    lines.add('- Total Pemasukan: ${fmt.format(income)}');
    lines.add('- Total Pengeluaran: ${fmt.format(expense)}');
    lines.add('- Saldo: ${fmt.format(balance)}');

    if (expense > income && income > 0) {
      lines.add('- Status: Defisit (pengeluaran melebihi pemasukan)');
      lines.add('');
      lines.add('Peringatan: Keuangan dalam kondisi defisit. Prioritas:');
      lines.add('1. Identifikasi pengeluaran yang bisa dipangkas');
      lines.add('2. Fokus pada kebutuhan, tunda keinginan');
      lines.add('3. Tingkatkan pemasukan atau tambah sumber pendapatan');
    } else if (income > 0) {
      final savingRate = ((balance / income) * 100).toStringAsFixed(1);
      lines.add('- Saving rate: $savingRate%');
      lines.add('- Status: Surplus');

      final sr = double.parse(savingRate);
      lines.add('');
      if (sr >= 20) {
        lines.add(
          'Kondisi keuangan sehat. Saving rate di atas 20% adalah prestasi yang baik.',
        );
        lines.add(
          'Prioritas: Pertahankan kebiasaan ini dan pertimbangkan untuk berinvestasi.',
        );
      } else if (sr >= 10) {
        lines.add(
          'Kondisi keuangan cukup baik, tapi saving rate masih di bawah ideal.',
        );
        lines.add(
          'Prioritas: Tingkatkan saving rate minimal ke 20% dengan mengurangi pengeluaran non-esensial.',
        );
      } else {
        lines.add(
          'Kondisi keuangan perlu perhatian. Saving rate terlalu rendah.',
        );
        lines.add(
          'Prioritas: Audit pengeluaran, identifikasi area pemborosan, dan tetapkan target tabungan bulanan.',
        );
      }
    }

    // Consistency check
    final now = DateTime.now();
    final months = <int>{};
    for (final t in txs) {
      if (t.date.year == now.year) months.add(t.date.month);
    }
    if (months.length >= 3) {
      lines.add('');
      lines.add(
        'Konsistensi: Kamu aktif mencatat transaksi di $months bulan tahun ini. Pertahankan kebiasaan ini.',
      );
    } else {
      lines.add('');
      lines.add(
        'Konsistensi: Rajinlah mencatat transaksi setiap hari untuk mendapat analisis yang lebih akurat.',
      );
    }

    return lines.join('\n');
  }

  // ── Developer chat mode: keyword-based intent ───────────────────────

  Stream<String> streamResponse({
    required String userMessage,
    required String sessionId,
  }) async* {
    final transactions = await _ref.read(transactionsProvider.future);
    final settings = _ref.read(settingsProvider);
    final fmt = CurrencyFormatter.from(settings);

    final lower = userMessage.toLowerCase();
    if (_greetingKw.any(lower.contains)) {
      yield _greetingResponse();
      return;
    }
    if (_summaryKw.any(lower.contains)) {
      yield _financialOverview(transactions, fmt);
      return;
    }
    if (_spendingKw.any(lower.contains)) {
      yield _spendingAnalysis(transactions, fmt);
      return;
    }
    if (_incomeKw.any(lower.contains)) {
      yield _incomeAnalysis(transactions, fmt);
      return;
    }
    if (_tipKw.any(lower.contains)) {
      yield _financialHealthCheck(transactions, fmt);
      return;
    }
    yield 'Maaf, saya belum mengerti pertanyaanmu. Coba tanyakan tentang:\n'
        '- Saldo atau ringkasan\n'
        '- Pengeluaran terbesar\n'
        '- Pemasukan\n'
        '- Tips hemat';
  }

  String _greetingResponse() {
    return 'Halo! Saya Noir, asisten keuangan pribadi kamu.\n\n'
        'Berikut beberapa hal yang bisa saya bantu secara otomatis:\n\n'
        '- Mencatat Pengeluaran: Ketik "Beli Kopi 25rb" atau "Makan siang 15000"\n'
        '- Mencatat Pemasukan: Ketik "Gaji 5jt" atau "Bonus proyek 500rb"\n'
        '- Cek Sisa Saldo: Tanya "Berapa sisa uangku?" atau "Sisa saldo"\n'
        '- Rekap Pengeluaran: Tanya "Berapa total pengeluaranku?"\n'
        '- Rekap Pemasukan: Tanya "Berapa total pemasukanku?"\n\n'
        'Kamu bisa ketik langsung di kolom chat atau tekan tombol shortcut di bawah.';
  }

  String _incomeAnalysis(List<TransactionModel> txs, CurrencyFormatter fmt) {
    final incomes = txs.where((t) => t.type == 'income');
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
  }
}
