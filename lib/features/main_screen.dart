import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/transitions/page_transitions.dart';
import 'package:watch_your_money/core/updates/update_helper.dart';
import 'package:watch_your_money/features/dashboard/dashboard_screen.dart';
import 'package:watch_your_money/features/transactions/history_screen.dart';
import 'package:watch_your_money/features/analytics/statistics_screen.dart';
import 'package:watch_your_money/features/wallet/wallet_screen.dart';
import 'package:watch_your_money/features/ai_assistant/ai_assistant_screen.dart';
import 'package:watch_your_money/features/transactions/add_transaction_modal.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final t = AppTranslations.of(ref.read(settingsProvider).languageCode);
        UpdateHelper.checkForUpdates(context, t: t);
      }
    });
  }

  final List<Widget> _pages = const [
    DashboardScreen(),
    HistoryScreen(),
    StatisticsScreen(),
    WalletScreen(),
  ];

  void _openTransactionModal(String type) {
    setState(() => _isMenuOpen = false);
    context.showAnimatedBottomSheet(
      builder: (context) => AddTransactionModal(initialType: type),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.65),
    );
  }

  void _openAIAssistant() {
    setState(() => _isMenuOpen = false);
    context.pushModalPage(const AIAssistantScreen());
  }

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations.of(ref.watch(settingsProvider).languageCode);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    // Calculate vertical center of the centerDocked FAB (48x48):
    final fabBottomOffset = 56.0 + bottomPadding - 24.0;

    return Stack(
      children: [
        // ── Base Scaffold ──────────────────────────────────────────
        Scaffold(
          backgroundColor: AppColors.surfaceCanvas,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );

              final slideAnimation = Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curvedAnimation);

              final fadeAnimation = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(curvedAnimation);

              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              );
            },
            child: _pages[_currentIndex],
          ),

          // ── Bottom Navigation Bar ────────────────────────────────
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                top: BorderSide(color: Color(0x0FFFFFFF), width: 1),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconSize: 20,
              selectedItemColor: AppColors.accentWhite,
              unselectedItemColor: AppColors.textMuted,
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              onTap: (index) {
                if (_isMenuOpen) setState(() => _isMenuOpen = false);
                setState(() => _currentIndex = index);
              },
              items: [
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 2.5),
                    child: Icon(Icons.dashboard_outlined, size: 20),
                  ),
                  activeIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 2.5),
                    child: Icon(Icons.dashboard_rounded, size: 20),
                  ),
                  label: t.dashboard,
                ),
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 2.5),
                    child: Icon(Icons.receipt_long_outlined, size: 20),
                  ),
                  activeIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 2.5),
                    child: Icon(Icons.receipt_long_rounded, size: 20),
                  ),
                  label: t.history,
                ),
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 2.5),
                    child: Icon(Icons.analytics_outlined, size: 20),
                  ),
                  activeIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 2.5),
                    child: Icon(Icons.analytics_rounded, size: 20),
                  ),
                  label: t.statistics,
                ),
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 2.5),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 20,
                    ),
                  ),
                  activeIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 2.5),
                    child: Icon(Icons.account_balance_wallet_rounded, size: 20),
                  ),
                  label: t.wallet,
                ),
              ],
            ),
          ),

          // ── Center Docked Floating Action Button (Closed State) ──
          floatingActionButton: _isMenuOpen
              ? const SizedBox(width: 48, height: 48)
              : _buildFab(isOpen: false),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ),

        // ── Full-Screen Backdrop & Speed-Dial Overlay (Open State) ─
        if (_isMenuOpen) ...[
          // 1. Frosted Backdrop over entire screen
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _isMenuOpen = false),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black.withValues(alpha: 0.65)),
              ),
            ).animate().fadeIn(duration: 200.ms),
          ),

          // 2. Arc Speed-Dial Buttons anchored cleanly above the FAB (Icons only)
          Positioned(
            bottom: fabBottomOffset + 38,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 140,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Left Action: Pemasukan (Income)
                  Positioned(
                    left: 36,
                    bottom: 8,
                    child: _buildArcSpeedDialItem(
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFF10B981),
                      glowColor: const Color(0x4010B981),
                      delayMs: 0,
                      onTap: () => _openTransactionModal('income'),
                    ),
                  ),

                  // Center Action: AI Assistant (Elevated Crown Peak)
                  Positioned(
                    bottom: 68,
                    child: _buildArcSpeedDialItem(
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFF818CF8),
                      glowColor: const Color(0x666366F1),
                      isHighlight: true,
                      delayMs: 40,
                      onTap: _openAIAssistant,
                    ),
                  ),

                  // Right Action: Pengeluaran (Expense)
                  Positioned(
                    right: 36,
                    bottom: 8,
                    child: _buildArcSpeedDialItem(
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFFF43F5E),
                      glowColor: const Color(0x40F43F5E),
                      delayMs: 80,
                      onTap: () => _openTransactionModal('expense'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Open-State Floating Action Button on top of backdrop
          Positioned(
            bottom: fabBottomOffset,
            left: 0,
            right: 0,
            child: Center(child: _buildFab(isOpen: true)),
          ),
        ],
      ],
    );
  }

  /// Center Floating Action Button with smooth rotation and illumination
  Widget _buildFab({required bool isOpen}) {
    return GestureDetector(
      onTap: _toggleMenu,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOpen ? const Color(0xFF23252E) : AppColors.accentWhite,
          border: Border.all(
            color: isOpen ? const Color(0x55F43F5E) : const Color(0x1A000000),
            width: isOpen ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isOpen ? const Color(0x66F43F5E) : const Color(0x55FFFFFF),
              offset: const Offset(0, 3),
              blurRadius: isOpen ? 16 : 12,
            ),
          ],
        ),
        child: Center(
          child: AnimatedRotation(
            turns: isOpen ? 0.25 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Icon(
              isOpen ? Icons.close_rounded : Icons.add_rounded,
              size: 22,
              color: isOpen ? const Color(0xFFFB7185) : AppColors.accentBlack,
            ),
          ),
        ),
      ),
    );
  }

  /// Speed-Dial Item in Arc Layout (Clean Minimalist Icon Button)
  Widget _buildArcSpeedDialItem({
    required IconData icon,
    required Color color,
    required Color glowColor,
    required VoidCallback onTap,
    required int delayMs,
    bool isHighlight = false,
  }) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainer,
              border: Border.all(
                color: isHighlight
                    ? const Color(0x66818CF8)
                    : color.withValues(alpha: 0.35),
                width: isHighlight ? 1.5 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 3),
                ),
                const BoxShadow(
                  color: AppColors.shadowDarkFloat,
                  blurRadius: 12,
                  offset: Offset(3, 5),
                ),
                const BoxShadow(
                  color: AppColors.shadowLightFloat,
                  blurRadius: 6,
                  offset: Offset(-2, -2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isHighlight ? AppColors.accentWhite : color,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 220.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          delay: delayMs.ms,
          duration: 260.ms,
          curve: Curves.easeOutBack,
        )
        .slideY(
          begin: 0.4,
          end: 0,
          delay: delayMs.ms,
          duration: 260.ms,
          curve: Curves.easeOutBack,
        );
  }
}
