import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/i18n/app_translations.dart';
import '../../core/settings/settings_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/history_screen.dart';
import 'analytics/statistics_screen.dart';
import 'wallet/wallet_screen.dart';
import 'goals/screens/goals_screen.dart';
import 'goals/widgets/create_goal_modal.dart';
import 'dashboard/dashboard_provider.dart';
import 'ai_assistant/ai_assistant_screen.dart';
import 'transactions/add_transaction_modal.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isMenuOpen = false;

  late final AnimationController _menuController;
  late final AnimationController _fabController;
  late final Animation<double> _fabRotation;
  late final Animation<double> _backdropOpacity;

  static const Color _panelColor = Color(0xFF191A20);
  static const Color _borderColor = Color(0xFF2D2E36);
  static const Color _mutedColor = Color(0xFF92939F);

  // White theme colors for bubbles
  static const Color _bubbleBgColor = Colors.white;

  static const Color _incomeColor = Color(0xFF45D6A0);
  static const Color _expenseColor = Color(0xFFFF7185);
  static const Color _aiColor = Color(0xFFBE9AFF);
  static const Color _goalColor = Color(0xFFF59E0B);

  late final List<Widget> _pages = [
    const DashboardScreen(),
    const HistoryScreen(),
    const StatisticsScreen(),
    Consumer(builder: (context, ref, _) => const GoalsScreen()),
    Consumer(builder: (context, ref, _) => const WalletScreen()),
  ];

  @override
  void initState() {
    super.initState();

    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _fabRotation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOutCubic),
    );

    _backdropOpacity = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
      return;
    }

    setState(() => _isMenuOpen = true);

    _menuController.forward();
    _fabController.forward();
  }

  Future<void> _closeMenu() async {
    if (!_isMenuOpen) return;

    setState(() => _isMenuOpen = false);

    await Future.wait<void>([
      _menuController.reverse(),
      _fabController.reverse(),
    ]);
  }

  Future<void> _openTransactionModal(String type) async {
    await _closeMenu();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      useSafeArea: true,
      enableDrag: true,
      builder: (_) => AddTransactionModal(initialType: type),
    );
  }

  Future<void> _openAiAssistant() async {
    await _closeMenu();

    if (!mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, secondaryAnimation) =>
            const AIAssistantScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openGoalModal() async {
    await _closeMenu();

    if (!mounted) return;

    final container = ProviderScope.containerOf(context);
    final settings = container.read(settingsProvider);
    final fmt = CurrencyFormatter.from(settings);
    final t = AppTranslations.of(settings.languageCode);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      useSafeArea: true,
      builder: (_) => CreateGoalModal(
        fmt: fmt,
        t: t,
        onSaved: () => container.invalidate(goalsProvider),
      ),
    );
  }

  void _onNavigationTap(int index) {
    if (_currentIndex == index) {
      if (_isMenuOpen) _closeMenu();
      return;
    }

    if (_isMenuOpen) {
      _closeMenu();
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // HALAMAN UTAMA
          Positioned.fill(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),

          // BACKDROP MENU BUBBLE
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _menuController,
              builder: (context, child) {
                return IgnorePointer(
                  ignoring: _menuController.value == 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeMenu,
                    child: Opacity(
                      opacity: _backdropOpacity.value * 0.58,
                      child: const ColoredBox(color: Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),

          // BUBBLE ACTION MENU
          Positioned(
            left: 16,
            right: 16,
            bottom: 104,
            child: AnimatedBuilder(
              animation: _menuController,
              builder: (context, child) {
                return IgnorePointer(
                  ignoring: _menuController.value < 0.85,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBubble(
                        index: 0,
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI Assistant',
                        subtitle: 'Asisten keuangan personal',
                        tag: 'AI',
                        color: _aiColor,
                        onTap: _openAiAssistant,
                      ),
                      const SizedBox(height: 10),
                      _buildBubble(
                        index: 1,
                        icon: Icons.arrow_downward_rounded,
                        title: 'Pengeluaran',
                        subtitle: 'Catat belanja dan tagihan',
                        tag: 'EXPENSE',
                        color: _expenseColor,
                        onTap: () => _openTransactionModal('expense'),
                      ),
                      const SizedBox(height: 10),
                      _buildBubble(
                        index: 2,
                        icon: Icons.arrow_upward_rounded,
                        title: 'Pemasukan',
                        subtitle: 'Catat uang yang masuk',
                        tag: 'INCOME',
                        color: _incomeColor,
                        onTap: () => _openTransactionModal('income'),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ),

          // FLOATING NAVBAR
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAddButton(),
                    const SizedBox(width: 10),

                    // NAVBAR CAPSULE
                    Expanded(
                      child: Container(
                        height: 64,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _panelColor,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: _borderColor, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 28,
                              spreadRadius: -6,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _navItem(0, Icons.grid_view_rounded, 'Home'),
                            _navItem(1, Icons.receipt_long_rounded, 'History'),
                            _navItem(2, Icons.equalizer_rounded, 'Stats'),
                            _navItem(3, Icons.flag_rounded, 'Goals'),
                            _navItem(
                              4,
                              Icons.account_balance_wallet_rounded,
                              'Wallet',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOMBOL TAMBAH
  // ==========================================
  Widget _buildAddButton() {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        final isOpen = _isMenuOpen;

        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _toggleMenu,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.10),
                    blurRadius: 12,
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: Center(
                child: Transform.rotate(
                  angle: _fabRotation.value * 2 * math.pi,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      isOpen ? Icons.close_rounded : Icons.add_rounded,
                      key: ValueKey<bool>(isOpen),
                      color: const Color(0xFF191A20),
                      size: 29,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // NAVBAR ITEM DENGAN ANIMASI
  // ==========================================
  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onNavigationTap(index),
            borderRadius: BorderRadius.circular(25),
            splashColor: Colors.white.withValues(alpha: 0.06),
            highlightColor: Colors.white.withValues(alpha: 0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        icon,
                        size: 18,
                        color: selected ? Colors.white : _mutedColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      color: selected ? Colors.white : _mutedColor,
                      fontSize: 9,
                      height: 1,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      letterSpacing: selected ? 0.1 : 0,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // INDICATOR AKTIF
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: selected ? 12 : 3,
                    height: 2,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BUBBLE ACTION
  // ==========================================
  Widget _buildBubble({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    required Color color,
    required VoidCallback onTap,
  }) {
    final start = index * 0.14;

    final animation = CurvedAnimation(
      parent: _menuController,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(-14 * (1 - progress), 18 * (1 - progress)),
            child: Transform.scale(
              scale: 0.94 + (0.06 * progress),
              alignment: Alignment.bottomLeft,
              child: child,
            ),
          ),
        );
      },
      child: Row(
        children: [
          // IKON BUBBLE
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _panelColor,
              shape: BoxShape.circle,
              border: Border.all(color: _borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BubbleActionCard(
              title: title,
              subtitle: subtitle,
              tag: tag,
              color: color,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================
// KARTU BUBBLE
// =====================================
class _BubbleActionCard extends StatelessWidget {
  const _BubbleActionCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final Color color;
  final VoidCallback onTap;

  static const Color _panelColor = Color(0xFF191A20);
  static const Color _borderColor = Color(0xFF2D2E36);
  static const Color _mutedColor = Color(0xFF92939F);
  static const Color _textPrimary = Color(0xFFF4F4F6);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        splashColor: Colors.white.withValues(alpha: 0.04),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: _panelColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: color.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _mutedColor,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
