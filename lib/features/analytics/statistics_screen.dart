import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/widgets/micro_interactions.dart';
import 'package:watch_your_money/features/analytics/widgets/chart_data_service.dart';
import 'package:watch_your_money/features/analytics/widgets/statistics_bar_chart.dart';
import 'package:watch_your_money/features/analytics/widgets/statistics_category_list.dart';
import 'package:watch_your_money/features/analytics/widgets/statistics_chart_selector.dart';
import 'package:watch_your_money/features/analytics/widgets/statistics_header.dart';
import 'package:watch_your_money/features/analytics/widgets/statistics_pie_chart.dart';
import 'package:watch_your_money/features/analytics/widgets/statistics_summary_cards.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _period = 'MONTH'; // 'WEEK' | 'MONTH' | 'ALL'
  String _chartType = 'BAR'; // 'BAR' (Diagram Batang) | 'PIE' (Diagram Lingkaran)

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final settings = ref.watch(appSettingsProvider);
    final fmt = CurrencyFormatter.from(settings);
    final t = AppTranslations.of(settings.languageCode);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header Bar ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: StatisticsHeader(
                selectedPeriod: _period,
                onPeriodChanged: (period) => setState(() => _period = period),
              ),
            ),

            // ── Content ─────────────────────────────────────────────
            transactionsAsync.when(
              data: (all) {
                final txs = ChartDataService.filterByPeriod(all, _period);
                final totalIncome = txs
                    .where((tx) => tx.type == 'income')
                    .fold(0.0, (s, tx) => s + tx.amount);
                final totalExpense = txs
                    .where((tx) => tx.type == 'expense')
                    .fold(0.0, (s, tx) => s + tx.amount);
                final byCategory = ChartDataService.groupByCategory(txs);
                final categoryData = ChartDataService.computeCategoryData(
                  byCategory,
                  totalExpense,
                  AppColors.chartPalette,
                );

                return SliverToBoxAdapter(
                  child: StaggeredEntry(
                    staggerDelay: const Duration(milliseconds: 80),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    slideBegin: const Offset(0, 0.12),
                    children: [
                      // ── Inflow & Outflow Summary Cards ─────────────
                      StatisticsSummaryCards(
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                        fmt: fmt,
                        t: t,
                      ),

                      // ── Chart Type Switcher: Batang vs Lingkaran ───
                      StatisticsChartSelector(
                        selectedChartType: _chartType,
                        onChartTypeChanged: (type) => setState(() => _chartType = type),
                      ),

                      // ── Chart Container ────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _chartType == 'BAR'
                            ? StatisticsBarChart(
                                transactions: txs,
                                fmt: fmt,
                                period: _period,
                                weekLabel: t.weekShort,
                              )
                            : StatisticsPieChart(
                                categoryData: categoryData,
                                t: t,
                              ),
                      ),

                      // ── Category Expense Breakdown ─────────────────
                      StatisticsCategoryList(
                        categoryData: categoryData,
                        totalExpense: totalExpense,
                        fmt: fmt,
                        t: t,
                      ),

                      const SizedBox(height: 110),
                    ],
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentWhite,
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: AppColors.negative),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}