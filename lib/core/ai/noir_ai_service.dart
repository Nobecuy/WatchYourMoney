import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch_your_money/core/ai/ollama_client.dart';
import 'package:watch_your_money/core/ai/topic_gate.dart';
import 'package:watch_your_money/core/ai/context_builder.dart';
import 'package:watch_your_money/core/ai/tool_handlers.dart' hide toolHandlersProvider;
import 'package:watch_your_money/core/ai/finance_tools.dart' as finance_tools;
import 'package:watch_your_money/domain/models/chat_message_model.dart' as domain_models;
import 'package:watch_your_money/domain/models/noir_settings_model.dart';
import 'package:watch_your_money/domain/repositories/chat_message_repository.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

/// Service that orchestrates the noir AI assistant.
/// Handles LLM communication, tool calling, chat persistence, and streaming.
class NoirAIService {
  final Ref ref;
  final NoirSettingsModel settings;
  final ChatMessageRepository _chatRepo;

  NoirAIService(this.ref, this.settings)
      : _chatRepo = ref.read(chatMessageRepositoryProvider);

  /// Stream a response from the AI for the given user message.
  /// Yields chunks of the response as they arrive.
  Stream<String> streamResponse({
    required String userMessage,
    required String sessionId,
  }) async* {
    // 1. Check topic gate
    final topicCheck = TopicGate.classify(userMessage);
    final isFinance = topicCheck.$1;
    if (!isFinance) {
      yield TopicGate.getRejectionMessage();
      return;
    }

    // 2. Save user message
    final userMsg = domain_models.ChatMessageModel(
      id: _generateId(),
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
      sessionId: sessionId,
    );
    await _chatRepo.addMessage(userMsg);

    // 3. Get recent messages for context
    final recentMessages = await _chatRepo.getMessages(sessionId);
    final recentMessagesJson = recentMessages
        .take(10)
        .map((m) => {
              'role': m.role,
              'content': m.content,
              'tool_calls': m.toolCalls?.map((e) => e.toJson()).toList(),
              'tool_results': m.toolResults?.map((e) => e.toJson()).toList(),
            })
        .toList();

    // 4. Build context
    final contextBuilder = ref.read(contextBuilderProvider(settings));
    final context = await contextBuilder.buildContext(
      userQuery: userMessage,
      recentMessages: recentMessagesJson,
    );

    // 5. Prepare messages for Ollama
    final ollamaMessages = _buildOllamaMessages(
      userMessage: userMessage,
      context: context,
      recentMessages: recentMessagesJson,
    );

    // 6. Get tool definitions
    final tools = finance_tools.FinanceToolDefinitions.getToolDefinitions();

    // 7. Call Ollama with streaming
    final client = OllamaClient(settings);
    try {
      final toolHandlers = ref.read(toolHandlersProvider);
      int toolCallCount = 0;
      String accumulatedContent = '';
      List<OllamaToolCall> pendingToolCalls = [];

      // Explicitly declare as nullable list
      final List<OllamaTool>? toolsNullable = tools as List<OllamaTool>?;

      await for (final chunk in client.chatStream(
        messages: ollamaMessages,
        temperature: settings.temperature,
        maxTokens: settings.maxTokens,
        tools: toolsNullable,
      )) {
        // Handle streaming chunks
        if (chunk.message != null) {
          final message = chunk.message!;
          // Handle tool calls
          if (message.toolCalls != null) {
            pendingToolCalls.addAll(message.toolCalls!);
          }

          // Handle text content (content is non-nullable String in OllamaMessage)
          if (message.content.isNotEmpty) {
            accumulatedContent += message.content;
            yield message.content;
          }
        }

        // If done, execute tool calls
        if (chunk.done) {
          if (pendingToolCalls.isNotEmpty) {
            yield* _executeToolCalls(
              toolCalls: pendingToolCalls,
              toolHandlers: toolHandlers,
              sessionId: sessionId,
              userMessage: userMessage,
              context: context,
              recentMessagesJson: recentMessagesJson,
              accumulatedContent: accumulatedContent,
              toolCallCount: toolCallCount,
            );
          }

          // Save assistant message
          final assistantMsg = domain_models.ChatMessageModel(
            id: _generateId(),
            role: 'assistant',
            content: accumulatedContent.isEmpty
                ? 'Saya tidak menemukan jawaban yang tepat.'
                : accumulatedContent,
            toolCalls: pendingToolCalls.isEmpty ? null : pendingToolCalls
                .map((tc) => domain_models.ToolCall(
                      id: tc.id,
                      name: tc.function.name,
                      arguments: tc.function.arguments,
                    ))
                .toList(),
            toolResults: pendingToolCalls.isEmpty ? null : [],
            timestamp: DateTime.now(),
            sessionId: sessionId,
          );
          await _chatRepo.addMessage(assistantMsg);
          break;
        }
      }
    } finally {
      client.dispose();
    }
  }

