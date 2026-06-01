import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'Alimentation':
        return Icons.restaurant_rounded;
      case 'Loyer & Factures':
        return Icons.home_rounded;
      case 'Divertissement':
        return Icons.celebration_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Santé':
        return Icons.healing_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }

  Color _getCategoryColor(String name) {
    switch (name) {
      case 'Alimentation':
        return AppColors.secondary;
      case 'Loyer & Factures':
        return AppColors.info;
      case 'Divertissement':
        return AppColors.error;
      case 'Transport':
        return AppColors.accent;
      case 'Santé':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);
    final user = ref.watch(authStateProvider);
    final activeMonth = ref.watch(activeMonthProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Mes Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            onPressed: () async {
              final now = DateTime.now();
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 2),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (selectedDate != null) {
                final monthStr = DateFormat('yyyy-MM').format(selectedDate);
                ref.read(activeMonthProvider.notifier).state = monthStr;
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: activeBudgetAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Erreur lors du chargement : $err',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          data: (budget) {
            if (budget == null) {
              return _buildEmptyState(context, ref, user?.monthlyIncome ?? 250000.0, activeMonth);
            }

            final spentTotal = budget.categories.values.fold(0.0, (sum, cat) => sum + cat.spent);
            final remainingTotal = (budget.totalBudget - spentTotal).clamp(0.0, double.infinity);

            final categoryEntries = budget.categories.entries.toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Card
                  _buildOverviewCard(context, budget.totalBudget, spentTotal, remainingTotal),

                  const SizedBox(height: 32),

                  // Method Explainer
                  _buildMethodExplainer(context),

                  const SizedBox(height: 32),

                  // Categories Header
                  Text(
                    'Répartition par catégorie',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 16),

                  // List of category budgets
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryEntries.length,
                    itemBuilder: (context, index) {
                      final entry = categoryEntries[index];
                      final catName = entry.key;
                      final catBudget = entry.value;

                      final pct = catBudget.percentage;
                      final isCritique = catBudget.isCritical;
                      final isAlerte = catBudget.isAlert;

                      Color statusColor = AppColors.primary;
                      String alertMessage = 'Sous contrôle';
                      IconData alertIcon = Icons.check_circle_outline_rounded;

                      if (isCritique) {
                        statusColor = AppColors.error;
                        alertMessage = 'Critique (Dépassement imminent)';
                        alertIcon = Icons.error_outline_rounded;
                      } else if (isAlerte) {
                        statusColor = AppColors.secondary;
                        alertMessage = 'Alerte (Seuil des 70% franchi)';
                        alertIcon = Icons.warning_amber_rounded;
                      }

                      return GestureDetector(
                        onTap: () {
                          context.push('/budget/$catName');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            border: Border.all(
                              color: isCritique
                                  ? AppColors.error.withOpacity(0.4)
                                  : (isAlerte ? AppColors.secondary.withOpacity(0.3) : AppColors.darkBorder),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(catName).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(_getCategoryIcon(catName), color: _getCategoryColor(catName), size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          catName,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(alertIcon, color: statusColor, size: 12),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                alertMessage,
                                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${pct.toInt()}%',
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Restant : ${catBudget.remaining.toFCFA()}',
                                          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100,
                                  minHeight: 6,
                                  backgroundColor: AppColors.darkBorder,
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Dépensé : ${catBudget.spent.toFCFA()}',
                                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Limite : ${catBudget.limit.toFCFA()}',
                                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, double total, double spent, double remaining) {
    final pctSpent = total > 0 ? (spent / total * 100).toInt().clamp(0, 100) : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dépenses totales', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      spent.toFCFA(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Budget Global : ${total.toFCFA()}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 18,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: pctSpent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(9),
                        bottomLeft: const Radius.circular(9),
                        topRight: Radius.circular(pctSpent >= 99 ? 9 : 0),
                        bottomRight: Radius.circular(pctSpent >= 99 ? 9 : 0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - pctSpent,
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$pctSpent% utilisé ce mois',
                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Restant : ${remaining.toFCFA()}',
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildMethodExplainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Méthode budgétaire active',
                  style: const TextStyle(color: AppColors.secondary, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Vous utilisez la règle simplifiée 50/30/20. Vos besoins stricts sont limités à 50%, vos loisirs à 30% et vous mettez de côté au moins 20% pour vos projets futurs.',
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, double income, String activeMonth) {
    final tempDate = DateTime.tryParse('$activeMonth-01') ?? DateTime.now();
    final formattedMonth = DateFormat('MMMM yyyy').format(tempDate);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.darkBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.04),
                blurRadius: 24,
                spreadRadius: 4,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pas de budget pour $formattedMonth',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Configurez vos limites mensuelles pour ce mois afin de suivre intelligemment vos dépenses avec la méthode 50/30/20.',
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final totalBudget = income;
                    final categoryLimits = {
                      'Alimentation': income * 0.20,
                      'Loyer & Factures': income * 0.30,
                      'Divertissement': income * 0.15,
                      'Transport': income * 0.10,
                      'Santé': income * 0.05,
                      'Autres': income * 0.00,
                    };

                    try {
                      await ref.read(budgetOperationsProvider.notifier).initializeBudget(
                        activeMonth,
                        totalBudget,
                        categoryLimits,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Budget de $formattedMonth initialisé avec succès !'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Initialiser mon budget'),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
    );
  }
}
