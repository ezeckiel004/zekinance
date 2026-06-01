import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../providers/savings_provider.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Mon Épargne'),
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
                    'Erreur lors du chargement: $err',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (goals) {
            double totalEpargne = goals.fold(0.0, (sum, g) => sum + g.current);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Savings Card
                  _buildSavingsOverview(context, totalEpargne),

                  const SizedBox(height: 32),

                  // Goals Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Objectifs actifs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => _showAddGoalSheet(context, ref),
                          icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 16),

                  if (goals.isEmpty)
                    _buildEmptyState(context, ref)
                  else
                    // List of savings goals
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: goals.length,
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        final progression = goal.target > 0 
                            ? (goal.current / goal.target * 100).clamp(0, 100) 
                            : 0.0;
                        
                        // Calculate monthly payment needed (deadline in months)
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
                          onTap: () => _showGoalDetailsSheet(context, ref, goal),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.darkBorder),
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
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  goal.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  goal.category,
                                                  style: const TextStyle(
                                                    color: AppColors.darkTextSecondary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: progressColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${progression.toInt()}%',
                                        style: TextStyle(
                                          color: progressColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Progress ring/bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progression / 100,
                                    minHeight: 6,
                                    backgroundColor: AppColors.darkBorder,
                                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ACTUEL',
                                          style: TextStyle(
                                            color: AppColors.darkTextSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          goal.current.toFCFA(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'CIBLE',
                                          style: TextStyle(
                                            color: AppColors.darkTextSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          goal.target.toFCFA(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (goal.current < goal.target) ...[
                                  const SizedBox(height: 16),
                                  Divider(color: AppColors.darkBorder),
                                  const SizedBox(height: 12),
                                  // Necessary Monthly Deposit
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, color: AppColors.secondary, size: 16),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Mensualité recommandée :',
                                          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                                        ),
                                      ),
                                      Text(
                                        '${monthlyNeeded.toFCFA()}/mois',
                                        style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms).slideY(begin: 0.05, end: 0);
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSavingsOverview(BuildContext context, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Épargne totale accumulée',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            total.toFCFA(),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Félicitations ! Vous êtes sur la bonne voie pour sécuriser votre avenir financier.',
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucun projet d'épargne",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Créez votre premier objectif pour commencer à épargner de façon structurée.",
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddGoalSheet(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Créer mon premier objectif', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Vacances':
        return Icons.flight_takeoff_rounded;
      case 'High-Tech':
        return Icons.laptop_mac_rounded;
      case 'Sécurité':
        return Icons.security_rounded;
      case 'Logement':
        return Icons.home_rounded;
      case 'Véhicule':
        return Icons.directions_car_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final currentController = TextEditingController();
    
    String selectedCategory = 'Vacances';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 90));
    final categories = ['Vacances', 'High-Tech', 'Sécurité', 'Logement', 'Véhicule', 'Autre'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nouvel objectif d\'épargne',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Name input
                    const Text('NOM DE L\'OBJECTIF', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ex: Voyage au Kenya',
                        hintStyle: TextStyle(color: AppColors.darkTextSecondary.withOpacity(0.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category input
                    const Text('CATEGORIE', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedCategory = cat;
                              });
                            }
                          },
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.darkSurfaceLight,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Amounts input
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MONTANT CIBLE', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: targetController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: 'Ex: 1500000',
                                  suffixText: 'FCFA',
                                  suffixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('APPORT INITIAL', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: currentController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: 'Ex: 200000',
                                  suffixText: 'FCFA',
                                  suffixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Deadline Selector
                    const Text('DATE LIMITE CIBLE', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final pickerDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.black,
                                  surface: AppColors.darkSurface,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickerDate != null) {
                          setState(() {
                            selectedDate = pickerDate;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy', 'fr_FR').format(selectedDate),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final targetStr = targetController.text.trim();
                          final currentStr = currentController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez entrer un nom d\'objectif')),
                            );
                            return;
                          }

                          final double? target = double.tryParse(targetStr);
                          if (target == null || target <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez entrer un montant cible valide')),
                            );
                            return;
                          }

                          final double current = double.tryParse(currentStr) ?? 0.0;

                          await ref.read(savingsOperationsProvider.notifier).addGoal(
                            name: name,
                            target: target,
                            current: current,
                            deadline: selectedDate,
                            category: selectedCategory,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Objectif "$name" créé avec succès !'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Créer l\'objectif',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditGoalSheet(BuildContext context, WidgetRef ref, SavingsGoalModel goal) {
    final nameController = TextEditingController(text: goal.name);
    final targetController = TextEditingController(text: goal.target.toInt().toString());
    final currentController = TextEditingController(text: goal.current.toInt().toString());
    
    String selectedCategory = goal.category;
    DateTime selectedDate = goal.deadline;
    final categories = ['Vacances', 'High-Tech', 'Sécurité', 'Logement', 'Véhicule', 'Autre'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Modifier l\'objectif',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Name input
                    const Text('NOM DE L\'OBJECTIF', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ex: Voyage au Kenya',
                        hintStyle: TextStyle(color: AppColors.darkTextSecondary.withOpacity(0.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category input
                    const Text('CATEGORIE', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedCategory = cat;
                              });
                            }
                          },
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.darkSurfaceLight,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Amounts input
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MONTANT CIBLE', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: targetController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: 'Ex: 1500000',
                                  suffixText: 'FCFA',
                                  suffixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('APPORT ÉPARGNÉ', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: currentController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: 'Ex: 200000',
                                  suffixText: 'FCFA',
                                  suffixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Deadline Selector
                    const Text('DATE LIMITE CIBLE', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final pickerDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.black,
                                  surface: AppColors.darkSurface,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickerDate != null) {
                          setState(() {
                            selectedDate = pickerDate;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy', 'fr_FR').format(selectedDate),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final targetStr = targetController.text.trim();
                          final currentStr = currentController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez entrer un nom d\'objectif')),
                            );
                            return;
                          }

                          final double? target = double.tryParse(targetStr);
                          if (target == null || target <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez entrer un montant cible valide')),
                            );
                            return;
                          }

                          final double current = double.tryParse(currentStr) ?? 0.0;

                          await ref.read(savingsOperationsProvider.notifier).updateGoal(
                            id: goal.id,
                            name: name,
                            target: target,
                            current: current,
                            deadline: selectedDate,
                            category: selectedCategory,
                            createdAt: goal.createdAt,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Objectif "$name" modifié avec succès !'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Enregistrer les modifications',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showGoalDetailsSheet(BuildContext context, WidgetRef ref, SavingsGoalModel goal) {
    final depositController = TextEditingController();
    final progression = goal.target > 0 
        ? (goal.current / goal.target * 100).clamp(0, 100) 
        : 0.0;
    
    // Calculate monthly payment needed (deadline in months)
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            goal.category,
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditGoalSheet(context, ref, goal);
                          },
                          icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                          tooltip: 'Modifier l\'objectif',
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Progression Overview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ÉPARGNÉ', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          goal.current.toFCFA(),
                          style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('OBJECTIF CIBLE', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          goal.target.toFCFA(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progression / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progression.toInt()}% complété',
                      style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      'Échéance: ${DateFormat('dd MMM yyyy', 'fr_FR').format(goal.deadline)}',
                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                Divider(color: AppColors.darkBorder),
                const SizedBox(height: 16),

                // Info Section
                if (goal.current < goal.target) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.secondary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mensualité Recommandée',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Basé sur ${monthsLeft.toStringAsFixed(1)} mois restants',
                                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${monthlyNeeded.toFCFA()}/m',
                          style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.stars_rounded, color: AppColors.primary, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Objectif Atteint ! Félicitations pour ce superbe succès financier ! 🎉',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Deposit Section
                const Text('FAIRE UN VERSEMENT', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: depositController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'Montant à ajouter',
                          prefixText: '+  ',
                          prefixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          suffixText: 'FCFA',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final amountStr = depositController.text.trim();
                        final double? amount = double.tryParse(amountStr);

                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez entrer un montant valide supérieur à 0')),
                          );
                          return;
                        }

                        await ref.read(savingsOperationsProvider.notifier).makeDeposit(goal.id, amount);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Versement de ${amount.toFCFA()} enregistré avec succès !'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Déposer', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Delete Button
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      // Confirm action dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.darkSurface,
                          title: const Text('Supprimer l\'objectif ?', style: TextStyle(color: Colors.white)),
                          content: Text('Êtes-vous sûr de vouloir supprimer l\'objectif "${goal.name}" ? Cette action est irréversible.', style: const TextStyle(color: AppColors.darkTextSecondary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler', style: TextStyle(color: AppColors.darkTextSecondary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref.read(savingsOperationsProvider.notifier).deleteGoal(goal.id);
                        if (context.mounted) {
                          Navigator.pop(context); // Close details sheet
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Objectif "${goal.name}" supprimé'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    label: const Text('Supprimer cet objectif', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
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
