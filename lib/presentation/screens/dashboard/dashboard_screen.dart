import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/transaction_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final userName = user?.displayName ?? 'Utilisateur';
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.white))),
          data: (transactions) {
            final income = user?.monthlyIncome ?? 250000.0;
            final currentMonthStr = DateFormat('yyyy-MM').format(DateTime.now());

            final currentMonthExpenses = transactions.where((tx) {
              final isSameMonth = DateFormat('yyyy-MM').format(tx.date) == currentMonthStr;
              return isSameMonth && tx.type == TransactionType.expense;
            }).fold(0.0, (sum, tx) => sum + tx.amount);

            final currentMonthIncomes = transactions.where((tx) {
              final isSameMonth = DateFormat('yyyy-MM').format(tx.date) == currentMonthStr;
              return isSameMonth && tx.type == TransactionType.income;
            }).fold(0.0, (sum, tx) => sum + tx.amount);

            final double availableBalance = income + currentMonthIncomes - currentMonthExpenses;
            final double monthlySavings = (income * 0.20) + (currentMonthIncomes - currentMonthExpenses).clamp(0, double.infinity);

            final budgetUsagePct = income > 0 ? (currentMonthExpenses / income) : 0.0;
            final healthScore = (100 - (budgetUsagePct * 100)).clamp(0.0, 100.0).toInt();

            String healthStatus = 'Excellent';
            Color healthColor = AppColors.primary;
            if (healthScore < 50) {
              healthStatus = 'Critique';
              healthColor = AppColors.error;
            } else if (healthScore < 80) {
              healthStatus = 'Moyen';
              healthColor = AppColors.secondary;
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  _buildHeader(context, userName, user?.photoUrl),
                  
                  const SizedBox(height: 24),

                  // Account Balance Card (Glowing Emerald Gradient)
                  _buildBalanceCard(context, availableBalance, monthlySavings),

                  const SizedBox(height: 28),

                  // Quick Actions Row
                  _buildQuickActions(context),

                  const SizedBox(height: 28),

                  // Financial Health Card & Mini AI Banner (Double Grid / Column)
                  _buildHealthAndCoachSection(context, healthScore, healthStatus, healthColor, currentMonthExpenses),

                  const SizedBox(height: 28),

                  // Recent Transactions List
                  _buildRecentTransactions(context, transactions),
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String? avatarUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour,',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // Premium Profile Avatar
        GestureDetector(
          onTap: () {
            // Take to profile tab
            context.go('/profile');
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              backgroundColor: AppColors.darkSurfaceLight,
              child: avatarUrl == null 
                ? const Icon(Icons.person, color: AppColors.darkTextPrimary)
                : null,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildBalanceCard(BuildContext context, double currentBalance, double monthlySavings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solde disponible',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.wallet_rounded, color: Colors.black87),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentBalance.toFCFA(),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Épargne ce mois',
                    style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monthlySavings.toFCFA(),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              // Subtly styled capsule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.trending_up_rounded, color: Colors.black, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          context,
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan Reçu',
          color: AppColors.accent,
          onTap: () {
            // Take to adding transaction with mock OCR
            context.go('/transactions/add');
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.mic_rounded,
          label: 'Voix',
          color: AppColors.secondary,
          onTap: () {
            context.go('/transactions/add');
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.add_rounded,
          label: 'Transaction',
          color: AppColors.primary,
          onTap: () {
            context.go('/transactions/add');
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.trending_down_rounded,
          label: 'Simulateur',
          color: AppColors.info,
          onTap: () {
            context.go('/budget');
          },
        ),
      ],
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAndCoachSection(
    BuildContext context,
    int healthScore,
    String healthStatus,
    Color healthColor,
    double expenses,
  ) {
    // Generate dynamic tip based on health status
    String coachTip = '"Votre santé financière est excellente. Continuez sur cette lancée en maintenant vos dépenses sous contrôle !"';
    if (healthScore < 50) {
      coachTip = '"Vos dépenses mensuelles sont très élevées. Pensez à limiter vos envies et concentrez-vous sur vos besoins stricts pour redresser la barre !"';
    } else if (healthScore < 80) {
      coachTip = '"Votre budget est un peu serré. Une réduction mineure de 10% sur vos loisirs ce mois-ci vous permettrait d\'équilibrer vos comptes."';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Health Score Card (Left)
        Expanded(
          flex: 11,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Santé financière',
                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial Progress Bar
                      SizedBox(
                        height: 75,
                        width: 75,
                        child: CircularProgressIndicator(
                          value: healthScore / 100.0,
                          strokeWidth: 8,
                          backgroundColor: AppColors.darkBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$healthScore',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            '/100',
                            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: healthColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      healthStatus,
                      style: TextStyle(color: healthColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Coach IA Tip Card (Right)
        Expanded(
          flex: 13,
          child: Container(
            height: 163, // Align height with the left card
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.darkSurface, AppColors.darkSurfaceLight.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.psychology_rounded, color: AppColors.accent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Conseil de FinCoach',
                        style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    coachTip,
                    style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 11, height: 1.4, fontStyle: FontStyle.italic),
                    overflow: TextOverflow.fade,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.go('/profile'), // AI Coach is sub-branch of profile
                  child: const Text(
                    'Discuter →',
                    style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRecentTransactions(BuildContext context, List<TransactionModel> txs) {
    final displayTxs = txs.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transactions récentes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/transactions'),
              child: const Text(
                'Voir tout',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (displayTxs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Center(
              child: Text(
                'Aucune transaction récente',
                style: TextStyle(color: AppColors.darkTextSecondary),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayTxs.length,
            itemBuilder: (context, index) {
              final tx = displayTxs[index];
              final isExpense = tx.type == TransactionType.expense;
              final formattedDate = DateFormat('dd MMM, HH:mm').format(tx.date);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isExpense ? AppColors.error : AppColors.primary).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpense ? Icons.shopping_bag_outlined : Icons.monetization_on_outlined,
                        color: isExpense ? AppColors.error : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.description,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tx.category} • $formattedDate',
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      (isExpense ? '-' : '+') + tx.amount.toFCFA(),
                      style: TextStyle(
                        color: isExpense ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0);
  }
}
