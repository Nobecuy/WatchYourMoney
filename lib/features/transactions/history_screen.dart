import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _typeFilter = 'ALL';
  String _paymentFilter = 'ALL';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _typeFilters = ['ALL', 'INCOME', 'EXPENSE'];
  static const _paymentFilters = ['ALL', 'CASH', 'CARD'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> all) {
    return all.where((t) {
      final typeMatch = _typeFilter == 'ALL' || t.type.toUpperCase() == _typeFilter;
      final payMatch = _paymentFilter == 'ALL' || t.paymentMethod.toUpperCase() == _paymentFilter;
      final searchMatch = _searchQuery.isEmpty ||
          t.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.categoryId.toLowerCase().contains(_searchQuery.toLowerCase());
      return typeMatch && payMatch && searchMatch;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Transactions',
                style: Theme.of(context).textTheme.headlineLarge,
              ).animate().fadeIn(duration: 300.ms),
            ),

            // ── Search Bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: NeumorphicContainer(
                isPressed: true,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                borderRadius: 12,
                clipBehavior: Clip.antiAlias,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            ),

            // ── Type Filter Chips ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 0, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._typeFilters.map((f) => _buildFilterChip(f, f == _typeFilter, () => setState(() => _typeFilter = f))),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 20, color: AppColors.surfaceBright),
                    const SizedBox(width: 8),
                    ..._paymentFilters.skip(1).map((f) => _buildFilterChip(f, f == _paymentFilter, () => setState(() => _paymentFilter = f))),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
            ),
            const SizedBox(height: 12),

            // ── Transaction List ────────────────────────────────
            Expanded(
              child: transactionsAsync.when(
                data: (all) {
                  final filtered = _applyFilters(all);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off, color: AppColors.textMuted, size: 40),
                          const SizedBox(height: 12),
                          Text('Tidak ada transaksi', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildTxItem(filtered[i], i),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textSecondary, strokeWidth: 1.5,
                  ),
                ),
                error: (err, _) => Center(child: Text('$err', style: Theme.of(context).textTheme.bodySmall)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.surfaceBright : const Color(0x0FFFFFFF),
            ),
            boxShadow: selected ? [
              const BoxShadow(color: AppColors.shadowDark, offset: Offset(2, 2), blurRadius: 6),
            ] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTxItem(TransactionModel tx, int index) {
    final isIncome = tx.type == 'income';
    final color = isIncome ? AppColors.positive : AppColors.negative;

    return Dismissible(
      key: Key(tx.id),
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: AppColors.negative, size: 20),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteDialog(context),
      onDismissed: (_) => _deleteTransaction(tx.id),
      child: NeumorphicContainer(
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
              child: Icon(_categoryIcon(tx.categoryId), color: color, size: 16),
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
                    '${tx.date.day}/${tx.date.month}/${tx.date.year} · ${tx.paymentMethod.toUpperCase()}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'} Rp ${_fmt(tx.amount)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 40).ms, duration: 250.ms).slideY(begin: 0.05),
    );
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}rb';
    return amount.toStringAsFixed(0);
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food': return Icons.restaurant_outlined;
      case 'transport': return Icons.directions_car_outlined;
      case 'salary': return Icons.account_balance_outlined;
      case 'entertainment': return Icons.movie_outlined;
      case 'shopping': return Icons.shopping_bag_outlined;
      case 'health': return Icons.favorite_outline;
      default: return Icons.receipt_outlined;
    }
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 40),
              const SizedBox(height: 16),
              const Text('Hapus Transaksi?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Tindakan ini tidak bisa dibatalkan.', style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: NeumorphicContainer(
                      onTap: () => Navigator.pop(context, false),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      borderRadius: 12,
                      child: const Center(child: Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeumorphicContainer(
                      onTap: () => Navigator.pop(context, true),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      borderRadius: 12,
                      backgroundColor: AppColors.surfaceBright,
                      child: const Center(child: Text('Hapus', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteTransaction(String id) async {
    await ref.read(transactionRepositoryProvider).deleteTransaction(id);
    ref.invalidate(transactionsProvider);
  }
}
