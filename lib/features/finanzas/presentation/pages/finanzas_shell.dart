import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:a_core/core/routes/app_router.dart';

class FinanzasShell extends StatelessWidget {
  final Widget child;
  const FinanzasShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith(AppRoutes.finanzasCompromisos)) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go(AppRoutes.finanzas);
            case 1:
              context.go(AppRoutes.finanzasCompromisos);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Cuentas',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: 'Compromisos',
          ),
        ],
      ),
    );
  }
}
