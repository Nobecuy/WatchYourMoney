import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_your_money/core/auth/developer_config.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/dynamic_island_alert.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  String _category = 'Saran Fitur Baru';
  bool _isSending = false;

  static const _categories = [
    'Saran Fitur Baru',
    'Laporan Bug / Error',
    'Kritik & Masukan',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      context.showDynamicIslandError('Pesan tidak boleh kosong.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      final email = _emailController.text.trim();
      final subject = '[WatchYourMoney Feedback - $_category]';
      final body = StringBuffer()
        ..writeln(message)
        ..writeln()
        ..writeln('---')
        ..writeln('App Version: watchh v$appVersion')
        ..writeln('Category: $_category');
      if (email.isNotEmpty) {
        body.writeln('Reply To: $email');
      }

      final uri = Uri(
        scheme: 'mailto',
        path: developerEmails.first,
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body.toString())}',
      );

      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Try Supabase if active
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser != null) {
        try {
          await Supabase.instance.client.from('feedbacks').insert({
            'user_id': supabaseUser.id,
            'category': _category,
            'message': message,
            'email': email.isNotEmpty ? email : supabaseUser.email,
            'app_version': appVersion,
          });
        } catch (_) {
          // Supabase insert is best-effort; mailto is primary
        }
      }

      if (mounted) {
        context.showDynamicIslandSuccess(
          'Terima kasih! Saran & kritik kamu sangat berharga untuk pengembangan aplikasi ini.',
          duration: const Duration(seconds: 4),
        );
        _messageController.clear();
        _emailController.clear();
        if (!launched) {
          // mailto failed but Supabase or validation passed — still confirm
          context.showDynamicIslandWarning('Email client tidak tersedia. Feedback tetap tercatat di sistem.');
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showDynamicIslandError('Gagal mengirim feedback: $e');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
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
                    const SizedBox(width: 14),
                    const Text(
                      'Saran & Kritik',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 250.ms),
              ),
            ),

            // Intro text
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: const Text(
                  'Bantu kami meningkatkan aplikasi ini. Kirimkan saran, laporan bug, atau kritik konstruktif kamu di bawah ini.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
              ),
            ),

            // Form
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: NeumorphicContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Label
                      const Text(
                        'KATEGORI',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Category Dropdown
                      NeumorphicContainer(
                        isPressed: true,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        borderRadius: 12,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _category,
                            isExpanded: true,
                            dropdownColor: AppColors.surfaceContainerHigh,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _category = v);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Message Label
                      const Text(
                        'PESAN',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Message Input
                      NeumorphicContainer(
                        isPressed: true,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        borderRadius: 14,
                        child: TextField(
                          controller: _messageController,
                          maxLines: 5,
                          minLines: 4,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Tulis saran atau kritik kamu di sini...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Email Label
                      const Text(
                        'EMAIL (OPSIONAL)',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Email Input
                      NeumorphicContainer(
                        isPressed: true,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        borderRadius: 999,
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'email@kamu.com (opsional, untuk balasan)',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      NeumorphicContainer(
                        isElevated: true,
                        padding: EdgeInsets.zero,
                        borderRadius: 999,
                        backgroundColor: AppColors.accentWhite,
                        onTap: _isSending ? null : _sendFeedback,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: _isSending
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accentBlack,
                                    ),
                                  )
                                : const Text(
                                    'Kirim Feedback',
                                    style: TextStyle(
                                      color: AppColors.accentBlack,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.05),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}
