import 'package:connectivity_plus/connectivity_plus.dart';
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

    // ── Case 1: logged-in user (Supabase session restored) ─────────────────
    if (!authState.isGuest || authState.isOfflineMode) {
      return const MainScreen();
    }

    // ── Case 2: user explicitly chose guest mode ────────────────────────────
    if (authState.isExplicitGuest) {
      return const MainScreen();
    }

    // ── Case 3: isGuest=true, not explicit — could be offline or new user ───
    // Check Supabase: if there's a valid session token even without network,
    // the SDK may still know the user identity from its secure storage.
    bool hasSupabaseSession = false;
    try {
      // Supabase SDK restores session from secure storage on initialize.
      // Even if network is unavailable, the local session persists.
      hasSupabaseSession =
          Supabase.instance.client.auth.currentUser != null ||
          Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      // Supabase not fully initialized (offline startup) —
      // but session might still exist in secure storage.
      // The AuthNotifier will also check this and set isOfflineMode.
      // We'll let the FutureBuilder handle connectivity check below.
    }

    if (hasSupabaseSession) {
      // Session exists in SDK — the auth notifier will pick this up.
      return const MainScreen();
    }

    // ── Case 4: no session at all — check connectivity ─────────────────────
    return FutureBuilder<List<ConnectivityResult>>(
      future: Connectivity().checkConnectivity(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Still loading connectivity — show a brief splash to avoid flicker.
          return const Scaffold(
            backgroundColor: Color(0xFF121316),
            body: SizedBox.shrink(),
          );
        }

        final isOnline =
            snapshot.data!.isNotEmpty &&
            !snapshot.data!.contains(ConnectivityResult.none);

        if (isOnline) {
          // Online, no session → show login screen.
          return const AuthScreen();
        } else {
          // Offline, no session → allow offline / guest access to local data.
          // The user can still browse any locally cached data.
          // We set offline mode so the app doesn't redirect away later.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(authProvider.notifier).setOfflineMode();
          });
          return const MainScreen();
        }
      },
    );
  }
}
