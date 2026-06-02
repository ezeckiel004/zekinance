import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../core/localization/translations.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../providers/savings_provider.dart';
import '../../providers/settings_provider.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  String _getSavingsCategoryDisplayName(String key, bool isFr) {
    switch (key) {
      case 'Logement':
        return isFr ? 'Logement' : 'Housing';
      case 'Voyage':
        return isFr ? 'Voyage' : 'Travel';
      case 'Auto / Moto':
        return isFr ? 'Auto / Moto' : 'Vehicle';
      case 'Éducation':
        return isFr ? 'Éducation' : 'Education';
      case 'Projet Pro':
        return isFr ? 'Projet Pro' : 'Business';
      case 'Urgence':
        return isFr ? 'Urgence' : 'Emergency';
      case 'Autre':
        return isFr ? 'Autre' : 'Other';
      default:
        return key;
    }
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'Logement':
        return Icons.home_rounded;
      case 'Voyage':
        return Icons.flight_rounded;
      case 'Auto / Moto':
        return Icons.directions_car_rounded;
      case 'Éducation':
        return Icons.school_rounded;
      case 'Projet Pro':
        return Icons.business_center_rounded;
      case 'Urgence':
        return Icons.local_hospital_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final isFr = ref.watch(languageProvider) == 'fr';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          isFr ? 'Mon Épargne' : 'My Savings',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    '${isFr ? 'Erreur lors du chargement' : 'Error loading savings'}: $err',
                    style: TextStyle(color: context.textPrimary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (goals) {
            double totalEpargne = goals.fold(0.0, (sum, g) => sum + g.current);

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: context.surfaceColor,
              onRefresh: () async {
                ref.invalidate(savingsGoalsStreamProvider);
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Savings Card
                    _buildSavingsOverview(context, ref, totalEpargne, isFr),

                    const SizedBox(height: 32),

                    // Goals Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isFr ? 'Objectifs actifs' : 'Active goals',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: context.textPrimary,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => _showAddGoalSheet(context, ref, isFr),
                            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 16),

                    if (goals.isEmpty)
                      _buildEmptyState(context, ref, isFr)
                    else
                      // List of savings goals
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: goals.length,
                        itemBuilder: (context, index) {
                          final goal = goals[index];
                          final progression = goal.target > 0 
                              ? (goal.current / goal.target * 100).clamp(0.0, 100.0) 
                              : 0.0;
                          
                          final monthsLeft = (goal.deadline.difference(DateTime.now()).inDays / 30).clamp(1.0, 120.0);
                          final monthlyNeeded = goal.current >= goal.target 
                              ? 0.0 
                              : (goal.target - goal.current) / monthsLeft;

                          Color progressColor;
                          if (progression >= 100) {
                            progressColor = AppColors.primary;
                          } else if (progression >= 50) {
                            progressColor = AppColors.secondary;
                          } else {
                            progressColor = AppColors.accent;
                          }

                          return GestureDetector(
                            onTap: () => _showGoalDetailsSheet(context, ref, goal, isFr),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: context.borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: progressColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _getCategoryIcon(goal.category),
                                                color: progressColor,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                goal.name,
                                                style: TextStyle(
                                                  color: context.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: progressColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${progression.toInt()}%',
                                          style: TextStyle(
                                            color: progressColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progression / 100,
                                      minHeight: 6,
                                      backgroundColor: context.borderColor,
                                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isFr ? 'Actuel' : 'Current',
                                              style: TextStyle(color: context.textSecondary, fontSize: 10),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              goal.current.toFCFA(),
                                              style: TextStyle(
                                                color: context.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              isFr ? 'Mensuel Requis' : 'Monthly Required',
                                              style: TextStyle(color: context.textSecondary, fontSize: 10),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              monthlyNeeded.toFCFA(),
                                              style: TextStyle(
                                                color: monthlyNeeded > 0 ? AppColors.accent : AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              isFr ? 'Cible' : 'Target',
                                              style: TextStyle(color: context.textSecondary, fontSize: 10),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              goal.target.toFCFA(),
                                              style: TextStyle(
                                                color: context.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSavingsOverview(BuildContext context, WidgetRef ref, double total, bool isFr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr(ref, 'savings_total'),
                style: TextStyle(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const Icon(Icons.savings_rounded, color: AppColors.secondary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            total.toFCFA(),
            style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFr 
              ? 'Vos réserves d\'épargne accumulées' 
              : 'Your accumulated savings reserves',
            style: TextStyle(color: context.textSecondary, fontSize: 11),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(duration: 400.ms);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isFr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isFr ? 'Aucun objectif actif' : 'No active goals',
            style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(ref, 'savings_no_goals'),
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddGoalSheet(context, ref, isFr),
            icon: const Icon(Icons.add_rounded, color: Colors.black),
            label: Text(context.tr(ref, 'savings_create_goal')),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref, bool isFr) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final currentController = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    
    String selectedCategory = 'Voyage';
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 365));

    final categories = ['Voyage', 'Logement', 'Auto / Moto', 'Éducation', 'Projet Pro', 'Urgence', 'Autre'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr(ref, 'savings_new_goal_title'),
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
                      const SizedBox(height: 16),
                      
                      Text(
                        isFr ? 'NOM DE L\'OBJECTIF' : 'GOAL NAME', 
                        style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: isFr ? 'Ex: Voyage au Kenya' : 'e.g. Trip to Kenya',
                          hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty 
                            ? (isFr ? 'Veuillez entrer un nom' : 'Please enter a name') 
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        isFr ? 'CATÉGORIE' : 'CATEGORY', 
                        style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSelected = selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(_getSavingsCategoryDisplayName(cat, isFr)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  selectedCategory = cat;
                                });
                              }
                            },
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : context.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            selectedColor: AppColors.primary,
                            backgroundColor: context.surfaceColorLight,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFr ? 'MONTANT CIBLE' : 'TARGET AMOUNT', 
                                  style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: targetController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: context.textPrimary),
                                  decoration: const InputDecoration(
                                    hintText: 'FCFA',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return isFr ? 'Obligatoire' : 'Required';
                                    }
                                    final d = double.tryParse(val);
                                    if (d == null || d <= 0) return isFr ? 'Invalide' : 'Invalid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFr ? 'APPORT INITIAL' : 'INITIAL AMOUNT', 
                                  style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: currentController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: context.textPrimary),
                                  decoration: const InputDecoration(
                                    hintText: 'FCFA',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return null;
                                    final d = double.tryParse(val);
                                    if (d == null || d < 0) return isFr ? 'Invalide' : 'Invalid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text(
                        isFr ? 'ÉCHÉANCE CIBLE' : 'TARGET DEADLINE', 
                        style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDeadline,
                            firstDate: DateTime.now().add(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDeadline = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: context.surfaceColorLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMMM yyyy').format(selectedDeadline),
                                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            
                            final name = nameController.text.trim();
                            final target = double.parse(targetController.text.trim());
                            final current = double.parse(currentController.text.trim());

                            try {
                              await ref.read(savingsOperationsProvider.notifier).addGoal(
                                name: name,
                                target: target,
                                current: current,
                                category: selectedCategory,
                                deadline: selectedDeadline,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr(ref, 'savings_goal_added')),
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
                          child: Text(isFr ? 'Créer l\'objectif' : 'Create Goal'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showGoalDetailsSheet(BuildContext context, WidgetRef ref, SavingsGoalModel goal, bool isFr) {
    final progression = goal.target > 0 ? (goal.current / goal.target * 100).clamp(0.0, 100.0) : 0.0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getSavingsCategoryDisplayName(goal.category, isFr).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: context.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                goal.name,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isFr ? 'Échéance' : 'Deadline'}: ${DateFormat('dd MMMM yyyy').format(goal.deadline)}',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Progress Bar Visual
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isFr ? 'Progression globale' : 'Overall Progress', 
                    style: TextStyle(color: context.textSecondary, fontSize: 13)
                  ),
                  Text(
                    '${progression.toStringAsFixed(1)}%',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progression / 100,
                  minHeight: 8,
                  backgroundColor: context.borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),

              // Numeric indicators
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.surfaceColorLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isFr ? 'ÉPARGNÉ' : 'SAVED', style: TextStyle(color: context.textSecondary, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          goal.current.toFCFA(),
                          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(isFr ? 'CIBLE' : 'TARGET', style: TextStyle(color: context.textSecondary, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          goal.target.toFCFA(),
                          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAdjustFundsSheet(context, ref, goal, false, isFr);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        context.tr(ref, 'savings_withdraw'),
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAdjustFundsSheet(context, ref, goal, true, isFr);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        context.tr(ref, 'savings_add'),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(savingsOperationsProvider.notifier).deleteGoal(goal.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFr 
                                ? 'Objectif d\'épargne supprimé' 
                                : 'Savings goal deleted'
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${context.tr(ref, 'error')}: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                  label: Text(
                    isFr ? 'Supprimer l\'objectif' : 'Delete Goal',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdjustFundsSheet(BuildContext context, WidgetRef ref, SavingsGoalModel goal, bool isDeposit, bool isFr) {
    final amountController = TextEditingController();
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
                      isDeposit 
                          ? context.tr(ref, 'savings_add_fund_title') 
                          : context.tr(ref, 'savings_withdraw_fund_title'),
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
                  isDeposit 
                      ? (isFr ? 'Déposez de l\'argent vers cet objectif.' : 'Deposit money to this goal.')
                      : (isFr ? 'Retirez de l\'argent de cet objectif.' : 'Withdraw money from this goal.'),
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr(ref, 'savings_amount_label').toUpperCase(), 
                  style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixText: 'FCFA  ',
                    prefixStyle: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                    hintText: 'Ex: 15000',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return isFr ? 'Veuillez entrer un montant' : 'Please enter an amount';
                    }
                    final d = double.tryParse(val);
                    if (d == null || d <= 0) {
                      return isFr ? 'Montant invalide' : 'Invalid amount';
                    }
                    if (!isDeposit && d > goal.current) {
                      return isFr 
                          ? 'Solde d\'épargne insuffisant' 
                          : 'Insufficient savings balance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      
                      final amount = double.parse(amountController.text.trim());
                      
                      try {
                        await ref.read(savingsOperationsProvider.notifier).makeDeposit(
                          goal,
                          isDeposit ? amount : -amount,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr(ref, 'savings_fund_updated')),
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
                    child: Text(isFr ? 'Valider' : 'Submit'),
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
