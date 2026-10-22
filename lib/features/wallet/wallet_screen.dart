import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/auth/auth_provider.dart';
import 'package:watch_your_money/features/auth/auth_screen.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';
import 'package:watch_your_money/features/wallet/adjust_balance_modal.dart';
import 'package:watch_your_money/features/profile/profile_screen.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isBalanceVisible = true;
  int _currentCardIndex = 0;
  String _selectedFilter = 'all'; // 'all' | 'card' | 'cash'
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final t = AppTranslations.of(ref.read(appSettingsProvider).languageCode);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.negativeLight,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              t.logoutConfirm,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          t.logoutMessage,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              t.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.logout),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      ref.read(authProvider.notifier).setLoggedOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  void _openAdjustBalance({
    required String initialMethod,
    required double cardBalance,
    required double cashBalance,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdjustBalanceModal(
        initialMethod: initialMethod,
        currentCardBalance: cardBalance,
        currentCashBalance: cashBalance,
      ),
    );
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
        child: transactionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentWhite),
          ),
          error: (e, st) => Center(
            child: Text(
              'Gagal memuat wallet: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          data: (transactions) {
            // Calculate balances
            double cardIncome = 0;
            double cardExpense = 0;
            double cashIncome = 0;
            double cashExpense = 0;

            for (final tx in transactions) {
              if (tx.paymentMethod == 'card') {
                if (tx.type == 'income') {
                  cardIncome += tx.amount;
                } else {
                  cardExpense += tx.amount;
                }
              } else {
                if (tx.type == 'income') {
                  cashIncome += tx.amount;
                } else {
                  cashExpense += tx.amount;
                }
              }
            }

            final cardBalance = cardIncome - cardExpense;
            final cashBalance = cashIncome - cashExpense;
            final totalBalance = cardBalance + cashBalance;

            // Filter transactions
            final filteredTransactions = transactions.where((tx) {
              if (_selectedFilter == 'card') return tx.paymentMethod == 'card';
              if (_selectedFilter == 'cash') return tx.paymentMethod == 'cash';
              return true;
            }).toList()..sort((a, b) => b.date.compareTo(a.date));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Header Bar ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  t.myWallet,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1A6366F1),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0x336366F1),
                                    ),
                                  ),
                                  child: const Text(
                                    '2 ACCOUNTS',
                                    style: TextStyle(
                                      color: Color(0xFF818CF8),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.manageWallet,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        NeumorphicContainer(
                          width: 44,
                          height: 44,
                          borderRadius: 999,
                          padding: EdgeInsets.zero,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 250.ms),
                  ),
                ),

                // ── Master Net Worth Banner ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child:
                        _buildTotalNetWorthCard(
                              totalBalance: totalBalance,
                              cardBalance: cardBalance,
                              cashBalance: cashBalance,
                              fmt: fmt,
                              t: t,
                            )
                            .animate()
                            .fadeIn(delay: 50.ms, duration: 300.ms)
                            .slideY(begin: 0.08),
                  ),
                ),

                // ── Section Title: Digital Cards ────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.activeWallet,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Dot indicators for Card PageView
                        Row(
                          children: [
                            _buildPageDot(
                              0,
                              _currentCardIndex == 0,
                              const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 5),
                            _buildPageDot(
                              1,
                              _currentCardIndex == 1,
                              const Color(0xFF10B981),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Interactive Digital Cards Carousel ──────────────
                SliverToBoxAdapter(
                  child:
                      SizedBox(
                            height: 205,
                            child: PageView(
                              controller: _pageController,
                              physics: const BouncingScrollPhysics(),
                              onPageChanged: (index) {
                                setState(() => _currentCardIndex = index);
                              },
                              children: [
                                // Card 1: Debit / Digital Card
                                _buildDebitCard(
                                  balance: cardBalance,
                                  income: cardIncome,
                                  expense: cardExpense,
                                  cardBalance: cardBalance,
                                  cashBalance: cashBalance,
                                  fmt: fmt,
                                  t: t,
                                ),
                                // Card 2: Cash / Dompet Fisik
                                _buildCashCard(
                                  balance: cashBalance,
                                  income: cashIncome,
                                  expense: cashExpense,
                                  cardBalance: cardBalance,
                                  cashBalance: cashBalance,
                                  fmt: fmt,
                                  t: t,
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 300.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                ),

                // ── Filter Segment for Activity ─────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.walletHistory,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x14FFFFFF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFilterPill(t.allLabel, 'all'),
                              _buildFilterPill('💳 ${t.filterCard}', 'card'),
                              _buildFilterPill('💵 ${t.filterCash}', 'cash'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Filtered Transactions List ──────────────────────
                if (filteredTransactions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceContainer,
                              border: Border.all(
                                color: const Color(0x12FFFFFF),
                              ),
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.textMuted,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t.noWalletTx,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.useButtonsAbove,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final tx = filteredTransactions[index];
                        return _buildTransactionItem(tx, index, fmt);
                      }, childCount: filteredTransactions.length),
                    ),
                  ),

                // ── Account & Security Card ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                    child: NeumorphicContainer(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0x1A6366F1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Color(0xFF818CF8),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.securityAccount,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      t.encryptionNote,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: Color(0x14FFFFFF), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    side: const BorderSide(
                                      color: Color(0x1AFFFFFF),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileScreen(),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    t.profile,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.negativeLight,
                                    side: const BorderSide(
                                      color: Color(0x33F43F5E),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _logout(context),
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    t.logout,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Master Net Worth Banner ─────────────────────────────────────────
  Widget _buildTotalNetWorthCard({
    required double totalBalance,
    required double cardBalance,
    required double cashBalance,
    required CurrencyFormatter fmt,
    required AppTranslations t,
  }) {
    // Proportions for visual balance distribution bar
    final totalPositive =
        (cardBalance > 0 ? cardBalance : 0) +
        (cashBalance > 0 ? cashBalance : 0);
    final cardRatio = totalPositive > 0
        ? (cardBalance > 0 ? (cardBalance / totalPositive) : 0.0)
        : 0.5;
    final cashRatio = 1.0 - cardRatio;

    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  t.totalBalance.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x12FFFFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isBalanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isBalanceVisible ? t.hide : t.show,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isBalanceVisible ? fmt.format(totalBalance) : '••••••••',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),

          // Visual distribution bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (cardRatio * 100).toInt().clamp(5, 95),
                    child: Container(color: const Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (cashRatio * 100).toInt().clamp(5, 95),
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${t.cardBalance}: ',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _isBalanceVisible ? fmt.format(cardBalance) : '••••',
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${t.cashBalance}: ',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _isBalanceVisible ? fmt.format(cashBalance) : '••••',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Digital Card: Debit Card (Indigo Luxury) ────────────────────────
  Widget _buildDebitCard({
    required double balance,
    required double income,
    required double expense,
    required double cardBalance,
    required double cashBalance,
    required CurrencyFormatter fmt,
    required AppTranslations t,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E2A72), Color(0xFF1A1744), Color(0xFF0F0E2A)],
        ),
        border: Border.all(color: const Color(0x33818CF8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x406366F1),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF818CF8).withValues(alpha: 0.08),
              ),
            ),
          ),

          // Card Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Chip & Contactless & Brand
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Golden Chip Graphic
                      Container(
                        width: 38,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
                          ),
                          border: Border.all(
                            color: const Color(0x66FFFFFF),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 22,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: const Color(0x55000000),
                                width: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.contactless_rounded,
                        color: Color(0x99FFFFFF),
                        size: 20,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: Text(
                      t.debitPlatinum,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),

              // Middle: Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.cardBalanceLabel,
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _isBalanceVisible ? fmt.format(balance) : '••••••••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openAdjustBalance(
                          initialMethod: 'card',
                          cardBalance: cardBalance,
                          cashBalance: cashBalance,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x33818CF8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x55818CF8)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 11,
                                color: Color(0xFFCDD0FA),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Color(0xFFCDD0FA),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Bottom Row: Masked Number & Cardholder & Flow stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '••••  ••••  ••••  5824',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 12,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.cardHolderName,
                        style: const TextStyle(
                          color: Color(0x77FFFFFF),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildFlowBadge(
                        '+${fmt.compact(income)}',
                        isIncome: true,
                      ),
                      const SizedBox(width: 6),
                      _buildFlowBadge(
                        '-${fmt.compact(expense)}',
                        isIncome: false,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Digital Card: Cash Vault (Emerald Luxury) ───────────────────────
  Widget _buildCashCard({
    required double balance,
    required double income,
    required double expense,
    required double cardBalance,
    required double cashBalance,
    required CurrencyFormatter fmt,
    required AppTranslations t,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF042F2E), Color(0xFF021C1C)],
        ),
        border: Border.all(color: const Color(0x3334D399), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3310B981),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient shapes
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
              ),
            ),
          ),

          // Card Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Cash Icon & Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0x2210B981),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x4410B981)),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF34D399),
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: Text(
                      t.cashWalletLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),

              // Middle: Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.cashBalanceLabel,
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _isBalanceVisible ? fmt.format(balance) : '••••••••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openAdjustBalance(
                          initialMethod: 'cash',
                          cardBalance: cardBalance,
                          cashBalance: cashBalance,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x3334D399),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x5534D399)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 11,
                                color: Color(0xFFAAF0D1),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Color(0xFFAAF0D1),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Bottom Row: Status & Flow stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.casualDailyLabel,
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.cashReady,
                        style: const TextStyle(
                          color: Color(0x77FFFFFF),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildFlowBadge(
                        '+${fmt.compact(income)}',
                        isIncome: true,
                      ),
                      const SizedBox(width: 6),
                      _buildFlowBadge(
                        '-${fmt.compact(expense)}',
                        isIncome: false,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowBadge(String text, {required bool isIncome}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
            .withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isIncome ? const Color(0xFF34D399) : const Color(0xFFFB7185))
              .withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isIncome ? const Color(0xFF34D399) : const Color(0xFFFB7185),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPageDot(int index, bool isActive, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? color : AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  // ── Filter Pill for Transaction List ────────────────────────────────
  Widget _buildFilterPill(String title, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerHigh
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0x22FFFFFF) : Colors.transparent,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Transaction Item ────────────────────────────────────────────────
  Widget _buildTransactionItem(
    TransactionModel tx,
    int index,
    CurrencyFormatter fmt,
  ) {
    final isIncome = tx.type == 'income';
    final isCard = tx.paymentMethod == 'card';

    return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: NeumorphicContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: 16,
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: (isIncome ? AppColors.positive : AppColors.negative)
                        .withValues(alpha: 0.12),
                    border: Border.all(
                      color:
                          (isIncome
                                  ? AppColors.positiveLight
                                  : AppColors.negativeLight)
                              .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _categoryIcon(tx.categoryId),
                      color: isIncome
                          ? AppColors.positiveLight
                          : AppColors.negativeLight,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Note & Date & Method Tag
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.note.isNotEmpty ? tx.note : tx.categoryId,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            DateFormat('d MMM, HH:mm').format(tx.date),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isCard
                                          ? const Color(0xFF6366F1)
                                          : const Color(0xFF10B981))
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    (isCard
                                            ? const Color(0xFF818CF8)
                                            : const Color(0xFF34D399))
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              isCard ? '💳 Card' : '💵 Cash',
                              style: TextStyle(
                                color: isCard
                                    ? const Color(0xFF818CF8)
                                    : const Color(0xFF34D399),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${isIncome ? '+' : '-'} ${fmt.format(tx.amount)}',
                  style: TextStyle(
                    color: isIncome
                        ? AppColors.positiveLight
                        : AppColors.negativeLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 40).clamp(0, 300).ms, duration: 250.ms)
        .slideX(begin: 0.03);
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
      case 'edukasi':
      case 'education':
        return Icons.school_rounded;
      case 'investasi':
        return Icons.trending_up_rounded;
      case 'tagihan':
        return Icons.receipt_long_rounded;
      case 'bonus':
      case 'bonus / freelance':
        return Icons.work_rounded;
      case 'hadiah':
        return Icons.card_giftcard_rounded;
      case 'penjualan':
        return Icons.storefront_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }
}
