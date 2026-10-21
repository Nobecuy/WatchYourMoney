import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final bool isGuest;
  final User? user;
  const AuthState({required this.isGuest, this.user});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isGuest: true));

  void setLoggedIn(User user) => state = AuthState(isGuest: false, user: user);
  void setGuest() => state = const AuthState(isGuest: true);
  void setLoggedOut() => state = const AuthState(isGuest: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
