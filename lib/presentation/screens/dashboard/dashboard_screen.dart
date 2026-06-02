import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../core/localization/translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/savings_provider.dart';
import '../../../data/models/transaction_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final userName = user?.displayName ?? 'Utilisateur';
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, stack) => Center(child: Text('${context.tr(ref, 'error')}: $err', style: TextStyle(color: context.textPrimary))),
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

            final goals = goalsAsync.valueOrNull ?? [];
            final double totalEpargne = goals.fold(0.0, (sum, g) => sum + g.current);

            final budgetUsagePct = income > 0 ? (currentMonthExpenses / income) : 0.0;
            final healthScore = (100 - (budgetUsagePct * 100)).clamp(0.0, 100.0).toInt();

            String healthStatus = context.tr(ref, 'home_health_excellent');
            Color healthColor = AppColors.primary;
            if (healthScore < 50) {
              healthStatus = context.tr(ref, 'home_health_critical');
              healthColor = AppColors.error;
            } else if (healthScore < 80) {
              healthStatus = context.tr(ref, 'home_health_medium');
              healthColor = AppColors.secondary;
            }

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: context.surfaceColor,
              onRefresh: () async {
                ref.invalidate(transactionsStreamProvider);
                ref.invalidate(savingsGoalsStreamProvider);
                ref.invalidate(activeBudgetStreamProvider);
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    _buildHeader(context, ref, userName, user?.photoUrl),
                    
                    const SizedBox(height: 24),

                    // Account Balance Card (Glowing Emerald Gradient)
                    _buildBalanceCard(context, ref, availableBalance, totalEpargne),

                    const SizedBox(height: 28),

                    // Quick Actions Row
                    _buildQuickActions(context, ref),

                    const SizedBox(height: 28),

                    // Financial Health Card & Mini AI Banner (Double Grid / Column)
                    _buildHealthAndCoachSection(context, ref, healthScore, healthStatus, healthColor, currentMonthExpenses, lang),

                    const SizedBox(height: 28),

                    // Recent Transactions List
                    _buildRecentTransactions(context, ref, transactions),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String name, String? avatarUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(ref, 'home_greeting'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
              ),
            ),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        // Premium Profile Avatar
        GestureDetector(
          onTap: () {
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
              backgroundColor: context.surfaceColorLight,
              child: avatarUrl == null 
                ? Icon(Icons.person, color: context.textPrimary)
                : null,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref, double currentBalance, double totalEpargne) {
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
                context.tr(ref, 'home_available'),
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
                    context.tr(ref, 'home_saved'),
                    style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalEpargne.toFCFA(),
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

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final isFr = ref.watch(languageProvider) == 'fr';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          context,
          icon: Icons.qr_code_scanner_rounded,
          label: isFr ? 'Scan Reçu' : 'Scan Receipt',
          color: AppColors.accent,
          onTap: () {
            context.go('/transactions/add');
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.mic_rounded,
          label: isFr ? 'Voix' : 'Voice',
          color: AppColors.secondary,
          onTap: () {
            context.go('/transactions/add');
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.add_rounded,
          label: context.tr(ref, 'home_action_add_tx'),
          color: AppColors.primary,
          onTap: () {
            context.go('/transactions/add');
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.trending_down_rounded,
          label: isFr ? 'Simulateur' : 'Simulator',
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
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAndCoachSection(
    BuildContext context,
    WidgetRef ref,
    int healthScore,
    String healthStatus,
    Color healthColor,
    double expenses,
    String lang,
  ) {
    String coachTip = '';
    if (lang == 'fr') {
      coachTip = '"Votre santé financière est excellente. Continuez sur cette lancée en maintenant vos dépenses sous contrôle !"';
      if (healthScore < 50) {
        coachTip = '"Vos dépenses mensuelles sont très élevées. Pensez à limiter vos envies et concentrez-vous sur vos besoins stricts pour redresser la barre !"';
      } else if (healthScore < 80) {
        coachTip = '"Votre budget est un peu serré. Une réduction mineure de 10% sur vos loisirs ce mois-ci vous permettrait d\'équilibrer vos comptes."';
      }
    } else {
      coachTip = '"Your financial health is excellent. Keep it up by keeping your spending under control!"';
      if (healthScore < 50) {
        coachTip = '"Your monthly expenses are very high. Think about limiting non-essentials and focus strictly on needs to get back on track!"';
      } else if (healthScore < 80) {
        coachTip = '"Your budget is slightly tight. A minor 10% reduction on leisure this month would help balance your accounts."';
      }
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
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(ref, 'home_health'),
                  style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
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
                          backgroundColor: context.borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$healthScore',
                            style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(color: context.textSecondary, fontSize: 10),
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
                colors: [context.surfaceColor, context.surfaceColorLight.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang == 'fr' ? 'Conseil de FinCoach' : 'FinCoach Advice',
                        style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold),
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
                    style: TextStyle(color: context.textPrimary, fontSize: 11, height: 1.4, fontStyle: FontStyle.italic),
                    overflow: TextOverflow.fade,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.go('/profile'), // Nav to Profile contains AI Coach in secondary sub-branch
                  child: Text(
                    lang == 'fr' ? 'Discuter →' : 'Discuss →',
                    style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRecentTransactions(BuildContext context, WidgetRef ref, List<TransactionModel> txs) {
    final displayTxs = txs.take(3).toList();
    final lang = ref.watch(languageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr(ref, 'home_recent_tx'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: context.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/transactions'),
              child: Text(
                context.tr(ref, 'home_see_all'),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
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
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: Center(
              child: Text(
                lang == 'fr' ? 'Aucune transaction récente' : 'No recent transactions',
                style: TextStyle(color: context.textSecondary),
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
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
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
                            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tx.category} • $formattedDate',
                            style: TextStyle(color: context.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      (isExpense ? '-' : '+') + tx.amount.toFCFA(),
                      style: TextStyle(
                        color: isExpense ? context.textPrimary : AppColors.primary,
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
