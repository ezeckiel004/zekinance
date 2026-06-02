import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../core/localization/translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../../data/models/budget_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);
    final user = ref.watch(authStateProvider);
    final activeMonth = ref.watch(activeMonthProvider);
    final isFr = ref.watch(languageProvider) == 'fr';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          context.tr(ref, 'budget_title'),
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
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
              '${context.tr(ref, 'error')}: $err',
              style: TextStyle(color: context.textPrimary),
            ),
          ),
          data: (budget) {
            if (budget == null) {
              return _buildEmptyState(context, ref, user?.monthlyIncome ?? 250000.0, activeMonth, isFr);
            }

            final spentTotal = budget.categories.values.fold(0.0, (sum, cat) => sum + cat.spent);
            final remainingTotal = (budget.totalBudget - spentTotal).clamp(0.0, double.infinity);

            final categoryEntries = budget.categories.entries.toList();

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: context.surfaceColor,
              onRefresh: () async {
                ref.invalidate(activeBudgetStreamProvider);
                ref.invalidate(transactionsStreamProvider);
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Card
                    _buildOverviewCard(context, ref, budget.totalBudget, spentTotal, remainingTotal, isFr),

                    const SizedBox(height: 32),

                    // Method Explainer
                    _buildMethodExplainer(context, isFr),

                    const SizedBox(height: 32),

                    // Categories Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isFr ? 'Répartition par catégorie' : 'Allocation by category',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _showAddCategorySheet(context, ref, budget, isFr),
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                          label: Text(
                            isFr ? 'Ajouter' : 'Add',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
                        String alertMessage = isFr ? 'Sous contrôle' : 'Under control';
                        IconData alertIcon = Icons.check_circle_outline_rounded;

                        if (isCritique) {
                          statusColor = AppColors.error;
                          alertMessage = isFr ? 'Critique (Dépassement imminent)' : 'Critical (Overspend imminent)';
                          alertIcon = Icons.error_outline_rounded;
                        } else if (isAlerte) {
                          statusColor = AppColors.secondary;
                          alertMessage = isFr ? 'Alerte (Seuil des 70% franchi)' : 'Alert (70% threshold crossed)';
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
                              color: context.surfaceColor,
                              border: Border.all(
                                color: isCritique
                                    ? AppColors.error.withOpacity(0.4)
                                    : (isAlerte ? AppColors.secondary.withOpacity(0.3) : context.borderColor),
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
                                            _getCategoryDisplayName(catName, isFr),
                                            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
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
                                            '${isFr ? 'Restant' : 'Remaining'}: ${catBudget.remaining.toFCFA()}',
                                            style: TextStyle(color: context.textSecondary, fontSize: 11),
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
                                    backgroundColor: context.borderColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${isFr ? 'Dépensé' : 'Spent'}: ${catBudget.spent.toFCFA()}',
                                        style: TextStyle(color: context.textSecondary, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${isFr ? 'Limite' : 'Limit'}: ${catBudget.limit.toFCFA()}',
                                        style: TextStyle(color: context.textSecondary, fontSize: 12),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, WidgetRef ref, double total, double spent, double remaining, bool isFr) {
    final pctSpent = total > 0 ? (spent / total * 100).toInt().clamp(0, 100) : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor),
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
                    Text(context.tr(ref, 'budget_total_expense'), style: TextStyle(color: context.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      spent.toFCFA(),
                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
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
                    '${isFr ? 'Budget Global' : 'Global Budget'}: ${total.toFCFA()}',
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
              color: context.borderColor,
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
                  isFr ? '$pctSpent% utilisé ce mois' : '$pctSpent% used this month',
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${isFr ? 'Restant' : 'Remaining'}: ${remaining.toFCFA()}',
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

  Widget _buildMethodExplainer(BuildContext context, bool isFr) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColorLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
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
                  isFr ? 'Méthode budgétaire active' : 'Active budgeting method',
                  style: const TextStyle(color: AppColors.secondary, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isFr 
              ? 'Vous utilisez la règle simplifiée 50/30/20. Vos besoins stricts sont limités à 50%, vos loisirs à 30% et vous mettez de côté au moins 20% pour vos projets futurs.'
              : 'You are using the simplified 50/30/20 rule. Your strict needs are limited to 50%, your leisure to 30% and you save at least 20% for future projects.',
            style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, double income, String activeMonth, bool isFr) {
    final tempDate = DateTime.tryParse('$activeMonth-01') ?? DateTime.now();
    final formattedMonth = isFr 
        ? DateFormat('MMMM yyyy', 'fr_FR').format(tempDate)
        : DateFormat('MMMM yyyy', 'en_US').format(tempDate);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: context.surfaceColor,
      onRefresh: () async {
        ref.invalidate(activeBudgetStreamProvider);
        await Future.delayed(const Duration(milliseconds: 800));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: context.borderColor),
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
                    isFr ? 'Pas de budget pour $formattedMonth' : 'No budget for $formattedMonth',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isFr
                      ? 'Configurez vos limites mensuelles pour ce mois afin de suivre intelligemment vos dépenses avec la méthode 50/30/20.'
                      : 'Configure your monthly limits for this month to track your expenses intelligently with the 50/30/20 method.',
                    style: TextStyle(
                      color: context.textSecondary,
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFr 
                                    ? 'Budget de $formattedMonth initialisé avec succès !' 
                                    : 'Budget of $formattedMonth successfully initialized!'
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
                      child: Text(isFr ? 'Initialiser mon budget' : 'Initialize my budget'),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        ],
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, WidgetRef ref, BudgetModel budget, bool isFr) {
    final nameController = TextEditingController();
    final limitController = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr(ref, 'budget_add_category'),
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
                    ? 'Créez une catégorie personnalisée et définissez sa limite mensuelle.' 
                    : 'Create a custom category and set its monthly limit.',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Text(
                  isFr ? 'NOM DE LA CATÉGORIE' : 'CATEGORY NAME',
                  style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: isFr ? 'Ex: Éducation, Cadeaux, Voyage...' : 'e.g. Education, Gifts, Travel...',
                    prefixIcon: Icon(Icons.label_outline_rounded, color: context.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isFr ? 'Veuillez entrer un nom' : 'Please enter a name';
                    }
                    if (budget.categories.keys.any((k) => k.toLowerCase() == value.trim().toLowerCase())) {
                      return isFr ? 'Cette catégorie existe déjà' : 'This category already exists';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  isFr ? 'LIMITE MENSUELLE (FCFA)' : 'MONTHLY LIMIT (FCFA)',
                  style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixText: 'FCFA  ',
                    prefixStyle: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                    hintText: 'Ex: 50000',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isFr ? 'Veuillez entrer une limite' : 'Please enter a limit';
                    }
                    final limit = double.tryParse(value);
                    if (limit == null || limit < 0) {
                      return isFr ? 'Veuillez entrer un montant valide' : 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final name = nameController.text.trim();
                      final limit = double.parse(limitController.text.trim());

                      try {
                        await ref.read(budgetOperationsProvider.notifier).addCategory(
                              budget,
                              name,
                              limit,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFr 
                                  ? 'Catégorie "$name" ajoutée avec succès !' 
                                  : 'Category "$name" successfully added!'
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
                    child: Text(isFr ? 'Créer la catégorie' : 'Create Category'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