  /// Execute tool calls and continue the conversation.
  Stream<String> _executeToolCalls({
    required List<OllamaToolCall> toolCalls,
    required ToolHandlers toolHandlers,
    required String sessionId,
    required String userMessage,
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> recentMessagesJson,
    required String accumulatedContent,
    int toolCallCount = 0,
  }) async* {
    if (toolCallCount >= settings.maxToolCallsPerTurn) {
      yield '\n\n⚠️ Batas maksimum pemanggilan tool tercapai.';
      return;
    }

    final toolResults = <finance_tools.ToolResult>[];
    String newContent = '';

    for (final toolCall in toolCalls) {
      final function = toolCall.function;
      final toolName = function.name;
      final args = Map<String, dynamic>.from(function.arguments);

      // Validate tool call
      final validation = finance_tools.FinanceToolSchemas.validate(toolName, args);
      if (!validation.$1) {
        final errorResult = finance_tools.ToolResult(
          toolCallId: toolCall.id,
          name: toolName,
          result: 'Error: ${validation.$2}',
          isError: true,
        );
        toolResults.add(errorResult);
        continue;
      }

      // Execute tool
      dynamic result;
      try {
        switch (toolName) {
          case 'get_financial_summary':
            result = await toolHandlers.handleGetFinancialSummary(
              args['period'] as String,
            );
            break;
          case 'get_transactions':
            result = await toolHandlers.handleGetTransactions(
              dateFrom: args['date_from'] as String?,
              dateTo: args['date_to'] as String?,
              category: args['category'] as String?,
              type: args['type'] as String?,
              paymentMethod: args['payment_method'] as String?,
              limit: args['limit'] as int? ?? 50,
            );
            break;
          case 'get_spending_analysis':
            result = await toolHandlers.handleGetSpendingAnalysis(
              period: args['period'] as String,
              groupBy: args['group_by'] as String? ?? 'category',
            );
            break;
          case 'calculate_savings_plan':
            result = await toolHandlers.handleCalculateSavingsPlan(
              targetAmount: args['target_amount'] as int,
              monthlySaving: args['monthly_saving'] as int,
              currentSavings: args['current_savings'] as int? ?? 0,
            );
            break;
          case 'propose_transaction':
            result = await toolHandlers.handleProposeTransaction(
              type: args['type'] as String,
              amount: args['amount'] as int,
              categoryId: args['category_id'] as String,
              note: args['note'] as String?,
              date: args['date'] as String?,
              paymentMethod: args['payment_method'] as String? ?? 'cash',
            );
            break;
          case 'confirm_transaction':
            result = await toolHandlers.handleConfirmTransaction(
              args['idempotency_key'] as String,
            );
            break;
          case 'propose_transaction_update':
            result = await toolHandlers.handleProposeTransactionUpdate(
              transactionId: args['transaction_id'] as String,
              amount: args['amount'] as int?,
              categoryId: args['category_id'] as String?,
              note: args['note'] as String?,
              date: args['date'] as String?,
              paymentMethod: args['payment_method'] as String?,
            );
            break;
          case 'confirm_transaction_update':
            result = await toolHandlers.handleConfirmTransactionUpdate(
              args['idempotency_key'] as String,
            );
            break;
          case 'get_saving_rate_analysis':
            result = await toolHandlers.handleGetSavingRateAnalysis(
              args['period'] as String,
            );
            break;
          default:
            result = {'error': 'Unknown tool: $toolName'};
        }
      } catch (e) {
        result = {'error': 'Tool execution failed: $e'};
      }

      final toolResult = finance_tools.ToolResult(
        toolCallId: toolCall.id,
        name: toolName,
        result: result is Map ? result.toString() : result.toString(),
        isError: result is Map && result.containsKey('error'),
      );
      toolResults.add(toolResult);
    }

    // Save tool results as tool message
    final toolMsg = domain_models.ChatMessageModel(
      id: _generateId(),
      role: 'tool',
      content: 'Tool execution results',
      toolResults: toolResults
          .map((tr) => domain_models.ToolResult(
                toolCallId: tr.toolCallId,
                name: tr.name,
                content: tr.isError ? 'Error: ${tr.result}' : tr.result.toString(),
                isError: tr.isError,
              ))
          .toList(),
      timestamp: DateTime.now(),
      sessionId: sessionId,
    );
    await _chatRepo.addMessage(toolMsg);

    // Continue conversation with tool results
    final client = OllamaClient(settings);
    try {
      final followUpMessages = _buildFollowUpMessages(
        context: context,
        recentMessages: recentMessagesJson,
        toolResults: toolResults,
      );

      await for (final chunk in client.chatStream(
        messages: followUpMessages,
        temperature: settings.temperature,
        maxTokens: settings.maxTokens,
        tools: finance_tools.FinanceToolDefinitions.getToolDefinitions().toList() as List<OllamaTool>?,
      )) {
        if (chunk.message != null) {
          final message = chunk.message!;
          if (message.toolCalls != null) {
            // Recursive tool call (should be rare)
            yield* _executeToolCalls(
              toolCalls: message.toolCalls!,
              toolHandlers: toolHandlers,
              sessionId: sessionId,
              userMessage: userMessage,
              context: context,
              recentMessagesJson: recentMessagesJson,
              accumulatedContent: accumulatedContent + newContent,
              toolCallCount: toolCallCount + 1,
            );
          }

          // Handle text content (content is non-nullable String in OllamaMessage)
          if (message.content.isNotEmpty) {
            newContent += message.content;
            yield message.content;
          }
        }

        if (chunk.done) {
          // Save final assistant message
          final finalMsg = domain_models.ChatMessageModel(
            id: _generateId(),
            role: 'assistant',
            content: (accumulatedContent + newContent).trim(),
            toolCalls: [],
            toolResults: toolResults
                .map((tr) => domain_models.ToolResult(
                      toolCallId: tr.toolCallId,
                      name: tr.name,
                      content: tr.isError ? 'Error: ${tr.result}' : tr.result.toString(),
                      isError: tr.isError,
                    ))
                .toList(),
            timestamp: DateTime.now(),
            sessionId: sessionId,
          );
          await _chatRepo.addMessage(finalMsg);
          break;
        }
      }
    } finally {
      client.dispose();
    }
  }

