/// Chart data computation service for Statistics screen.
/// Extracted from StatisticsScreen to separate business logic from UI.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';

class ChartDataPoint {
  final String label;
  final double income;
  final double expense;

  const ChartDataPoint({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class CategoryDataPoint {
  final String category;
  final double amount;
  final Color color;
  final double percentage;

  const CategoryDataPoint({
    required this.category,
    required this.amount,
    required this.color,
    required this.percentage,
  });
}

class ChartDataService {
  /// Filters transactions by period
  static List<TransactionModel> filterByPeriod(
    List<TransactionModel> all,
    String period,
  ) {
    final now = DateTime.now();
    return all.where((t) {
      if (period == 'WEEK') {
        return t.date.isAfter(now.subtract(const Duration(days: 7)));
      }
      if (period == 'MONTH') {
        return t.date.month == now.month && t.date.year == now.year;
      }
      return true;
    }).toList();
  }

  /// Groups expenses by category
  static Map<String, double> groupByCategory(List<TransactionModel> txs) {
    final map = <String, double>{};
    for (final t in txs.where((t) => t.type == 'expense')) {
      final cat = t.categoryId.isEmpty ? 'Lainnya' : t.categoryId;
      map[cat] = (map[cat] ?? 0) + t.amount;
    }
    return map;
  }

  /// Computes bar chart data points based on period
  static List<ChartDataPoint> computeBarChartData(
    List<TransactionModel> txs,
    String period,
    String weekLabel,
  ) {
    final now = DateTime.now();
    final List<ChartDataPoint> barData = [];

    if (period == 'WEEK') {
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final dayTxs = txs.where(
          (t) =>
              t.date.year == d.year &&
              t.date.month == d.month &&
              t.date.day == d.day,
        );
        final inc = dayTxs
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount);
        final exp = dayTxs
            .where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);
        barData.add(
          ChartDataPoint(
            label: DateFormat('E').format(d),
            income: inc,
            expense: exp,
          ),
        );
      }
    } else if (period == 'MONTH') {
      for (int w = 1; w <= 4; w++) {
        final startDay = (w - 1) * 7 + 1;
        final endDay = w * 7;
        final weekTxs = txs.where(
          (t) => t.date.day >= startDay && t.date.day <= endDay,
        );
        final inc = weekTxs
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount);
        final exp = weekTxs
            .where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);
        barData.add(
          ChartDataPoint(label: '$weekLabel $w', income: inc, expense: exp),
        );
      }
    } else {
      for (int m = 5; m >= 0; m--) {
        final date = DateTime(now.year, now.month - m, 1);
        final monthTxs = txs.where(
          (t) => t.date.year == date.year && t.date.month == date.month,
        );
        final inc = monthTxs
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount);
        final exp = monthTxs
            .where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);
        barData.add(
          ChartDataPoint(
            label: DateFormat('MMM').format(date),
            income: inc,
            expense: exp,
          ),
        );
      }
    }

    return barData;
  }

  /// Computes max Y value for chart scaling
  static double computeMaxY(List<ChartDataPoint> barData) {
    double maxY = 100000;
    for (final b in barData) {
      if (b.income > maxY) maxY = b.income;
      if (b.expense > maxY) maxY = b.expense;
    }
    return maxY * 1.25;
  }

  /// Computes category data points with colors and percentages
  static List<CategoryDataPoint> computeCategoryData(
    Map<String, double> byCategory,
    double totalExpense,
    List<Color> chartPalette,
  ) {
    final entries = byCategory.entries.toList();
    return entries.asMap().entries.map((entry) {
      final idx = entry.key;
      final e = entry.value;
      final color = chartPalette[idx % chartPalette.length];
      final pct = totalExpense > 0 ? (e.value / totalExpense * 100) : 0.0;
      return CategoryDataPoint(
        category: e.key,
        amount: e.value,
        color: color,
        percentage: pct,
      );
    }).toList();
  }
}
