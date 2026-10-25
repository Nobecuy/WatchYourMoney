import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen>
    with TickerProviderStateMixin {
  final List<_ChatMessage> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  bool _hasText = false;
  bool _isStreaming = false;
  String _currentSessionId = '';
  bool _isDev = false;
  bool _isOllamaHealthy = false;

  late AnimationController _pulseController;

  static const _quickChips = <(String, AnalysisType)>[
    ('Ringkasan Keuangan', AnalysisType.financialOverview),
    ('Analisis Pengeluaran', AnalysisType.spendingAnalysis),
    ('Cek Anggaran', AnalysisType.budgetIntelligence),
    ('Pola Transaksi', AnalysisType.transactionInsights),
    ('Kesehatan Keuangan', AnalysisType.financialHealthCheck),
    ('Hitung Saving Rate', AnalysisType.savingRate),
  ];

  @override
  void initState() {
    super.initState();
    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _isDev = isDeveloper(Supabase.instance.client.auth.currentUser?.email);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _initChat();
  }

  void _initChat() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatMessage(
            text: 'Halo! Saya **Noir**, asisten keuangan pribadi kamu.\n\nSaya bisa bantu analisis kondisi keuanganmu secara offline — tidak perlu internet. Pilih shortcut di bawah atau ketik pertanyaanmu langsung.',
            isAI: true,
            isWelcome: true,
          ),
        );
      });
    });
    if (_isDev) _checkOllamaHealth();
  }

  Future<void> _checkOllamaHealth() async {
    final settings = await ref.read(noirSettingsProvider.future);
    final service = ref.read(noirAIServiceProvider(settings));
    final healthy = await service.checkHealth();
    if (mounted) setState(() => _isOllamaHealthy = healthy);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool fast = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: fast ? 150 : 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _runAnalysis(AnalysisType type, String label) async {
    if (_isStreaming) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_ChatMessage(text: label, isAI: false));
      _messages.add(
        const _ChatMessage(text: '', isAI: true, isStreaming: true),
      );
      _isStreaming = true;
    });
    _scrollToBottom();
    final engine = LocalFinancialEngine(ref);
    final result = await engine.runAnalysis(type);
    if (mounted) {
      setState(() {
        _messages[_messages.length - 1] = _ChatMessage(
          text: result,
          isAI: true,
        );
        _isStreaming = false;
      });
    }
    _scrollToBottom();
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isStreaming) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isAI: false));
      _messages.add(
        const _ChatMessage(text: '', isAI: true, isStreaming: true),
      );
      _controller.clear();
      _isStreaming = true;
    });
    _scrollToBottom();
    final appSettings = ref.read(settingsProvider);
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;
    final useOllama =
        appSettings.useOllama && isDeveloper(currentEmail) && _isOllamaHealthy;
    if (useOllama) {
      _sendViaOllama(trimmed);
    } else {
      _sendViaLocal(trimmed);
    }
  }

  /// Sends a predefined prompt to AI to trigger saving rate analysis via tool.
  void _sendViaOllama(String text) {
    final noirSettingsValue = ref.read(noirSettingsProvider);
    noirSettingsValue.whenData((noirSettings) {
      final service = ref.read(noirAIServiceProvider(noirSettings));
      final stream = service
          .streamResponse(userMessage: text, sessionId: _currentSessionId)
          .timeout(const Duration(seconds: 30));
      String acc = '';
      stream.listen(
        (chunk) {
          acc += chunk;
          if (mounted) {
            setState(() {
              _messages[_messages.length - 1] = _ChatMessage(
                text: acc,
                isAI: true,
                isStreaming: true,
              );
            });
            _scrollToBottom(fast: true);
          }
        },
        onDone: () {
          if (acc.isEmpty) {
            _sendViaLocal(text);
          } else {
            if (mounted) {
              setState(() {
                _messages[_messages.length - 1] = _ChatMessage(
                  text: acc,
                  isAI: true,
                );
                _isStreaming = false;
              });
              _scrollToBottom();
            }
          }
        },
        onError: (_) => _sendViaLocal(text),
      );
    });
  }

  Future<void> _sendViaLocal(String text) async {
    final engine = LocalFinancialEngine(ref);
    String acc = '';
    await for (final chunk in engine.streamResponse(
      userMessage: text,
      sessionId: _currentSessionId,
    )) {
      acc += chunk;
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last.isAI) {
            _messages[_messages.length - 1] = _ChatMessage(
              text: acc,
              isAI: true,
              isStreaming: false,
            );
          }
          _isStreaming = false;
        });
        _scrollToBottom(fast: true);
      }
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) => _buildBubble(_messages[i], i),
                    ),
            ),
            _buildQuickChips(),
            _buildInput(),
            if (_isDev) const SizedBox(height: 12),
            if (!_isDev) const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0CFFFFFF), width: 1)),
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop()) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const NeumorphicContainer(
                width: 36,
                height: 36,
                borderRadius: 10,
                padding: EdgeInsets.zero,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glow = 0.3 + 0.2 * _pulseController.value;
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.positive.withValues(alpha: glow),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.positive,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Noir AI',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildStatusBadge(),
                  ],
                ),
                Text(
                  _isDev && _isOllamaHealthy
                      ? 'Ollama aktif - mode lanjut'
                      : 'Analisis lokal - tanpa internet',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _messages.clear();
                  _isStreaming = false;
                });
                _initChat();
              },
              child: const NeumorphicContainer(
                width: 36,
                height: 36,
                borderRadius: 10,
                padding: EdgeInsets.zero,
                child: Center(
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildStatusBadge() {
    final online = _isDev && _isOllamaHealthy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: online
            ? AppColors.positive.withValues(alpha: 0.12)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: online
              ? AppColors.positive.withValues(alpha: 0.3)
              : const Color(0x10FFFFFF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? AppColors.positive : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            online ? 'ONLINE' : 'LOCAL',
            style: TextStyle(
              color: online ? AppColors.positive : AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
              boxShadow: [
                BoxShadow(
                  color: AppColors.positive.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.positive,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Noir AI',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Asisten keuangan lokal kamu',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildQuickChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: List.generate(_quickChips.length, (idx) {
              final (label, type) = _quickChips[idx];
              return GestureDetector(
                onTap: _isStreaming ? null : () => _runAnalysis(type, label),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isStreaming ? 0.4 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x12FFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowDark,
                          offset: Offset(2, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 250.ms).slideY(begin: 0.05);
  }

  Widget _buildInput() {
    if (!_isDev) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasText
                      ? AppColors.positive.withValues(alpha: 0.35)
                      : const Color(0x10FFFFFF),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _inputFocusNode,
                      enabled: !_isStreaming,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: _isStreaming
                            ? 'Memproses...'
                            : 'Tanya Noir tentang keuanganmu...',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: _isStreaming ? null : (v) => _sendMessage(v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: (_hasText && !_isStreaming)
                ? () => _sendMessage(_controller.text)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_hasText && !_isStreaming)
                    ? AppColors.positive
                    : AppColors.surfaceContainerHigh,
                boxShadow: (_hasText && !_isStreaming)
                    ? [
                        BoxShadow(
                          color: AppColors.positive.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: _isStreaming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: AppColors.positive,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: (_hasText && !_isStreaming)
                            ? Colors.black
                            : AppColors.textMuted,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg, int index) {
    if (!msg.isAI) {
      return Align(
        alignment: Alignment.centerRight,
        child:
            Container(
                  margin: const EdgeInsets.only(bottom: 12, left: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: (index * 20).ms, duration: 200.ms)
                .slideX(begin: 0.05),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child:
          Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.positive.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.positive,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Noir',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16, right: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isStreaming
                          ? AppColors.surfaceContainerLow
                          : AppColors.surfaceContainer,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(
                        color: msg.isStreaming
                            ? AppColors.positive.withValues(alpha: 0.18)
                            : const Color(0x0AFFFFFF),
                      ),
                    ),
                    child: msg.isStreaming && msg.text.isEmpty
                        ? const _TypingDots()
                        : _buildFormattedText(msg.text),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: (index * 20).ms, duration: 200.ms)
              .slideX(begin: -0.04),
    );
  }

  Widget _buildFormattedText(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: CircleAvatar(
                    radius: 2.5,
                    backgroundColor: AppColors.positive,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildRichLine(line.substring(2))),
              ],
            ),
          ),
        );
      } else if (RegExp(r'^\d+\.').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\.\s*(.*)').firstMatch(line);
        if (match != null) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${match.group(1)}.',
                    style: const TextStyle(
                      color: AppColors.positive,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildRichLine(match.group(2) ?? '')),
                ],
              ),
            ),
          );
        }
      } else if (line.isNotEmpty &&
          !line.contains(':') &&
          line.length < 40 &&
          (i == 0 || lines[i - 1].isEmpty)) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: i > 0 ? 8 : 0, bottom: 4),
            child: Text(
              line.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _buildRichLine(line),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichLine(String text) {
    final parts = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        parts.add(
          TextSpan(
            text: text.substring(last, match.start),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        );
      }
      parts.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      );
      last = match.end;
    }
    if (last < text.length) {
      parts.add(
        TextSpan(
          text: text.substring(last),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      );
    }
    return RichText(
      text: TextSpan(
        children: parts.isEmpty
            ? [
                TextSpan(
                  text: text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ]
            : parts,
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isAI;
  final bool isStreaming;
  final bool isWelcome;
  const _ChatMessage({
    required this.text,
    required this.isAI,
    this.isStreaming = false,
    this.isWelcome = false,
  });
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.22;
            final raw = (_ctrl.value - delay) % 1.0;
            final v = raw.clamp(0.0, 1.0);
            final scale =
                0.55 + 0.45 * (1.0 - (v - 0.5).abs() * 2.0).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.positive.withValues(
                      alpha: 0.4 + 0.5 * scale,
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
