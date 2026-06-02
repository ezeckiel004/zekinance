import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/localization/translations.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell shell;

  const MainShell({super.key, required this.shell});

  void _onTap(int index) {
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view_rounded),
            label: context.tr(ref, 'nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_rounded),
            label: context.tr(ref, 'nav_budgets'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_rounded),
            label: context.tr(ref, 'nav_transactions'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.savings_rounded),
            label: context.tr(ref, 'nav_savings'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.psychology_rounded),
            label: context.tr(ref, 'nav_coach'),
          ),
        ],
      ),
    );
  }
}
