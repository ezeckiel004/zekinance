import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final String categoryId;

  const BudgetDetailScreen({super.key, required this.categoryId});

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

  String _getMethodType(String name) {
    switch (name) {
      case 'Alimentation':
      case 'Loyer & Factures':
      case 'Transport':
      case 'Santé':
        return 'Besoins stricts (50%)';
      case 'Divertissement':
      case 'Autres':
        return 'Envies & Plaisirs (30%)';
      default:
        return 'Besoins stricts (50%)';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final activeMonth = ref.watch(activeMonthProvider);

    final catColor = _getCategoryColor(categoryId);
    final catIcon = _getCategoryIcon(categoryId);
    final methodType = _getMethodType(categoryId);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(categoryId),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
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
              return Center(
                child: Text(
                  'Aucun budget configuré pour ce mois.',
                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 16),
                ),
              );
            }

            final categoryBudget = budget.categories[categoryId] ?? CategoryBudget(limit: 0.0);
            final double limit = categoryBudget.limit;
            final double spent = categoryBudget.spent;
            final double remaining = categoryBudget.remaining;
            final double pctSpent = categoryBudget.percentage;

            return transactionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Erreur lors du chargement des transactions : $err',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              data: (transactions) {
                final categoryTransactions = transactions.where((tx) {
                  final txMonth = DateFormat('yyyy-MM').format(tx.date);
                  return tx.category == categoryId &&
                      tx.type == TransactionType.expense &&
                      txMonth == activeMonth;
                }).toList();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLargeRadialIndicator(
                        context,
                        categoryId,
                        limit,
                        spent,
                        remaining,
                        pctSpent,
                        catColor,
                        catIcon,
                        methodType,
                      ),

                      const SizedBox(height: 32),

                      _buildCategoryActions(context, ref, budget, limit),

                      const SizedBox(height: 32),

                      Text(
                        'Dépenses de ce mois',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 16),

                      categoryTransactions.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.darkBorder),
                              ),
                              child: const Center(
                                child: Text(
                                  'Aucune dépense enregistrée ce mois-ci.',
                                  style: TextStyle(
                                    color: AppColors.darkTextSecondary,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: categoryTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = categoryTransactions[index];
                                final formattedDate = DateFormat('dd MMMM yyyy à HH:mm').format(tx.date);

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
                                          color: catColor.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(catIcon, color: catColor, size: 18),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx.description,
                                              style: const TextStyle(
                                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          '-${tx.amount.toFCFA()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLargeRadialIndicator(
    BuildContext context,
    String name,
    double limit,
    double spent,
    double remaining,
    double pct,
    Color color,
    IconData icon,
    String method,
  ) {
    final isCritique = pct >= 90;
    final isAlerte = pct >= 70;

    Color statusColor = AppColors.primary;
    if (isCritique) {
      statusColor = AppColors.error;
    } else if (isAlerte) {
      statusColor = AppColors.secondary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Text(
            method.toUpperCase(),
            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 14,
                  backgroundColor: AppColors.darkBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 30),
                  const SizedBox(height: 6),
                  Text(
                    '${pct.toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const Text(
                    'utilisé',
                    style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 28),
          const Divider(color: AppColors.darkBorder),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('DÉPENSÉ', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(spent.toFCFA(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(width: 1, height: 35, color: AppColors.darkBorder),
              Column(
                children: [
                  const Text('RESTANT', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(remaining.toFCFA(), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryActions(BuildContext context, WidgetRef ref, BudgetModel budget, double currentLimit) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push('/transactions/add'),
            icon: const Icon(Icons.add_rounded, color: Colors.black),
            label: const Text('Ajouter dépense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            border: Border.all(color: AppColors.darkBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => _showEditLimitSheet(context, ref, budget, currentLimit),
            icon: const Icon(Icons.edit_rounded, color: AppColors.darkTextPrimary),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  void _showEditLimitSheet(BuildContext context, WidgetRef ref, BudgetModel budget, double currentLimit) {
    final controller = TextEditingController(text: currentLimit.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modifier la limite — $categoryId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.darkTextSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez la nouvelle limite budgétaire mensuelle affectée à cette catégorie.',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: 'FCFA  ',
                  prefixStyle: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                  hintText: 'Ex: 100000',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    final double? newLimit = double.tryParse(text);

                    if (newLimit == null || newLimit < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer une limite valide supérieure ou égale à 0'),
                        ),
                      );
                      return;
                    }

                    try {
                      await ref.read(budgetOperationsProvider.notifier).updateCategoryLimit(
                            budget,
                            categoryId,
                            newLimit,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Limite de $categoryId mise à jour !'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Sauvegarder'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
