import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/core/theme/app_theme.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Hive untuk Guest Mode (local storage)
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');

  // 2. Inisialisasi Supabase untuk Authenticated Mode
  await Supabase.initialize(
    url: 'https://ddsjgwsgwpfsdbyoslsk.supabase.co',
    // ignore: deprecated_member_use
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkc2pnd3Nnd3Bmc2RieW9zbHNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIwNTY1MzMsImV4cCI6MjEwNzYzMjUzM30.RZHzq_q3k2p6SuvWegZZNWPVGYuOcMXwEJQH0AxNKv0',
  );

  // 3. Jalankan aplikasi
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'watchh — Watch Your Money',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
