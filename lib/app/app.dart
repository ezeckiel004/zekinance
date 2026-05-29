import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/onboarding_screen.dart';
import '../presentation/screens/auth/auth_shell.dart';
import '../presentation/screens/dashboard/main_shell.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/budget/budget_screen.dart';
import '../presentation/screens/budget/budget_detail_screen.dart';
import '../presentation/screens/transactions/transactions_screen.dart';
import '../presentation/screens/transactions/add_transaction_screen.dart';
import '../presentation/screens/savings/savings_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/coach/coach_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch authState to automatically trigger redirects when user logs in/out
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      // If user is not authenticated and trying to access main app, redirect to login
      if (!isAuthenticated && !isAuthRoute && state.matchedLocation != '/splash') {
        return '/auth/login';
      }
      
      // If user is authenticated
      if (isAuthenticated) {
        final isOnboardingCompleted = authState.monthlyIncome > 0.0;
        
        if (!isOnboardingCompleted) {
          if (state.matchedLocation != '/auth/onboarding') {
            return '/auth/onboarding';
          }
          return null;
        } else {
          if (isAuthRoute) {
            return '/dashboard';
          }
        }
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Auth shell route
      ShellRoute(
        builder: (context, state, child) => AuthShell(child: child),
        routes: [
          GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
          GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
          GoRoute(path: '/auth/onboarding', builder: (_, __) => const OnboardingScreen()),
        ],
      ),
      // Main App Shell containing index stacks (tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(shell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (Accueil)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Budgets
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budget',
                builder: (context, state) => const BudgetScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final categoryId = state.pathParameters['id'] ?? 'Alimentation';
                      return BudgetDetailScreen(categoryId: categoryId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Transactions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddTransactionScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Savings (Épargne)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/savings',
                builder: (context, state) => const SavingsScreen(),
              ),
            ],
          ),
          // Branch 4: Coach IA & Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/coach',
                builder: (context, state) => const CoachScreen(),
              ),
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class ZeKinanceApp extends ConsumerWidget {
  const ZeKinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ze Kinance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force premium dark mode as default visual theme
      routerConfig: router,
    );
  }
}
