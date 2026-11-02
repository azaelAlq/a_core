import 'package:flutter/material.dart';

import 'package:a_core/core/app_colors.dart';

/// Pantalla de carga mientras se restaura la sesión de Firebase.
/// Evita que se vea el login antes de saber si hay un usuario activo.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Logo-Blanco.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
