import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final bool isGuest;
  final User? user;
  const AuthState({required this.isGuest, this.user});
}

/// Notifier that restores the existing Supabase session on startup.
/// Supabase SDK persists the token internally (SecureStorage / SharedPrefs),
/// so we just need to read `currentUser` once at construction time.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(_initialState()) {
    // Also listen to Supabase auth changes so token refresh / sign-out
    // from another tab/device is reflected immediately.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        state = AuthState(isGuest: false, user: user);
      } else {
        // Only reset to guest if we were previously logged in.
        // This prevents overwriting an explicit guest choice.
        if (!state.isGuest) {
          state = const AuthState(isGuest: true);
        }
      }
    });
  }

  /// Build the initial state from any existing Supabase session.
  static AuthState _initialState() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      return AuthState(isGuest: false, user: user);
    }
    return const AuthState(isGuest: true);
  }

  void setLoggedIn(User user) => state = AuthState(isGuest: false, user: user);

  void setGuest() => state = const AuthState(isGuest: true);

  void setLoggedOut() => state = const AuthState(isGuest: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
