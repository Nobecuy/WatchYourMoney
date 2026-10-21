import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';
import 'package:watch_your_money/features/profile/profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showBalance = true;

  void _onProfileTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
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
            // ── Vault Bar Header ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('watchh', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0x1A10B981),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0x3310B981)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('● ', style: TextStyle(color: AppColors.positive, fontSize: 8)),
                              Text(
                                'VAULT ACTIVE',
                                style: TextStyle(
                                  color: AppColors.positive,
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    NeumorphicContainer(
                      width: 40,
                      height: 40,
                      borderRadius: 999,
                      padding: EdgeInsets.zero,
                      onTap: () => _onProfileTap(context),
                      child: Center(
                        child: Icon(Icons.person_outline_rounded, color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
              ),
            ),

            // ── Net Worth Balance Card ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: transactionsAsync.when(
                  data: (transactions) => _buildBalanceCard(context, transactions),
                  loading: () => _buildBalanceCard(context, []),
                  error: (e, st) => _buildBalanceCard(context, []),
                ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.1),
              ),
            ),

            // ── Quick Analytics Bar Chart (Diagram Batang) ───────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: transactionsAsync.when(
                  data: (transactions) => _buildMiniBarChart(transactions),
                  loading: () => const SizedBox(),
                  error: (e, st) => const SizedBox(),
                ).animate().fadeIn(delay: 180.ms, duration: 350.ms).slideY(begin: 0.1),
              ),
            ),

            // ── Recent Transactions Header ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TRANSAKSI TERBARU',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      'Semua',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              ),
            ),

            // ── Transaction List ─────────────────────────────────
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada transaksi',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final recent = transactions.take(5).toList();
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _buildTransactionItem(recent[index], index),
                    ),
                    childCount: recent.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      color: AppColors.accentWhite,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Center(child: Text('$err', style: Theme.of(context).textTheme.bodySmall)),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, List<TransactionModel> transactions) {
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;

    return NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SALDO BERSIH (NET WORTH)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showBalance = !_showBalance),
                child: NeumorphicContainer(
                  width: 36,
                  height: 36,
                  borderRadius: 10,
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: Icon(
                      _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: _showBalance
                ? Text(
                    key: const ValueKey('shown'),
                    CurrencyFormatter.format(balance),
                    style: TextStyle(
                      color: balance >= 0 ? AppColors.textPrimary : AppColors.negativeLight,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  )
                : const Text(
                    key: ValueKey('hidden'),
                    'Rp ••••••••',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          // ── Inflow / Outflow Split Row ────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildFlowMetric(
                  label: 'PEMASUKAN',
                  amount: totalIncome,
                  color: AppColors.positive,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(width: 1, height: 42, color: const Color(0x1AFFFFFF)),
              Expanded(
                child: _buildFlowMetric(
                  label: 'PENGELUARAN',
                  amount: totalExpense,
                  color: AppColors.negative,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),

          if (totalIncome + totalExpense > 0) ...[
            const SizedBox(height: 16),
            _buildRatioBar(totalIncome, totalExpense),
          ],
        ],
      ),
    );
  }

  Widget _buildFlowMetric({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  CurrencyFormatter.format(amount),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioBar(double income, double expense) {
    final total = income + expense;
    final incomeRatio = total > 0 ? (income / total).clamp(0.05, 0.95) : 0.5;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: (incomeRatio * 100).round(),
                  child: Container(color: AppColors.positive),
                ),
                Expanded(
                  flex: 100 - (incomeRatio * 100).round(),
                  child: Container(color: AppColors.negative),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '${(incomeRatio * 100).round()}% Pemasukan',
                style: const TextStyle(color: AppColors.positive, fontSize: 10, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${100 - (incomeRatio * 100).round()}% Pengeluaran',
                style: const TextStyle(color: AppColors.negative, fontSize: 10, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniBarChart(List<TransactionModel> transactions) {
    // Generate data for the last 7 days
    final now = DateTime.now();
    final List<Map<String, dynamic>> dailyData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTxs = transactions.where((t) =>
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day);

      final income = dayTxs
          .where((t) => t.type == 'income')
          .fold(0.0, (sum, t) => sum + t.amount);
      final expense = dayTxs
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);

      dailyData.add({
        'day': DateFormat('E').format(date), // Sen, Sel, etc.
        'income': income,
        'expense': expense,
      });
    }

    double maxY = 100000;
    for (final d in dailyData) {
      if ((d['income'] as double) > maxY) maxY = d['income'] as double;
      if ((d['expense'] as double) > maxY) maxY = d['expense'] as double;
    }
    maxY = maxY * 1.2;

    return NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANALITIK ARUS KAS (7 HARI)',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Arus kas 7 hari terakhir',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot('Masuk', AppColors.positive),
                  const SizedBox(width: 8),
                  _buildLegendDot('Keluar', AppColors.negative),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
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
                      final val = rod.toY;
                      return BarTooltipItem(
                        '${isIncome ? "Masuk: " : "Keluar: "}${CurrencyFormatter.format(val)}',
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
                        if (idx >= 0 && idx < dailyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dailyData[idx]['day'] as String,
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
                barGroups: dailyData.asMap().entries.map((e) {
                  final idx = e.key;
                  final data = e.value;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      // Bar Pemasukan (Green)
                      BarChartRodData(
                        toY: data['income'] as double,
                        color: AppColors.positive,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      // Bar Pengeluaran (Rose)
                      BarChartRodData(
                        toY: data['expense'] as double,
                        color: AppColors.negative,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel tx, int index) {
    final isIncome = tx.type == 'income';
    final color = isIncome ? AppColors.positive : AppColors.negative;

    return NeumorphicContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcon(tx.categoryId),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note.isEmpty ? tx.categoryId : tx.note,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd MMM').format(tx.date)} · ${tx.paymentMethod.toUpperCase()}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(tx.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms, duration: 250.ms).slideX(begin: 0.04);
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
      case 'food':
        return Icons.restaurant_rounded;
      case 'transportasi':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'gaji':
      case 'salary':
        return Icons.payments_rounded;
      case 'hiburan':
      case 'entertainment':
        return Icons.movie_rounded;
      case 'belanja':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'kesehatan':
      case 'health':
        return Icons.local_hospital_rounded;
      case 'investasi':
        return Icons.trending_up_rounded;
      case 'tagihan':
        return Icons.receipt_long_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

}
