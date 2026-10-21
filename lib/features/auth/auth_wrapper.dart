import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_your_money/features/auth/auth_provider.dart';
import 'package:watch_your_money/features/auth/auth_screen.dart';
import 'package:watch_your_money/features/main_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final supabaseUser = Supabase.instance.client.auth.currentUser;

    if (authState.isGuest && supabaseUser == null) {
      return const AuthScreen();
    }
    return const MainScreen();
  }
}
