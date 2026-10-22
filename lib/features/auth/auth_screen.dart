import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/features/auth/auth_provider.dart';
import 'package:watch_your_money/features/main_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (!mounted) return;
        if (res.user != null) {
          ref.read(authProvider.notifier).setLoggedIn(res.user!);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (!mounted) return;
        if (res.session != null && res.user != null) {
          ref.read(authProvider.notifier).setLoggedIn(res.user!);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun dibuat! Silakan cek Gmail Anda untuk konfirmasi, atau matikan "Confirm email" di Supabase Dashboard.'),
            backgroundColor: AppColors.surfaceContainerHigh,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _isLoginMode = true);
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (e is AuthException) {
        if (e.message.toLowerCase().contains('email not confirmed')) {
          errorMsg = 'Email belum dikonfirmasi! Cek inbox Gmail Anda atau matikan "Confirm email" di Supabase Dashboard (Auth > Providers > Email).';
        } else {
          errorMsg = e.message;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.surfaceContainerHigh,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _enterGuestMode() {
    ref.read(authProvider.notifier).setGuest();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Brand ──────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowDark,
                            offset: Offset(4, 4),
                            blurRadius: 12,
                          ),
                          BoxShadow(
                            color: AppColors.shadowLight,
                            offset: Offset(-3, -3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Text brand
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'watchh',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            letterSpacing: -1.5,
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                          ),
                        ),
                        Text(
                          'your money',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            letterSpacing: 3,
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),
                const SizedBox(height: 48),

                // ── Mode toggle ────────────────────────────────────
                NeumorphicContainer(
                  isPressed: true,
                  padding: const EdgeInsets.all(4),
                  borderRadius: 999,
                  child: Row(
                    children: [
                      Expanded(child: _buildModeBtn('Login', _isLoginMode, () => setState(() => _isLoginMode = true))),
                      Expanded(child: _buildModeBtn('Register', !_isLoginMode, () => setState(() => _isLoginMode = false))),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 24),

                // ── Email field ────────────────────────────────────
                _buildLabel('EMAIL'),
                const SizedBox(height: 8),
                NeumorphicContainer(
                  isPressed: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  borderRadius: 999,
                  clipBehavior: Clip.antiAlias,
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'email@kamu.com',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.textMuted, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 16),

                // ── Password field ─────────────────────────────────
                _buildLabel('PASSWORD'),
                const SizedBox(height: 8),
                NeumorphicContainer(
                  isPressed: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  borderRadius: 999,
                  clipBehavior: Clip.antiAlias,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: 32),

                // ── CTA Button ─────────────────────────────────────
                NeumorphicContainer(
                  isElevated: true,
                  padding: EdgeInsets.zero,
                  borderRadius: 999,
                  onTap: _isLoading ? null : _handleAuth,
                  backgroundColor: AppColors.accentWhite,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.accentBlack,
                              ),
                            )
                          : Text(
                              _isLoginMode ? 'Masuk' : 'Buat Akun',
                              style: const TextStyle(
                                color: AppColors.accentBlack,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                const SizedBox(height: 16),

                // ── Guest Mode ─────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: _enterGuestMode,
                    child: Text(
                      'Lanjutkan sebagai Guest →',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeBtn(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? [
            const BoxShadow(color: AppColors.shadowDark, offset: Offset(2, 2), blurRadius: 6),
            const BoxShadow(color: AppColors.shadowLight, offset: Offset(-2, -2), blurRadius: 6),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
    );
  }
}
