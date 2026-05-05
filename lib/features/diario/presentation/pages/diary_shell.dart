import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:a_core/core/routes/app_router.dart';

class DiaryShell extends StatelessWidget {
  final Widget child;
  const DiaryShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.diaryTemplates)) return 1;
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
              context.go(AppRoutes.diary);
            case 1:
              context.go(AppRoutes.diaryTemplates);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Entradas',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined),
            selectedIcon: Icon(Icons.dashboard_customize),
            label: 'Plantillas',
          ),
        ],
      ),
    );
  }
}
