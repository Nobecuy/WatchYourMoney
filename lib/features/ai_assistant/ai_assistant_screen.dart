import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/core/ai/local_financial_engine.dart';
import 'package:watch_your_money/core/ai/noir_ai_service.dart';
import 'package:watch_your_money/core/auth/developer_config.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final List<_ChatMessage> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;
  bool _isStreaming = false;
  String _currentSessionId = '';
  bool _isHealthy = false;
  String _healthMessage = 'Memeriksa koneksi...';

  static const _shortcuts = [
    ('Sisa Uang', 'Berapa sisa uangku?'),
    ('Pengeluaran', 'Berapa total pengeluaranku?'),
    ('Pemasukan', 'Berapa total pemasukanku?'),
    ('Bisa Apa?', 'Kamu bisa apa aja?'),
  ];

  @override
  void initState() {
    super.initState();
    _currentSessionId = _generateSessionId();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Load previous messages for this session
    final chatRepo = ref.read(chatMessageRepositoryProvider);
    await chatRepo.init();
    final messages = await chatRepo.getMessages(_currentSessionId);

    if (messages.isEmpty) {
      // First time - add welcome message
      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'Halo! Saya Noir, asisten keuangan pribadimu. '
                'Tanyakan tentang saldo, pengeluaran, atau pemasukan. '
                'Kamu juga bisa menekan tombol shortcut di bawah untuk memulai.',
            isAI: true,
          ),
        );
      });
    } else {
      // Restore previous messages
      setState(() {
        _messages.addAll(
          messages
              .map(
                (m) =>
                    _ChatMessage(text: m.content, isAI: m.role == 'assistant'),
              )
              .toList(),
        );
      });
    }

    // Check Ollama health
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    final settings = await ref.read(noirSettingsProvider.future);
    final service = ref.read(noirAIServiceProvider(settings));
    final healthy = await service.checkHealth();

    setState(() {
      _isHealthy = healthy;
      _healthMessage = healthy
          ? 'Terhubung ke Ollama (${settings.modelName})'
          : 'Tidak terhubung ke Ollama. Pastikan Ollama berjalan di ${settings.ollamaHost}';
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

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isStreaming) return;

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isAI: false));
      _messages.add(_ChatMessage(text: '', isAI: true, isStreaming: true));
      _controller.clear();
      _isStreaming = true;
    });
    _scrollToBottom();

    // Check if Ollama is enabled in settings
    final appSettings = ref.read(settingsProvider);
    // Developer gate: only whitelisted accounts can use Ollama.
    // For all other users, force offline mode regardless of the saved setting.
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;
    final useOllama = appSettings.useOllama && isDeveloper(currentEmail);

    if (useOllama) {
      // Stream response from Ollama AI with timeout-based fallback
      final noirSettingsValue = ref.read(noirSettingsProvider);
      noirSettingsValue.whenData((noirSettings) {
        final service = ref.read(noirAIServiceProvider(noirSettings));
        final stream = service
            .streamResponse(userMessage: trimmed, sessionId: _currentSessionId)
            .timeout(const Duration(seconds: 30));

        String accumulatedResponse = '';
        stream.listen(
          (chunk) {
            setState(() {
              accumulatedResponse += chunk;
              _messages[_messages.length - 1] = _ChatMessage(
                text: accumulatedResponse,
                isAI: true,
                isStreaming: true,
              );
            });
            _scrollToBottom();
          },
          onDone: () {
            if (accumulatedResponse.isEmpty) {
              // Ollama returned nothing — fall back to local engine
              _fallbackToLocal(trimmed);
            } else {
              setState(() {
                _messages[_messages.length - 1] = _ChatMessage(
                  text: accumulatedResponse,
                  isAI: true,
                  isStreaming: false,
                );
                _isStreaming = false;
              });
              _scrollToBottom();
            }
          },
          onError: (error) {
            // Ollama error — fall back to local engine
            _fallbackToLocal(trimmed);
          },
        );
      });
    } else {
      // Use offline local engine directly
      _runLocalEngine(trimmed);
    }
  }

  void _fallbackToLocal(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mode offline digunakan — Ollama tidak terjangkau'),
        backgroundColor: AppColors.surfaceContainerHigh,
        duration: Duration(seconds: 2),
      ),
    );
    _runLocalEngine(text);
  }

  Future<void> _runLocalEngine(String text) async {
    final engine = LocalFinancialEngine(ref);
    String accumulated = '';

    await for (final chunk in engine.streamResponse(
      userMessage: text,
      sessionId: _currentSessionId,
    )) {
      accumulated += chunk;
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last.isAI) {
            _messages[_messages.length - 1] = _ChatMessage(
              text: accumulated,
              isAI: true,
              isStreaming: false,
            );
          } else {
            _messages.add(_ChatMessage(text: accumulated, isAI: true));
          }
          _isStreaming = false;
        });
      }
    }
    _scrollToBottom();
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final noirSettingsAsync = ref.watch(noirSettingsProvider);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Noir AI',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        noirSettingsAsync.when(
                          data: (settings) => Text(
                            _isHealthy
                                ? 'Ollama: ${settings.modelName} ✓'
                                : 'Ollama: Tidak terhubung ✗',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _isHealthy
                                      ? AppColors.positive
                                      : AppColors.negative,
                                ),
                          ),
                          loading: () => Text(
                            _healthMessage,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                          error: (_, _) => Text(
                            'Error memuat pengaturan',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.negative),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isHealthy
                          ? AppColors.positive.withValues(alpha: 0.1)
                          : AppColors.negative.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _isHealthy
                            ? AppColors.positive.withValues(alpha: 0.3)
                            : AppColors.negative.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _isHealthy ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: _isHealthy
                            ? AppColors.positive
                            : AppColors.negative,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

            // ── Typing Indicator ────────────────────────────────
            if (_isStreaming)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.positive.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppColors.positive.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.positive,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TypingIndicator().animate().fadeIn(duration: 200.ms),
                  ],
                ),
              ),

            // ── Quick Shortcut Chips ──────────────────────────
            _buildShortcutChips(),
            const SizedBox(height: 6),

            // ── Modern Floating Input Bar ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasText || _isStreaming
                        ? AppColors.positive.withValues(alpha: 0.5)
                        : const Color(0x1FFFFFFF),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hasText || _isStreaming
                          ? AppColors.positive.withValues(alpha: 0.12)
                          : const Color(0x66000000),
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
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.positive,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_isStreaming,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: _isStreaming ? 'Noir sedang mengetik...' : 'Tanyakan pola keuanganmu atau catat transaksi...',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: _isStreaming
                            ? null
                            : (v) => _sendMessage(v),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Modern Animated Send Button
                    GestureDetector(
                      onTap: (_hasText && !_isStreaming)
                          ? () => _sendMessage(_controller.text)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_hasText && !_isStreaming)
                              ? AppColors.accentWhite
                              : AppColors.surfaceContainerHigh,
                          boxShadow: (_hasText && !_isStreaming)
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
                          child: _isStreaming
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textMuted,
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_upward_rounded,
                                  color: (_hasText && !_isStreaming)
                                      ? AppColors.accentBlack
                                      : AppColors.textMuted,
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
    final isStreaming = msg.isStreaming;
    return Align(
      alignment: msg.isAI ? Alignment.centerLeft : Alignment.centerRight,
      child:
          Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: msg.isAI
                        ? (isStreaming
                              ? AppColors.surfaceContainerLow
                              : AppColors.surfaceContainer)
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(msg.isAI ? 4 : 20),
                      bottomRight: Radius.circular(msg.isAI ? 20 : 4),
                    ),
                    border: Border.all(
                      color: msg.isAI
                          ? (isStreaming
                                ? AppColors.positive.withValues(alpha: 0.3)
                                : const Color(0x14FFFFFF))
                          : const Color(0x24FFFFFF),
                      width: isStreaming ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isStreaming
                            ? AppColors.positive.withValues(alpha: 0.1)
                            : const Color(0x40000000),
                        offset: const Offset(0, 3),
                        blurRadius: isStreaming ? 12 : 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (msg.isAI) ...[
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isStreaming
                                  ? AppColors.positive.withValues(alpha: 0.2)
                                  : AppColors.surfaceContainerHigh,
                            ),
                            child: Center(
                              child: isStreaming
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.positive,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppColors.positive,
                                      size: 14,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: (index * 20).ms, duration: 200.ms)
              .slideY(begin: 0.1),
    );
  }

  Widget _buildShortcutChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _shortcuts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, message) = _shortcuts[i];
          return GestureDetector(
            onTap: _isStreaming ? null : () => _sendMessage(message),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isStreaming
                    ? AppColors.surfaceContainerLow
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _isStreaming
                      ? const Color(0x0AFFFFFF)
                      : const Color(0x1AFFFFFF),
                ),
                boxShadow: _isStreaming
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x66000000),
                          offset: Offset(2, 3),
                          blurRadius: 6,
                        ),
                        BoxShadow(
                          color: Color(0x05FFFFFF),
                          offset: Offset(-1, -1),
                          blurRadius: 4,
                        ),
                      ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: _isStreaming
                      ? AppColors.textMuted
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isAI;
  final bool isStreaming;
  const _ChatMessage({
    required this.text,
    required this.isAI,
    this.isStreaming = false,
  });
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * (1 - (value - 0.5).abs() * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.positive.withValues(
                      alpha: 0.5 + 0.5 * scale,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
