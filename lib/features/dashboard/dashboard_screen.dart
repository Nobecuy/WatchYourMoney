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
import 'package:watch_your_money/features/wallet/adjust_balance_modal.dart';
import 'package:watch_your_money/features/transactions/add_transaction_modal.dart';
import 'package:watch_your_money/features/ai_assistant/ai_assistant_screen.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/tips/app_tips.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showBalance = true;
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    // Rotate tips every 8 seconds quietly in background
    Future.delayed(const Duration(seconds: 8), _rotateTip);
  }

  void _rotateTip() {
    if (!mounted) return;
    setState(() {
      _tipIndex = (_tipIndex + 1) % AppTips.all.length;
    });
    Future.delayed(const Duration(seconds: 8), _rotateTip);
  }

  void _onProfileTap(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowDark,
                                offset: Offset(3, 3),
                                blurRadius: 8,
                              ),
                              BoxShadow(
                                color: AppColors.shadowLight,
                                offset: Offset(-2, -2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Brand text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'watch',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                            ),
                            Text(
                              'your money',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 8,
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x1A10B981),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0x3310B981)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '● ',
                                style: TextStyle(
                                  color: AppColors.positive,
                                  fontSize: 8,
                                ),
                              ),
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
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
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
                child: transactionsAsync
                    .when(
                      data: (transactions) =>
                          _buildBalanceCard(context, transactions, fmt, t),
                      loading: () => _buildBalanceCard(context, [], fmt, t),
                      error: (e, st) => _buildBalanceCard(context, [], fmt, t),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 350.ms)
                    .slideY(begin: 0.1),
              ),
            ),

            // ── Quick Actions ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child:
                    Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickAction(
                              icon: Icons.credit_card_rounded,
                              label: t.recordCard,
                              color: const Color(0xFF818CF8),
                              onTap: () =>
                                  _openModal('expense', paymentMethod: 'card'),
                            ),
                            _buildQuickAction(
                              icon: Icons.payments_rounded,
                              label: t.recordCash,
                              color: const Color(0xFF34D399),
                              onTap: () =>
                                  _openModal('expense', paymentMethod: 'cash'),
                            ),
                            _buildQuickAction(
                              icon: Icons.add_circle_outline_rounded,
                              label: t.addIncome,
                              color: const Color(0xFFFBBF24),
                              onTap: () => _openModal('income'),
                            ),
                            _buildQuickAction(
                              icon: Icons.auto_awesome_rounded,
                              label: t.askAI,
                              color: const Color(0xFFA78BFA),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AIAssistantScreen(),
                                ),
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 300.ms)
                        .slideY(begin: 0.1),
              ),
            ),

            // ── App Tips ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _buildTipCard(),
              ),
            ),

            // ── Quick Analytics Bar Chart (Diagram Batang) ───────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: transactionsAsync
                    .when(
                      data: (transactions) =>
                          _buildMiniBarChart(transactions, fmt, t),
                      loading: () => const SizedBox(),
                      error: (e, st) => const SizedBox(),
                    )
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 350.ms)
                    .slideY(begin: 0.1),
              ),
            ),

            // ── Recent Transactions Header ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.recentTx.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      t.allLabel,
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
                            const Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.textMuted,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.noTransactions,
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
                      child: _buildTransactionItem(recent[index], index, fmt),
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
                child: Center(
                  child: Text(
                    '$err',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  // ── Tips Card ────────────────────────────────────────────────────────────

  Widget _buildTipCard() {
    final tip = AppTips.all[_tipIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_tipIndex),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x0CFFFFFF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF818CF8).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  _tipIcon(tip.icon),
                  color: const Color(0xFF818CF8),
                  size: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TIPS',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tip.text,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Dot indicator + nav
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _tipIndex = (_tipIndex + 1) % AppTips.all.length;
                  }),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_tipIndex + 1}/${AppTips.all.length}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  IconData _tipIcon(String key) {
    switch (key) {
      case 'swap':
        return Icons.swap_horiz_rounded;
      case 'edit':
        return Icons.edit_rounded;
      case 'ai':
        return Icons.auto_awesome_rounded;
      case 'chart':
        return Icons.bar_chart_rounded;
      case 'stats':
        return Icons.pie_chart_outline_rounded;
      case 'filter':
        return Icons.filter_list_rounded;
      case 'currency':
        return Icons.payments_outlined;
      case 'language':
        return Icons.language_rounded;
      case 'guest':
        return Icons.cloud_off_rounded;
      case 'balance':
        return Icons.visibility_outlined;
      case 'feedback':
        return Icons.feedback_outlined;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  void _openModal(String type, {String? paymentMethod}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionModal(
        initialType: type,
        initialPaymentMethod: paymentMethod,
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          NeumorphicContainer(
            width: 56,
            height: 56,
            borderRadius: 18,
            padding: EdgeInsets.zero,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                ),
                child: Center(child: Icon(icon, color: color, size: 20)),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    List<TransactionModel> transactions,
    CurrencyFormatter fmt,
    AppTranslations t,
  ) {
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;

    // Derived per-method balances (needed for AdjustBalanceModal)
    final cardBalance =
        transactions
            .where((t) => t.paymentMethod == 'card' && t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount) -
        transactions
            .where((t) => t.paymentMethod == 'card' && t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);
    final cashBalance =
        transactions
            .where((t) => t.paymentMethod == 'cash' && t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount) -
        transactions
            .where((t) => t.paymentMethod == 'cash' && t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);

    void openAdjust(String method) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AdjustBalanceModal(
          initialMethod: method,
          currentCardBalance: cardBalance,
          currentCashBalance: cashBalance,
        ),
      );
    }

    return NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  t.netWorth.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit balance dropdown button
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.surfaceContainer,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBright,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                Text(
                                  t.editSaldo,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.pickWallet,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Kartu / Kredit
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    openAdjust('card');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0x226366F1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0x1A6366F1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.credit_card_rounded,
                                            color: Color(0xFF818CF8),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.cardCredit,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                '${t.currentBalance}: ${fmt.compact(cardBalance)}',
                                                style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: AppColors.textMuted,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Uang Tunai
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    openAdjust('cash');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0x2210B981),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0x1A10B981),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.payments_rounded,
                                            color: Color(0xFF34D399),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.cashWalletName,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                '${t.currentBalance}: ${fmt.compact(cashBalance)}',
                                                style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: AppColors.textMuted,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: NeumorphicContainer(
                      width: 36,
                      height: 36,
                      borderRadius: 10,
                      padding: EdgeInsets.zero,
                      child: const Center(
                        child: Icon(
                          Icons.edit_rounded,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showBalance = !_showBalance),
                    child: NeumorphicContainer(
                      width: 36,
                      height: 36,
                      borderRadius: 10,
                      padding: EdgeInsets.zero,
                      child: Center(
                        child: Icon(
                          _showBalance
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _showBalance
                ? Text(
                    key: const ValueKey('shown'),
                    fmt.format(balance),
                    style: TextStyle(
                      color: balance >= 0
                          ? AppColors.textPrimary
                          : AppColors.negativeLight,
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
                  label: t.income.toUpperCase(),
                  amount: totalIncome,
                  color: AppColors.positive,
                  icon: Icons.arrow_downward_rounded,
                  fmt: fmt,
                ),
              ),
              Container(width: 1, height: 42, color: const Color(0x1AFFFFFF)),
              Expanded(
                child: _buildFlowMetric(
                  label: t.expense.toUpperCase(),
                  amount: totalExpense,
                  color: AppColors.negative,
                  icon: Icons.arrow_upward_rounded,
                  fmt: fmt,
                ),
              ),
            ],
          ),

          if (totalIncome + totalExpense > 0) ...[
            const SizedBox(height: 16),
            _buildRatioBar(totalIncome, totalExpense, t),
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
    required CurrencyFormatter fmt,
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
                  fmt.format(amount),
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

  Widget _buildRatioBar(double income, double expense, AppTranslations t) {
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
                '${(incomeRatio * 100).round()}% ${t.income}',
                style: const TextStyle(
                  color: AppColors.positive,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${100 - (incomeRatio * 100).round()}% ${t.expense}',
                style: const TextStyle(
                  color: AppColors.negative,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniBarChart(
    List<TransactionModel> transactions,
    CurrencyFormatter fmt,
    AppTranslations t,
  ) {
    // Generate data for the last 7 days
    final now = DateTime.now();
    final List<Map<String, dynamic>> dailyData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTxs = transactions.where(
        (t) =>
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day,
      );

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.cashFlow7d.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.cashFlowSubtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot(t.income, AppColors.positive),
                  const SizedBox(width: 8),
                  _buildLegendDot(t.expense, AppColors.negative),
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
                        '${isIncome ? "${t.income}: " : "${t.expense}: "}${fmt.format(val)}',
                        TextStyle(
                          color: isIncome
                              ? AppColors.positive
                              : AppColors.negative,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      // Bar Pengeluaran (Rose)
                      BarChartRodData(
                        toY: data['expense'] as double,
                        color: AppColors.negative,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
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
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    TransactionModel tx,
    int index,
    CurrencyFormatter fmt,
  ) {
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
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('dd MMM').format(tx.date)} · ${tx.paymentMethod.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
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
        )
        .animate()
        .fadeIn(delay: (index * 60).ms, duration: 250.ms)
        .slideX(begin: 0.04);
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
