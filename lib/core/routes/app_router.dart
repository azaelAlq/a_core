import 'package:a_core/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/auth/presentation/pages/register_page.dart';
import 'package:a_core/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:a_core/features/home/presentation/pages/home_page.dart';

// ─────────────────────────────────────────────
//  ROUTE NAMES  (usa estas constantes siempre)
// ─────────────────────────────────────────────
abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  // Módulos futuros:
  // static const diario   = '/diario';
  // static const gym      = '/gym';
}

// ─────────────────────────────────────────────
//  ROUTER
// ─────────────────────────────────────────────
GoRouter createRouter(BuildContext context) {
  final authProvider = context.read<AuthProvider>();

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.user != null;
      final isInitial = authProvider.status == AuthStatus.initial;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (isInitial) return null;

      if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;
      if (isAuthenticated && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────
      GoRoute(path: AppRoutes.login, name: 'login', builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.register, name: 'register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (_, __) => const ForgotPasswordPage(),
      ),

      // ── Home ──────────────────────────────
      GoRoute(path: AppRoutes.home, name: 'home', builder: (_, __) => const HomePage()),

      // ── Módulos futuros (ShellRoute con BottomNavBar propio)
      // ShellRoute(
      //   builder: (context, state, child) => DiarioShell(child: child),
      //   routes: [
      //     GoRoute(path: AppRoutes.diario, builder: (_, __) => const DiarioPage()),
      //   ],
      // ),
    ],
  );
}
