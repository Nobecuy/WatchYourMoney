import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/utils/custom_dialog.dart';
import 'package:watch_your_money/core/utils/dynamic_island_alert.dart';
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

  // Local state for filtered transactions to enable instant removal on dismiss
  List<TransactionModel> _localTransactions = [];
  final bool _isLocalInitialized = false;
  // Track deleted transaction IDs to prevent them from reappearing after rebuild
  final Set<String> _deletedIds = {};

  static const _typeFilters = ['ALL', 'INCOME', 'EXPENSE'];
  static const _paymentFilters = ['ALL', 'CASH', 'CARD'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> all) {
    return all.where((t) {
      final typeMatch =
          _typeFilter == 'ALL' || t.type.toUpperCase() == _typeFilter;
      final payMatch =
          _paymentFilter == 'ALL' ||
          t.paymentMethod.toUpperCase() == _paymentFilter;
      final searchMatch =
          _searchQuery.isEmpty ||
          t.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.categoryId.toLowerCase().contains(_searchQuery.toLowerCase());
      return typeMatch && payMatch && searchMatch;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Initialize or update local transaction list from provider data
  void _syncLocalTransactions(List<TransactionModel> all) {
    // Filter out any deleted IDs
    _localTransactions = _applyFilters(all).where((t) => !_deletedIds.contains(t.id)).toList();
  }

  /// Re-apply filters to local transactions (called when search/filter changes)
  void _refreshLocalTransactions() {
    final allTransactions = ref.read(transactionsProvider).value ?? [];
    _localTransactions = _applyFilters(allTransactions).where((t) => !_deletedIds.contains(t.id)).toList();
  }

  /// Remove transaction from local list and sync with repository
  Future<void> _handleDismissed(TransactionModel tx) async {
    // Remove from local list immediately for instant UI feedback
    setState(() {
      _localTransactions.removeWhere((t) => t.id == tx.id);
      _deletedIds.add(tx.id);
    });

    // Delete from repository
    await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);

    // Show success alert
    if (mounted) {
      context.showDynamicIslandSuccess('Transaksi dihapus');
    }

    // Invalidate provider to sync with server (will rebuild and re-sync local list)
    ref.invalidate(transactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final settings = ref.watch(appSettingsProvider);
    final fmt = CurrencyFormatter.from(settings);
    final t = AppTranslations.of(settings.languageCode);

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
                t.transactionsTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ).animate().fadeIn(duration: 300.ms),
            ),

            // ── Search Bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: NeumorphicContainer(
                isPressed: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                borderRadius: 12,
                clipBehavior: Clip.antiAlias,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _refreshLocalTransactions();
                  },
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: t.searchTx,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _refreshLocalTransactions();
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
                    ..._typeFilters.map(
                      (f) => _buildFilterChip(
                        f,
                        f == _typeFilter,
                        () {
                          setState(() => _typeFilter = f);
                          _refreshLocalTransactions();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 20,
                      color: AppColors.surfaceBright,
                    ),
                    const SizedBox(width: 8),
                    ..._paymentFilters.map(
                      (f) => _buildFilterChip(
                        f,
                        f == _paymentFilter,
                        () {
                          setState(() => _paymentFilter = f);
                          _refreshLocalTransactions();
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
            ),
            const SizedBox(height: 12),

            // ── Transaction List ────────────────────────────────
            Expanded(
              child: transactionsAsync.when(
                data: (all) {
                  // Sync local transactions with provider data
                  if (!_isLocalInitialized || _needsResync(all)) {
                    _syncLocalTransactions(all);
                  }
                  final filtered = _localTransactions;
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            color: AppColors.textMuted,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t.noTxFound,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildTxItem(filtered[i], i, fmt),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textSecondary,
                    strokeWidth: 1.5,
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    '$err',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check if we need to resync local transactions with provider data
  bool _needsResync(List<TransactionModel> all) {
    // If provider has more transactions than local, we need to resync
    final filtered = _applyFilters(all);
    if (filtered.length != _localTransactions.length) return true;
    // Check if any transaction IDs differ
    final localIds = _localTransactions.map((t) => t.id).toSet();
    final filteredIds = filtered.map((t) => t.id).toSet();
    return !localIds.containsAll(filteredIds);
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
            color: selected
                ? AppColors.surfaceContainerHigh
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.surfaceBright
                  : const Color(0x0FFFFFFF),
            ),
            boxShadow: selected
                ? [
                    const BoxShadow(
                      color: AppColors.shadowDark,
                      offset: Offset(2, 2),
                      blurRadius: 6,
                    ),
                  ]
                : null,
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

  Widget _buildTxItem(TransactionModel tx, int index, CurrencyFormatter fmt) {
    final isIncome = tx.type == 'income';
    final color = isIncome ? AppColors.positive : AppColors.negative;

    // Build balance change text if available
    final hasBalanceInfo = tx.balanceBefore != 0.0 || tx.balanceAfter != 0.0;
    final balanceText = hasBalanceInfo
        ? '${fmt.format(tx.balanceBefore)} → ${fmt.format(tx.balanceAfter)}'
        : null;

    return Dismissible(
      key: Key(tx.id),
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.negative,
          size: 20,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteDialog(context),
      onDismissed: (_) => _handleDismissed(tx),
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
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.date.day}/${tx.date.month}/${tx.date.year} · ${tx.paymentMethod.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  if (balanceText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      balanceText,
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} ${fmt.format(tx.amount)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 40).ms, duration: 250.ms).slideY(begin: 0.05),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return Icons.restaurant_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'salary':
        return Icons.account_balance_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'health':
        return Icons.favorite_outline;
      default:
        return Icons.receipt_outlined;
    }
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    final t = AppTranslations.of(ref.read(appSettingsProvider).languageCode);
    return showCustomConfirm(
      context: context,
      title: t.deleteTransaction,
      message: t.confirmDelete,
      confirmText: t.delete,
      cancelText: t.cancel,
      isDestructive: true,
      icon: Icons.delete_outline,
      iconColor: AppColors.negativeLight,
    );
  }
}
