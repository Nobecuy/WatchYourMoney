// AI stream handler for managing AI response streaming.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/core/ai/local_financial_engine.dart';
import 'package:watch_your_money/core/ai/noir_ai_service.dart';
import 'package:watch_your_money/core/auth/developer_config.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/features/ai_assistant/widgets/ai_chat_message.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

class AIStreamHandler {
  /// Sends message via Ollama (developer mode with streaming)
  static void sendViaOllama({
    required String text,
    required String sessionId,
    required WidgetRef ref,
    required List<AIChatMessage> messages,
    required Function(List<AIChatMessage>) onMessagesUpdate,
    required void Function() onStreamingStart,
    required void Function() onStreamingEnd,
    required Function(String) onError,
  }) {
    final noirSettingsValue = ref.read(noirSettingsProvider);
    noirSettingsValue.whenData((noirSettings) {
      final service = ref.read(noirAIServiceProvider(noirSettings));
      final stream = service
          .streamResponse(userMessage: text, sessionId: sessionId)
          .timeout(const Duration(seconds: 30));
      String acc = '';
      stream.listen(
        (chunk) {
          acc += chunk;
          if (messages.isNotEmpty && messages.last.isAI) {
            final updatedMessages = List<AIChatMessage>.from(messages);
            updatedMessages[updatedMessages.length - 1] = messages.last.copyWith(
              text: acc,
              isStreaming: true,
            );
            onMessagesUpdate(updatedMessages);
          }
        },
        onDone: () {
          if (acc.isEmpty) {
            sendViaLocal(
              text: text,
              sessionId: sessionId,
              ref: ref,
              messages: messages,
              onMessagesUpdate: onMessagesUpdate,
              onStreamingStart: onStreamingStart,
              onStreamingEnd: onStreamingEnd,
              onError: onError,
            );
          } else {
            final updatedMessages = List<AIChatMessage>.from(messages);
            updatedMessages[updatedMessages.length - 1] = messages.last.copyWith(
              text: acc,
              isStreaming: false,
            );
            onMessagesUpdate(updatedMessages);
            onStreamingEnd();
          }
        },
        onError: (_) => sendViaLocal(
          text: text,
          sessionId: sessionId,
          ref: ref,
          messages: messages,
          onMessagesUpdate: onMessagesUpdate,
          onStreamingStart: onStreamingStart,
          onStreamingEnd: onStreamingEnd,
          onError: onError,
        ),
      );
    });
  }

  /// Sends message via local engine (offline-first)
  static Future<void> sendViaLocal({
    required String text,
    required String sessionId,
    required WidgetRef ref,
    required List<AIChatMessage> messages,
    required Function(List<AIChatMessage>) onMessagesUpdate,
    required void Function() onStreamingStart,
    required void Function() onStreamingEnd,
    required Function(String) onError,
  }) async {
    final engine = LocalFinancialEngine(ref);
    String acc = '';
    await for (final chunk in engine.streamResponse(
      userMessage: text,
      sessionId: sessionId,
    )) {
      acc += chunk;
      if (messages.isNotEmpty && messages.last.isAI) {
        final updatedMessages = List<AIChatMessage>.from(messages);
        updatedMessages[updatedMessages.length - 1] = messages.last.copyWith(
          text: acc,
          isStreaming: false,
        );
        onMessagesUpdate(updatedMessages);
      }
    }
    onStreamingEnd();
  }

  /// Checks Ollama health status
  static Future<bool> checkOllamaHealth(WidgetRef ref) async {
    final settings = await ref.read(noirSettingsProvider.future);
    final service = ref.read(noirAIServiceProvider(settings));
    return await service.checkHealth();
  }

  /// Determines if Ollama should be used
  static bool shouldUseOllama({
    required bool isDev,
    required bool isOllamaHealthy,
    required WidgetRef ref,
  }) {
    final appSettings = ref.read(settingsProvider);
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;
    return appSettings.useOllama && isDeveloper(currentEmail) && isOllamaHealthy;
  }
}