  /// Build initial messages for Ollama.
  List<OllamaMessage> _buildOllamaMessages({
    required String userMessage,
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> recentMessages,
  }) {
    final systemPrompt = _buildSystemPrompt(context);
    final messages = <OllamaMessage>[
      OllamaMessage(role: 'system', content: systemPrompt),
    ];

    // Add recent conversation history
    for (final msg in recentMessages.take(6)) {
      if (msg['role'] == 'user' || msg['role'] == 'assistant') {
        messages.add(OllamaMessage(
          role: msg['role'] as String,
          content: msg['content'] as String? ?? '',
        ));
      }
    }

    // Add current user message with context
    messages.add(OllamaMessage(
      role: 'user',
      content: 'Konteks keuangan: ${context.toString()}\n\nPertanyaan: $userMessage',
    ));

    return messages;
  }

  /// Build follow-up messages after tool execution.
  List<OllamaMessage> _buildFollowUpMessages({
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> recentMessages,
    required List<finance_tools.ToolResult> toolResults,
  }) {
    final systemPrompt = _buildSystemPrompt(context);
    final messages = <OllamaMessage>[
      OllamaMessage(role: 'system', content: systemPrompt),
    ];

    // Add recent history
    for (final msg in recentMessages.take(6)) {
      if (msg['role'] == 'user' || msg['role'] == 'assistant') {
        messages.add(OllamaMessage(
          role: msg['role'] as String,
          content: msg['content'] as String? ?? '',
        ));
      }
    }

    // Add tool results
    for (final result in toolResults) {
      messages.add(OllamaMessage(
        role: 'tool',
        content: result.isError ? 'Error: ${result.result}' : result.result.toString(),
        toolCallId: result.toolCallId,
      ));
    }

    return messages;
  }

