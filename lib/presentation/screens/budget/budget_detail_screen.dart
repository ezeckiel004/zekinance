import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../core/localization/translations.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/settings_provider.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final String categoryId;

  const BudgetDetailScreen({super.key, required this.categoryId});

  String _getCategoryDisplayName(String key, bool isFr) {
    switch (key) {
      case 'Alimentation':
        return isFr ? 'Alimentation' : 'Food & Groceries';
      case 'Loyer & Factures':
        return isFr ? 'Loyer & Factures' : 'Rent & Bills';
      case 'Divertissement':
        return isFr ? 'Divertissement' : 'Entertainment';
      case 'Transport':
        return isFr ? 'Transport' : 'Transportation';
      case 'Santé':
        return isFr ? 'Santé' : 'Health';
      case 'Autres':
        return isFr ? 'Autres' : 'Others';
      default:
        return key;
    }
  }

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

  String _getMethodType(String name, bool isFr) {
    switch (name) {
      case 'Alimentation':
      case 'Loyer & Factures':
      case 'Transport':
      case 'Santé':
        return isFr ? 'Besoins stricts (50%)' : 'Strict Needs (50%)';
      case 'Divertissement':
      case 'Autres':
        return isFr ? 'Envies & Plaisirs (30%)' : 'Wants & Leisure (30%)';
      default:
        return isFr ? 'Besoins stricts (50%)' : 'Strict Needs (50%)';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final activeMonth = ref.watch(activeMonthProvider);
    final isFr = ref.watch(languageProvider) == 'fr';

    final catColor = _getCategoryColor(categoryId);
    final catIcon = _getCategoryIcon(categoryId);
    final methodType = _getMethodType(categoryId, isFr);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          _getCategoryDisplayName(categoryId, isFr),
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary),
        ),
      ),
      body: SafeArea(
        child: activeBudgetAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Text(
              '${context.tr(ref, 'error')}: $err',
              style: TextStyle(color: context.textPrimary),
            ),
          ),
          data: (budget) {
            if (budget == null) {
              return Center(
                child: Text(
                  isFr ? 'Aucun budget configuré pour ce mois.' : 'No budget configured for this month.',
                  style: TextStyle(color: context.textSecondary, fontSize: 16),
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
                  isFr 
                    ? 'Erreur lors du chargement des transactions : $err' 
                    : 'Error loading transactions: $err',
                  style: TextStyle(color: context.textPrimary),
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
                        isFr,
                      ),

                      const SizedBox(height: 32),

                      _buildCategoryActions(context, ref, budget, limit, isFr),

                      const SizedBox(height: 32),

                      Text(
                        isFr ? 'Dépenses de ce mois' : 'Expenses this month',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: context.textPrimary,
                            ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 16),

                      categoryTransactions.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: context.borderColor),
                              ),
                              child: Center(
                                child: Text(
                                  isFr ? 'Aucune dépense enregistrée ce mois-ci.' : 'No expenses recorded this month.',
                                  style: TextStyle(
                                    color: context.textSecondary,
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
                                final formattedDate = isFr
                                    ? DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(tx.date)
                                    : DateFormat('dd MMMM yyyy at HH:mm', 'en_US').format(tx.date);

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
                                              style: TextStyle(
                                                  color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(color: context.textSecondary, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          '-${tx.amount.toFCFA()}',
                                          style: TextStyle(
                                            color: context.textPrimary,
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
    bool isFr,
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
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Text(
            method.toUpperCase(),
            style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
                  backgroundColor: context.borderColor,
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
                    style: TextStyle(color: context.textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  Text(
                    isFr ? 'utilisé' : 'used',
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 28),
          Divider(color: context.borderColor),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(isFr ? 'DÉPENSÉ' : 'SPENT', style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(spent.toFCFA(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(width: 1, height: 35, color: context.borderColor),
              Column(
                children: [
                  Text(isFr ? 'RESTANT' : 'REMAINING', style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
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

  Widget _buildCategoryActions(BuildContext context, WidgetRef ref, BudgetModel budget, double currentLimit, bool isFr) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push('/transactions/add'),
            icon: const Icon(Icons.add_rounded, color: Colors.black),
            label: Text(isFr ? 'Ajouter dépense' : 'Add Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => _showEditLimitSheet(context, ref, budget, currentLimit, isFr),
            icon: Icon(Icons.edit_rounded, color: context.textPrimary),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  void _showEditLimitSheet(BuildContext context, WidgetRef ref, BudgetModel budget, double currentLimit, bool isFr) {
    final controller = TextEditingController(text: currentLimit.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
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
                    isFr 
                      ? 'Modifier la limite — ${_getCategoryDisplayName(categoryId, true)}' 
                      : 'Modify Limit — ${_getCategoryDisplayName(categoryId, false)}',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: context.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isFr 
                  ? 'Entrez la nouvelle limite budgétaire mensuelle affectée à cette catégorie.' 
                  : 'Enter the new monthly budget limit allocated to this category.',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
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
                        SnackBar(
                          content: Text(
                            isFr 
                              ? 'Veuillez entrer une limite valide supérieure ou égale à 0' 
                              : 'Please enter a valid limit greater than or equal to 0'
                          ),
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
                            content: Text(
                              isFr
                                ? 'Limite de ${_getCategoryDisplayName(categoryId, true)} mise à jour !'
                                : 'Limit of ${_getCategoryDisplayName(categoryId, false)} updated!'
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${context.tr(ref, 'error')}: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isFr ? 'Sauvegarder' : 'Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
