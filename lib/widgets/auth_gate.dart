import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';

/// AuthGate decides whether to show the HomeScreen or the LoginScreen
/// based on the current Supabase auth session.
///
/// It listens to [AuthProvider] and rebuilds whenever auth state changes,
/// ensuring the user is automatically routed correctly after login/logout.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isAuthenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
