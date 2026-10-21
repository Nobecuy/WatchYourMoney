import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Halo! Saya asisten keuanganmu. Tanyakan apa saja tentang pola pengeluaranmu, atau gunakan tombol saran di bawah.',
      isAI: true,
    ),
  ];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text, {String? overrideAIReply}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isAI: false));
      _messages.add(_ChatMessage(
        text: overrideAIReply ?? 'Maaf, integrasi AI LLM belum aktif. Gunakan tombol saran di bawah untuk analisis otomatis.',
        isAI: true,
      ));
      _controller.clear();
    });
    _scrollToBottom();
  }

  void _analyzeExpense(List<TransactionModel> transactions) {
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final balance = totalIncome - totalExpense;
    final savingRate = totalIncome > 0 ? ((balance / totalIncome) * 100) : 0.0;

    // Category breakdown
    final catMap = <String, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      catMap[t.categoryId] = (catMap[t.categoryId] ?? 0) + t.amount;
    }
    final topCat = catMap.entries.isEmpty
        ? 'N/A'
        : catMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final reply = '''📊 Analisis Keuangan Kamu:

• Pemasukan: Rp ${_fmt(totalIncome)}
• Pengeluaran: Rp ${_fmt(totalExpense)}
• Saldo Bersih: Rp ${_fmt(balance)}
• Saving Rate: ${savingRate.toStringAsFixed(1)}%

🏆 Kategori terbesar: ${topCat.toUpperCase()}

${savingRate >= 20 ? '✅ Saving rate kamu sehat! Pertahankan.' : '⚠️ Saving rate di bawah 20%. Pertimbangkan kurangi pengeluaran $topCat.'}''';

    setState(() {
      _messages.add(_ChatMessage(text: 'Analisis pengeluaran saya', isAI: false));
      _messages.add(_ChatMessage(text: reply, isAI: true));
    });
    _scrollToBottom();
  }

  void _analyzePaymentRatio(List<TransactionModel> transactions) {
    final card = transactions.where((t) => t.paymentMethod == 'card').length;
    final cash = transactions.where((t) => t.paymentMethod == 'cash').length;
    final total = card + cash;
    final cardPct = total > 0 ? (card / total * 100).round() : 0;

    setState(() {
      _messages.add(_ChatMessage(text: 'Rasio pembayaran kartu vs tunai', isAI: false));
      _messages.add(_ChatMessage(
        text: '💳 Rasio Kartu vs Tunai:\n\n• Kartu: $card transaksi ($cardPct%)\n• Tunai: $cash transaksi (${100 - cardPct}%)\n\n${cardPct > 60 ? '📌 Kamu lebih banyak pakai kartu. Hati-hati dengan overspending yang tidak terasa.' : '📌 Kamu masih banyak pakai tunai. Pertimbangkan kartu untuk kemudahan tracking.'}',
        isAI: true,
      ));
    });
    _scrollToBottom();
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}rb';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const NeumorphicContainer(
                        width: 40,
                        height: 40,
                        borderRadius: 12,
                        padding: EdgeInsets.zero,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Text('AI Assistant', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x0FFFFFFF)),
                    ),
                    child: const Text('BETA', style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),

            // ── Chat Messages ───────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                itemCount: _messages.length,
                itemBuilder: (context, i) => _buildChatBubble(_messages[i], i),
              ),
            ),

            // ── Quick Suggestion Chips ─────────────────────────
            transactionsAsync.when(
              data: (transactions) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSuggestionChip('✦ Analisis Pengeluaran', () => _analyzeExpense(transactions)),
                      _buildSuggestionChip('✦ Rasio Kartu vs Tunai', () => _analyzePaymentRatio(transactions)),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),

            // ── Modern Floating Input Bar ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasText ? AppColors.positive.withValues(alpha: 0.5) : const Color(0x1FFFFFFF),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hasText ? AppColors.positive.withValues(alpha: 0.12) : const Color(0x66000000),
                      offset: const Offset(0, 4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  children: [
                    // AI Sparkle Badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.positive.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppColors.positive.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_awesome_rounded, color: AppColors.positive, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Tanyakan pola keuanganmu...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (v) => _sendMessage(v),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Modern Animated Send Button
                    GestureDetector(
                      onTap: () => _sendMessage(_controller.text),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hasText ? AppColors.accentWhite : AppColors.surfaceContainerHigh,
                          boxShadow: _hasText
                              ? const [
                                  BoxShadow(
                                    color: Color(0x40FFFFFF),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: _hasText ? AppColors.accentBlack : AppColors.textMuted,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage msg, int index) {
    return Align(
      alignment: msg.isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: msg.isAI ? AppColors.surfaceContainer : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(msg.isAI ? 4 : 20),
              bottomRight: Radius.circular(msg.isAI ? 20 : 4),
            ),
            border: Border.all(
              color: msg.isAI ? const Color(0x14FFFFFF) : const Color(0x24FFFFFF),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Text(
              msg.text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: (index * 20).ms, duration: 200.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildSuggestionChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x0FFFFFFF)),
          ),
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isAI;
  const _ChatMessage({required this.text, required this.isAI});
}
