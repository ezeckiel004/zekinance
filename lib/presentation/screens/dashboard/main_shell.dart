import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const MainShell({super.key, required this.shell});

  void _onTap(int index) {
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_rounded),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Flux',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_rounded),
            label: 'Épargne',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_rounded), // AI Coach icon
            label: 'Coach IA',
          ),
        ],
      ),
    );
  }
}
