import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/core/ai/local_financial_engine.dart';
import 'package:watch_your_money/core/auth/developer_config.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/widgets/micro_interactions.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_chat_bubble.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_chat_message.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_empty_state.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_header.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_input.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_quick_chips.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_stream_handler.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen>
    with TickerProviderStateMixin {
  final List<AIChatMessage> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  bool _hasText = false;
  bool _isStreaming = false;
  String _currentSessionId = '';
  bool _isDev = false;
  bool _isOllamaHealthy = false;

  late AnimationController _pulseController;

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
          const AIChatMessage(
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
    final healthy = await AIStreamHandler.checkOllamaHealth(ref);
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
      _messages.add(AIChatMessage(text: label, isAI: false));
      _messages.add(
        const AIChatMessage(text: '', isAI: true, isStreaming: true),
      );
      _isStreaming = true;
    });
    _scrollToBottom();
    final engine = LocalFinancialEngine(ref);
    final result = await engine.runAnalysis(type);
    if (mounted) {
      setState(() {
        _messages[_messages.length - 1] = AIChatMessage(
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
      _messages.add(AIChatMessage(text: trimmed, isAI: false));
      _messages.add(
        const AIChatMessage(text: '', isAI: true, isStreaming: true),
      );
      _controller.clear();
      _isStreaming = true;
    });
    _scrollToBottom();

    final useOllama = AIStreamHandler.shouldUseOllama(
      isDev: _isDev,
      isOllamaHealthy: _isOllamaHealthy,
      ref: ref,
    );
    if (useOllama) {
      _sendViaOllama(trimmed);
    } else {
      _sendViaLocal(trimmed);
    }
  }

  void _sendViaOllama(String text) {
    AIStreamHandler.sendViaOllama(
      text: text,
      sessionId: _currentSessionId,
      ref: ref,
      messages: _messages,
      onMessagesUpdate: (updated) => setState(() => _messages
        ..clear()
        ..addAll(updated)),
      onStreamingStart: () {},
      onStreamingEnd: () => setState(() => _isStreaming = false),
      onError: (err) => _sendViaLocal(text),
    );
  }

  Future<void> _sendViaLocal(String text) async {
    await AIStreamHandler.sendViaLocal(
      text: text,
      sessionId: _currentSessionId,
      ref: ref,
      messages: _messages,
      onMessagesUpdate: (updated) => setState(() => _messages
        ..clear()
        ..addAll(updated)),
      onStreamingStart: () {},
      onStreamingEnd: () => setState(() => _isStreaming = false),
      onError: (err) {},
    );
  }

  void _clearChat() {
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.clear();
      _isStreaming = false;
    });
    _initChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Column(
          children: [
            AIHeader(
              isDev: _isDev,
              isOllamaHealthy: _isOllamaHealthy,
              hasMessages: _messages.isNotEmpty,
              pulseController: _pulseController,
              onBackPressed: () => Navigator.of(context).pop(),
              onClearChat: _clearChat,
            ),
            Expanded(
              child: _messages.isEmpty
                  ? const AIEmptyState()
                  : StaggeredListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) =>
                          AIChatBubble(message: _messages[i], index: i),
                      staggerDelay: const Duration(milliseconds: 50),
                      staggerDuration: const Duration(milliseconds: 300),
                    ),
            ),
            AIQuickChips(
              isStreaming: _isStreaming,
              onChipTap: _runAnalysis,
            ),
            AIInput(
              controller: _controller,
              focusNode: _inputFocusNode,
              hasText: _hasText,
              isStreaming: _isStreaming,
              onSend: () => _sendMessage(_controller.text),
              onSubmitted: _sendMessage,
            ),
            if (_isDev) const SizedBox(height: 12),
            if (!_isDev) const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}