  /// Build system prompt with finance-only instructions.
  String _buildSystemPrompt(Map<String, dynamic> context) {
    final financialSummary = context['financial_summary'] as Map<String, dynamic>?;
    final currency = context['currency'] as Map<String, dynamic>?;
    final categories = context['categories'] as List<String>?;
    final savingRateAnalysis = context['saving_rate_analysis'] as Map<String, dynamic>?;

    return '''
Kamu adalah Noir, asisten keuangan lokal yang berjalan sepenuhnya di perangkat pengguna (offline-first).
Kamu HANYA boleh menjawab pertanyaan seputar keuangan pribadi: pengeluaran, pemasukan, tabungan, anggaran, investasi, dll.

ATURAN KETAT:
1. TOLAK pertanyaan non-keuangan dengan sopan: "Maaf, saya hanya bisa membantu topik keuangan."
2. Selalu gunakan TOOL yang tersedia untuk mengambil data - JANGAN mengarang angka.
3. Untuk transaksi: selalu gunakan propose_transaction → minta konfirmasi → confirm_transaction.
4. Jawab dalam Bahasa Indonesia, gunakan format Rupiah (Rp 1.500.000).
5. Maksimal ${settings.maxToolCallsPerTurn} pemanggilan tool per balasan.

KONTEKS KEUANGAN SAAT INI:
${financialSummary != null ? '- Total Pemasukan: ${financialSummary['formatted']?['total_income'] ?? 'N/A'}' : ''}
${financialSummary != null ? '- Total Pengeluaran: ${financialSummary['formatted']?['total_expense'] ?? 'N/A'}' : ''}
${financialSummary != null ? '- Saldo: ${financialSummary['formatted']?['balance'] ?? 'N/A'}' : ''}
${savingRateAnalysis != null ? '- Saving Rate: ${savingRateAnalysis['saving_rate_formatted'] ?? 'N/A'} (${savingRateAnalysis['status_label'] ?? 'N/A'})' : ''}
${currency != null ? '- Mata Uang: ${currency['code']} (${currency['symbol']})' : ''}
${categories != null ? '- Kategori tersedia: ${categories.join(', ')}' : ''}

TOOL YANG TERSEDIA:
- get_financial_summary: Ringkasan saldo & arus uang (week/month/all)
- get_transactions: Cari transaksi dengan filter
- get_spending_analysis: Analisis pengeluaran per kategori
- calculate_savings_plan: Hitung rencana tabungan
- get_saving_rate_analysis: Analisis saving rate dengan diagnosa kesehatan keuangan & rekomendasi
- propose_transaction: Usulkan transaksi baru (BELUM menyimpan)
- confirm_transaction: Konfirmasi & simpan transaksi yang diusulkan
- propose_transaction_update: Usulkan perubahan transaksi
- confirm_transaction_update: Konfirmasi perubahan transaksi

Gaya jawab: Ringkas, actionable, ramah, gunakan emoji secukupnya.
''';
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }

  /// Check if Ollama is available and model is loaded.
  Future<bool> checkHealth() async {
    final client = OllamaClient(settings);
    try {
      return await client.isHealthy();
    } finally {
      client.dispose();
    }
  }

  /// Get available models from Ollama.
  Future<List<String>> getAvailableModels() async {
    final client = OllamaClient(settings);
    try {
      return await client.listModels();
    } finally {
      client.dispose();
    }
  }

  /// Pull/download a model.
  Future<bool> pullModel(String modelName,
      {void Function(double progress)? onProgress}) async {
    final client = OllamaClient(settings);
    try {
      return await client.pullModel(modelName, onProgress: onProgress);
    } finally {
      client.dispose();
    }
  }
}

/// Riverpod provider for NoirAIService.
final noirAIServiceProvider = Provider.family<NoirAIService, NoirSettingsModel>(
  (ref, settings) => NoirAIService(ref, settings),
);