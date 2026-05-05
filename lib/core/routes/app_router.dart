import 'package:a_core/features/logros/presentation/pages/achievements_page.dart';
import 'package:a_core/features/logros/presentation/pages/logros_home_page.dart';
import 'package:a_core/features/logros/presentation/pages/logros_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/auth/presentation/pages/login_page.dart';
import 'package:a_core/features/auth/presentation/pages/register_page.dart';
import 'package:a_core/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:a_core/features/home/presentation/pages/home_page.dart';
import 'package:a_core/features/diario/presentation/pages/diary_shell.dart';
import 'package:a_core/features/diario/presentation/pages/diary_home_page.dart';
import 'package:a_core/features/diario/presentation/pages/diary_entry_page.dart';
import 'package:a_core/features/diario/presentation/pages/diary_templates_page.dart';
import 'package:a_core/features/diario/domain/entities/diary_entry.dart';

abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';

  // Diario
  static const diary = '/diary';
  static const diaryEntry = '/diary/entry';
  static const diaryTemplates = '/diary/templates';

  // Logros
  static const logros = '/logros';
  static const logrosAchievements = '/logros/achievements';
}

GoRouter createRouter(BuildContext context) {
  final authProvider = context.read<AuthProvider>();

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.user != null;
      final isInitial = authProvider.status == AuthStatus.initial;
      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ].contains(state.matchedLocation);

      if (isInitial) return null;
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;
      if (isAuthenticated && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordPage()),

      // ── Home ──────────────────────────────
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomePage()),

      // ── Diario ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => DiaryShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.diary,
            builder: (_, __) => const DiaryHomePage(),
            routes: [
              GoRoute(
                path: 'entry',
                builder: (_, state) => DiaryEntryPage(entry: state.extra as DiaryEntry?),
              ),
            ],
          ),
          GoRoute(path: AppRoutes.diaryTemplates, builder: (_, __) => const DiaryTemplatesPage()),
        ],
      ),

      // ── Logros ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => LogrosShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.logros, builder: (_, __) => const LogrosHomePage()),
          GoRoute(path: AppRoutes.logrosAchievements, builder: (_, __) => const AchievementsPage()),
        ],
      ),
    ],
  );
}
