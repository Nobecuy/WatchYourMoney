import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _period = 'MONTH'; // 'WEEK' | 'MONTH' | 'ALL'
  static const _periods = [
    {'key': 'WEEK', 'label': 'Minggu'},
    {'key': 'MONTH', 'label': 'Bulan'},
    {'key': 'ALL', 'label': 'Semua'},
  ];

  String _chartType = 'BAR'; // 'BAR' (Diagram Batang) | 'PIE' (Diagram Lingkaran)

  List<TransactionModel> _filter(List<TransactionModel> all) {
    final now = DateTime.now();
    return all.where((t) {
      if (_period == 'WEEK') {
        return t.date.isAfter(now.subtract(const Duration(days: 7)));
      }
      if (_period == 'MONTH') {
        return t.date.month == now.month && t.date.year == now.year;
      }
      return true;
    }).toList();
  }

  Map<String, double> _groupByCategory(List<TransactionModel> txs) {
    final map = <String, double>{};
    for (final t in txs.where((t) => t.type == 'expense')) {
      final cat = t.categoryId.isEmpty ? 'Lainnya' : t.categoryId;
      map[cat] = (map[cat] ?? 0) + t.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header Bar ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Analitik Keuangan', style: Theme.of(context).textTheme.headlineLarge),
                          const SizedBox(height: 2),
                          const Text(
                            'Pantau arus kas kamu',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Period Filter Selector
                    NeumorphicContainer(
                      isPressed: true,
                      padding: const EdgeInsets.all(3),
                      borderRadius: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _periods.map((p) => _buildPeriodBtn(p['key']!, p['label']!)).toList(),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 250.ms),
              ),
            ),

            // ── Content ─────────────────────────────────────────────
            transactionsAsync.when(
              data: (all) {
                final txs = _filter(all);
                final totalIncome = txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
                final totalExpense = txs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
                final byCategory = _groupByCategory(txs);

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Inflow & Outflow Summary Cards ─────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'PEMASUKAN',
                              amount: totalIncome,
                              color: AppColors.positive,
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'PENGELUARAN',
                              amount: totalExpense,
                              color: AppColors.negative,
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1),
                    ),

                    // ── Chart Type Switcher: Batang vs Lingkaran ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'GRAFIK STATISTIK',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          NeumorphicContainer(
                            isPressed: true,
                            padding: const EdgeInsets.all(3),
                            borderRadius: 12,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildChartTypeBtn('BAR', 'Batang', Icons.bar_chart_rounded),
                                _buildChartTypeBtn('PIE', 'Lingkaran', Icons.pie_chart_outline_rounded),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Chart Container ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: NeumorphicContainer(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(20),
                        child: _chartType == 'BAR'
                            ? _buildBarChart(txs, totalIncome, totalExpense)
                            : _buildPieChart(byCategory, totalIncome, totalExpense),
                      ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                    ),

                    // ── Category Expense Breakdown ─────────────────
                    if (byCategory.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: NeumorphicContainer(
                          borderRadius: 24,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'RINCIAN PENGELUARAN',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${byCategory.length} Kategori',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              ...byCategory.entries.toList().asMap().entries.map((entry) {
                                final index = entry.key;
                                final e = entry.value;
                                final color = AppColors.chartPalette[index % AppColors.chartPalette.length];
                                return _buildCategoryRow(e.key, e.value, totalExpense, color);
                              }),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                      ),

                    const SizedBox(height: 110),
                  ]),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.accentWhite)),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.negative))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodBtn(String key, String label) {
    final active = _period == key;
    return GestureDetector(
      onTap: () => setState(() => _period = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.accentWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accentBlack : AppColors.textMuted,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChartTypeBtn(String key, String label, IconData icon) {
    final active = _chartType == key;
    return GestureDetector(
      onTap: () => setState(() => _chartType = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceContainerHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? AppColors.textPrimary : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return NeumorphicContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<TransactionModel> txs, double totalIncome, double totalExpense) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> barData = [];

    if (_period == 'WEEK') {
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final dayTxs = txs.where((t) => t.date.year == d.year && t.date.month == d.month && t.date.day == d.day);
        final inc = dayTxs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
        final exp = dayTxs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
        barData.add({'label': DateFormat('E').format(d), 'income': inc, 'expense': exp});
      }
    } else if (_period == 'MONTH') {
      for (int w = 1; w <= 4; w++) {
        final startDay = (w - 1) * 7 + 1;
        final endDay = w * 7;
        final weekTxs = txs.where((t) => t.date.day >= startDay && t.date.day <= endDay);
        final inc = weekTxs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
        final exp = weekTxs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
        barData.add({'label': 'Mgg $w', 'income': inc, 'expense': exp});
      }
    } else {
      for (int m = 5; m >= 0; m--) {
        final date = DateTime(now.year, now.month - m, 1);
        final monthTxs = txs.where((t) => t.date.year == date.year && t.date.month == date.month);
        final inc = monthTxs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
        final exp = monthTxs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
        barData.add({'label': DateFormat('MMM').format(date), 'income': inc, 'expense': exp});
      }
    }

    double maxY = 100000;
    for (final b in barData) {
      if ((b['income'] as double) > maxY) maxY = b['income'] as double;
      if ((b['expense'] as double) > maxY) maxY = b['expense'] as double;
    }
    maxY = maxY * 1.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Arus Kas',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDotLegend('Masuk', AppColors.positive),
                const SizedBox(width: 8),
                _buildDotLegend('Keluar', AppColors.negative),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 190,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceContainerHigh,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isIncome = rodIndex == 0;
                    return BarTooltipItem(
                      '${isIncome ? "Masuk: " : "Keluar: "}${CurrencyFormatter.format(rod.toY)}',
                      TextStyle(
                        color: isIncome ? AppColors.positive : AppColors.negative,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < barData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            barData[idx]['label'] as String,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: barData.asMap().entries.map((e) {
                final idx = e.key;
                final data = e.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: data['income'] as double,
                      color: AppColors.positive,
                      width: 9,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                    BarChartRodData(
                      toY: data['expense'] as double,
                      color: AppColors.negative,
                      width: 9,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> byCategory, double totalIncome, double totalExpense) {
    if (byCategory.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Belum ada data pengeluaran', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    final entries = byCategory.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proporsi Pengeluaran per Kategori',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 190,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 46,
              sections: entries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final color = AppColors.chartPalette[idx % AppColors.chartPalette.length];
                final pct = totalExpense > 0 ? (e.value / totalExpense * 100).toStringAsFixed(0) : '0';

                return PieChartSectionData(
                  value: e.value,
                  color: color,
                  title: '$pct%',
                  radius: 46,
                  titleStyle: const TextStyle(
                    color: AppColors.accentWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final color = AppColors.chartPalette[idx % AppColors.chartPalette.length];
            return _buildDotLegend(e.key, color);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDotLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategoryRow(String category, double amount, double totalExpense, Color color) {
    final pct = totalExpense > 0 ? (amount / totalExpense * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.format(amount),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${pct.toStringAsFixed(1)}%)',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppColors.surfaceDim,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
