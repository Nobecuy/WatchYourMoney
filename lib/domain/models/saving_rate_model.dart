import 'package:hive/hive.dart';

part 'saving_rate_model.g.dart';

/// Represents the result of a saving rate analysis for a specific period.
@HiveType(typeId: 7)
class SavingRateAnalysis extends HiveObject {
  @HiveField(0)
  final String period; // 'week' | 'month' | 'all'

  @HiveField(1)
  final int totalIncome;

  @HiveField(2)
  final int totalExpense;

  @HiveField(3)
  final int netSavings;

  @HiveField(4)
  final double savingRatePercent;

  @HiveField(5)
  final SavingRateCategory category;

  @HiveField(6)
  final DateTime calculatedAt;

  @HiveField(7)
  final Map<String, int> topExpenseCategories; // categoryId -> amount

  @HiveField(8)
  final Map<String, int> topIncomeCategories; // categoryId -> amount

  SavingRateAnalysis({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingRatePercent,
    required this.category,
    required this.calculatedAt,
    required this.topExpenseCategories,
    required this.topIncomeCategories,
  });

  /// Create from raw calculation data.
  factory SavingRateAnalysis.fromCalculation({
    required String period,
    required int totalIncome,
    required int totalExpense,
    required Map<String, int> topExpenseCategories,
    required Map<String, int> topIncomeCategories,
  }) {
    final netSavings = totalIncome - totalExpense;
    final savingRatePercent = totalIncome > 0 && netSavings > 0
        ? (netSavings / totalIncome * 100)
        : 0.0;
    final category = SavingRateCategory.fromPercent(savingRatePercent);

    return SavingRateAnalysis(
      period: period,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSavings: netSavings,
      savingRatePercent: savingRatePercent,
      category: category,
      calculatedAt: DateTime.now(),
      topExpenseCategories: topExpenseCategories,
      topIncomeCategories: topIncomeCategories,
    );
  }

  /// Formatted strings for display.
  String get formattedTotalIncome => _formatCurrency(totalIncome);
  String get formattedTotalExpense => _formatCurrency(totalExpense);
  String get formattedNetSavings => _formatCurrency(netSavings);
  String get formattedSavingRate => '${savingRatePercent.toStringAsFixed(1)}%';

  /// Status label with percentage (e.g., "Sangat Sehat (32%)")
  String get statusLabel => '${category.label} ($formattedSavingRate)';

  /// Short summary for AI context.
  Map<String, dynamic> toAiContext() {
    return {
      'period': period,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'net_savings': netSavings,
      'saving_rate_percent': savingRatePercent,
      'saving_rate_formatted': formattedSavingRate,
      'category': category.name,
      'category_label': category.label,
      'status_label': statusLabel,
      'top_expense_categories': topExpenseCategories,
      'top_income_categories': topIncomeCategories,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp $amount';
  }
}

/// Financial health categories based on saving rate percentage.
@HiveType(typeId: 8)
enum SavingRateCategory {
  @HiveField(0)
  deficit, // < 0%

  @HiveField(1)
  poor, // 0% - 10%

  @HiveField(2)
  standard, // 10% - 20%

  @HiveField(3)
  good, // 20% - 50%

  @HiveField(4)
  excellent; // > 50%

  /// Determine category from saving rate percentage.
  static SavingRateCategory fromPercent(double percent) {
    if (percent < 0) return SavingRateCategory.deficit;
    if (percent < 10) return SavingRateCategory.poor;
    if (percent < 20) return SavingRateCategory.standard;
    if (percent < 50) return SavingRateCategory.good;
    return SavingRateCategory.excellent;
  }

  /// Human-readable label in Indonesian.
  String get label {
    switch (this) {
      case SavingRateCategory.deficit:
        return 'Defisit';
      case SavingRateCategory.poor:
        return 'Kurang';
      case SavingRateCategory.standard:
        return 'Standar';
      case SavingRateCategory.good:
        return 'Sangat Baik';
      case SavingRateCategory.excellent:
        return 'Luar Biasa';
    }
  }

  /// Detailed description for AI interpretation.
  String get description {
    switch (this) {
      case SavingRateCategory.deficit:
        return 'Pengeluaran melebihi pemasukan. Kondisi darurat, perlu tindakan segera.';
      case SavingRateCategory.poor:
        return 'Saving rate sangat rendah (0-10%). Belum ideal untuk dana darurat/investasi. Risiko tinggi jika ada kejutan finansial.';
      case SavingRateCategory.standard:
        return 'Saving rate cukup baik (10-20%). Sesuai aturan keuangan umum 50/30/20, tapi masih ruang perbaikan.';
      case SavingRateCategory.good:
        return 'Saving rate sangat sehat (20-50%). Mempercepat pencapaian target tabungan dan investasi.';
      case SavingRateCategory.excellent:
        return 'Saving rate luar biasa (>50%). Percepat alokasi investasi dan pelunasan kewajiban.';
    }
  }

  /// Recommended actions for this category.
  List<String> get recommendedActions {
    switch (this) {
      case SavingRateCategory.deficit:
        return [
          'Identifikasi & potong pengeluaran non-esensial segera',
          'Cari sumber pendapatan tambahan (side hustle, overtime)',
          'Tunda pembelian besar & cicilan baru',
          'Evaluasi langganan & keanggotaan yang tidak digunakan',
        ];
      case SavingRateCategory.poor:
        return [
          'Targetkan saving rate minimal 10% sebagai langkah awal',
          'Audit pengeluaran kategori terbesar untuk efisiensi',
          'Gunakan aturan 50/30/20: 50% kebutuhan, 30% keinginan, 20% tabungan',
          'Otomatisasi transfer tabungan saat gajian',
        ];
      case SavingRateCategory.standard:
        return [
          'Tingkatkan target saving rate ke 20%+ (zona sehat)',
          'Optimalkan pengeluaran variabel (makan di luar, hiburan)',
          'Mulai bangun dana darurat 3-6x pengeluaran bulanan',
          'Pertimbangkan investasi risiko rendah (reksa dana pasar uang)',
        ];
      case SavingRateCategory.good:
        return [
          'Pertahankan disiplin & tingkatkan ke 30%+ jika memungkinkan',
          'Alokasikan surplus ke investasi beragam (saham, reksa dana, emas)',
          'Percepat pelunasan hutang berjangka (jika ada)',
          'Tetapkan financial goals jangka menengah (DP rumah, pendidikan, dll)',
        ];
      case SavingRateCategory.excellent:
        return [
          'Maksimalkan pengembalian via investasi diversified portfolio',
          'Pertimbangkan tax-efficient investing',
          'Banguns passive income streams',
          'Legacy planning & wealth protection (asuransi, wasiat)',
        ];
    }
  }

  /// Color hex for UI representation.
  String get colorHex {
    switch (this) {
      case SavingRateCategory.deficit:
        return '#EF4444'; // Red
      case SavingRateCategory.poor:
        return '#F97316'; // Orange
      case SavingRateCategory.standard:
        return '#EAB308'; // Yellow
      case SavingRateCategory.good:
        return '#22C55E'; // Green
      case SavingRateCategory.excellent:
        return '#3B82F6'; // Blue
    }
  }
}