import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_theme.dart';
import 'package:watch_your_money/data/repositories/hive_chat_message_repository.dart';
import 'package:watch_your_money/data/repositories/hive_noir_settings_repository.dart'
    show HiveNoirSettingsRepository;
import 'package:watch_your_money/data/repositories/hive_pending_action_repository.dart'
    show HivePendingActionRepository;
import 'package:watch_your_money/domain/models/chat_message_model.dart';
import 'package:watch_your_money/features/goals/models/goal_model.dart';
import 'package:watch_your_money/domain/models/noir_settings_model.dart';
import 'package:watch_your_money/domain/models/pending_action_model.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Hive untuk Guest Mode (local storage)
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(ChatMessageModelAdapter());
  Hive.registerAdapter(ToolCallAdapter());
  Hive.registerAdapter(ToolResultAdapter());
  Hive.registerAdapter(PendingActionModelAdapter());
  Hive.registerAdapter(NoirSettingsModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<ChatMessageModel>('chat_messages');
  await Hive.openBox<PendingActionModel>('pending_actions');
  await Hive.openBox<NoirSettingsModel>('noir_settings');
  await Hive.openBox<GoalModel>('goals');

  // 2. Buka Hive box untuk Settings (language + currency preferences)
  await openSettingsBox();

  // 3. Initialize AI repositories
  final chatRepo = HiveChatMessageRepository();
  await chatRepo.init();
  final pendingRepo = HivePendingActionRepository();
  await pendingRepo.init();
  final noirSettingsRepo = HiveNoirSettingsRepository();
  await noirSettingsRepo.init();

  // 4. Inisialisasi Supabase untuk Authenticated Mode (dengan offline handling)
  await _initializeSupabase();

  // 5. Jalankan aplikasi
  runApp(const ProviderScope(child: MyApp()));
}

/// Initialize Supabase with proper error handling and timeout.
/// If initialization fails (offline, network error, etc.), the app will still
/// launch and allow users to access local data in guest/offline mode.
Future<void> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: 'https://ddsjgwsgwpfsdbyoslsk.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkc2pnd3Nnd3Bmc2RieW9zbHNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIwNTY1MzMsImV4cCI6MjEwNzYzMjUzM30.RZHzq_q3k2p6SuvWegZZNWPVGYuOcMXwEJQH0AxNKv0',
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    // Supabase initialization failed (likely offline).
    // App will continue in offline mode using local Hive data.
    debugPrint('Supabase initialization failed (offline mode): $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final locale = Locale(settings.languageCode);

    return MaterialApp(
      title: 'watchh — Watch Your Money',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}