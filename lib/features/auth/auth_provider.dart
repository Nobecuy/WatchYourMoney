import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final bool isGuest;
  final User? user;
  final bool isOfflineMode;

  /// True only when the user explicitly tapped "Lanjutkan sebagai Guest".
  /// False when the app simply has no session (e.g. offline startup).
  final bool isExplicitGuest;

  const AuthState({
    required this.isGuest,
    this.user,
    this.isOfflineMode = false,
    this.isExplicitGuest = false,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isGuest: true)) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user != null) {
        // Restored session from Supabase persistent storage.
        state = AuthState(isGuest: false, user: user);
      }

      // Listen to auth state changes (token refresh, sign-out from another device).
      client.auth.onAuthStateChange.listen(
        (data) {
          final u = data.session?.user;
          if (u != null) {
            state = AuthState(isGuest: false, user: u);
          } else {
            // Only auto-reset if we were logged in — don't override explicit guest.
            if (!state.isGuest &&
                !state.isOfflineMode &&
                !state.isExplicitGuest) {
              state = const AuthState(isGuest: true);
            }
          }
        },
        onError: (error) {
          debugPrint('Auth state listener error (offline?): $error');
        },
      );
    } catch (e) {
      // Supabase initialization failed (likely offline startup).
      // The SDK still stores session tokens in secure storage.
      // Check if there's a persisted session we can use offline.
      debugPrint('Auth initialization error (offline mode): $e');

      // Try to detect if there's a stored session even when offline.
      // The Supabase SDK persists session to secure storage.
      // We attempt to access it directly.
      bool hasStoredSession = false;
      try {
        // Even if initialize() failed, the SDK might have restored session from storage
        final client = Supabase.instance.client;
        hasStoredSession = client.auth.currentUser != null ||
                           client.auth.currentSession != null;
      } catch (_) {
        // If even this fails, we truly have no session
      }

      if (hasStoredSession) {
        // User was logged in before — allow offline access to their data
        state = const AuthState(isGuest: false, isOfflineMode: true);
        debugPrint('Offline mode enabled: stored session detected');
      }
    }
  }

  /// Successful Supabase login.
  void setLoggedIn(User user) => state = AuthState(isGuest: false, user: user);

  /// User explicitly tapped "Lanjutkan sebagai Guest".
  void setGuest() =>
      state = const AuthState(isGuest: true, isExplicitGuest: true);

  /// Signed out deliberately.
  void setLoggedOut() =>
      state = const AuthState(isGuest: true, isExplicitGuest: false);

  /// Use app offline with existing local Hive data (no Supabase session).
  void setOfflineMode() =>
      state = const AuthState(isGuest: false, isOfflineMode: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
