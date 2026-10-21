import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/features/auth/auth_provider.dart';
import 'package:watch_your_money/features/auth/auth_screen.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';
import 'package:watch_your_money/features/ai_assistant/ai_assistant_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.negativeLight, size: 22),
            SizedBox(width: 10),
            Text(
              'Keluar Akun?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi akun ini?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
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

  void _copyUserId(String? id) {
    if (id == null || id.isEmpty) return;
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.positive, size: 18),
            SizedBox(width: 8),
            Text('User ID berhasil disalin ke clipboard!'),
          ],
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest || user == null;
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Navigation Bar ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NeumorphicContainer(
                      width: 42,
                      height: 42,
                      borderRadius: 14,
                      padding: EdgeInsets.zero,
                      onTap: () => Navigator.of(context).pop(),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const Text(
                      'Profil Akun',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            'SECURE',
                            style: TextStyle(
                              color: AppColors.positive,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 250.ms),
              ),
            ),

            // ── Hero Profile Card ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: NeumorphicContainer(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                              Color(0xFF10B981),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (user?.email?.isNotEmpty ?? false)
                                ? user!.email![0].toUpperCase()
                                : 'G',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // User Email / Name
                      Text(
                        isGuest ? 'Pengguna Tamu (Offline)' : (user.email ?? 'Pengguna'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // User ID pill with copy action
                      if (!isGuest && user.id.isNotEmpty)
                        GestureDetector(
                          onTap: () => _copyUserId(user.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x1AFFFFFF)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'UID: ${user.id.substring(0, 8)}...${user.id.substring(user.id.length - 4)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.copy_rounded,
                                  color: AppColors.textMuted,
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isGuest
                              ? const Color(0x1AFBBF24)
                              : const Color(0x1A10B981),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isGuest
                                ? const Color(0x33FBBF24)
                                : const Color(0x3310B981),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGuest ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                              size: 12,
                              color: isGuest ? const Color(0xFFFBBF24) : AppColors.positive,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isGuest ? 'MODE TAMU (LOKAL)' : 'CLOUD VAULT AKTIF',
                              style: TextStyle(
                                color: isGuest ? const Color(0xFFFBBF24) : AppColors.positive,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 50.ms, duration: 300.ms).slideY(begin: 0.06),
              ),
            ),

            // ── Financial Activity Stats ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: transactionsAsync.when(
                  data: (txs) {
                    final txCount = txs.length;
                    double income = 0;
                    double expense = 0;
                    for (final t in txs) {
                      if (t.type == 'income') {
                        income += t.amount;
                      } else {
                        expense += t.amount;
                      }
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            title: 'Transaksi',
                            value: '$txCount',
                            color: const Color(0xFF818CF8),
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMiniStat(
                            title: 'Pemasukan',
                            value: CurrencyFormatter.compact(income),
                            color: const Color(0xFF34D399),
                            icon: Icons.south_west_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMiniStat(
                            title: 'Pengeluaran',
                            value: CurrencyFormatter.compact(expense),
                            color: const Color(0xFFFB7185),
                            icon: Icons.north_east_rounded,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (e, st) => const SizedBox(),
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              ),
            ),

            // ── Section: Detail Akun & Keamanan ─────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'INFORMASI AKUN',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    NeumorphicContainer(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          _buildSettingItem(
                            icon: Icons.email_outlined,
                            iconColor: const Color(0xFF818CF8),
                            title: 'Email Terdaftar',
                            subtitle: user?.email ?? 'Tidak terhubung email',
                            trailing: isGuest
                                ? const Text('Offline', style: TextStyle(color: AppColors.textMuted, fontSize: 11))
                                : const Icon(Icons.check_circle_rounded, color: AppColors.positive, size: 16),
                          ),
                          const Divider(color: Color(0x12FFFFFF), height: 1),
                          _buildSettingItem(
                            icon: Icons.calendar_today_outlined,
                            iconColor: const Color(0xFF38BDF8),
                            title: 'Bergabung Sejak',
                            subtitle: user?.createdAt != null
                                ? DateFormat('d MMMM yyyy').format(DateTime.parse(user!.createdAt))
                                : 'Oktober 2026',
                          ),
                          const Divider(color: Color(0x12FFFFFF), height: 1),
                          _buildSettingItem(
                            icon: Icons.security_rounded,
                            iconColor: const Color(0xFF34D399),
                            title: 'Protokol Keamanan',
                            subtitle: 'Enkripsi SSL & Supabase RLS Protected',
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Section: Preferensi Aplikasi ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'PENGATURAN & PREFERENSI',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    NeumorphicContainer(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          _buildSettingItem(
                            icon: Icons.payments_outlined,
                            iconColor: const Color(0xFFFBBF24),
                            title: 'Mata Uang',
                            subtitle: 'Indonesian Rupiah (IDR • Rp)',
                          ),
                          const Divider(color: Color(0x12FFFFFF), height: 1),
                          _buildSettingItem(
                            icon: Icons.dark_mode_outlined,
                            iconColor: const Color(0xFFA78BFA),
                            title: 'Tema Tampilan',
                            subtitle: 'Dark Onyx Neumorphism (Aktif)',
                          ),
                          const Divider(color: Color(0x12FFFFFF), height: 1),
                          _buildSettingItem(
                            icon: Icons.auto_awesome_rounded,
                            iconColor: const Color(0xFF818CF8),
                            title: 'AI Financial Assistant',
                            subtitle: 'Tanya analisis keuangan & tips hemat',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Section: Account Actions / Logout ───────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                child: Column(
                  children: [
                    if (isGuest)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentWhite,
                              foregroundColor: AppColors.accentBlack,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const AuthScreen()),
                              );
                            },
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text(
                              'Masuk / Hubungkan Akun Google',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.negativeLight,
                          side: const BorderSide(color: Color(0x33F43F5E), width: 1.2),
                          backgroundColor: const Color(0x14F43F5E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text(
                          isGuest ? 'Keluar dari Sesi Tamu' : 'Keluar dari Akun',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'watchh v1.0.0 • Dark Onyx Edition',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return NeumorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
