import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium mock budget data based on 250k standard income
    const double totalBudget = 250000.0;
    const double spentTotal = 145000.0;
    const double remainingTotal = totalBudget - spentTotal;

    final categories = [
      _MockCategoryBudget(name: 'Alimentation', limit: 80000, spent: 74000, color: AppColors.secondary, icon: Icons.restaurant_rounded),
      _MockCategoryBudget(name: 'Loyer & Factures', limit: 90000, spent: 45000, color: AppColors.info, icon: Icons.home_rounded),
      _MockCategoryBudget(name: 'Divertissement', limit: 30000, spent: 27500, color: AppColors.error, icon: Icons.celebration_rounded), // Critique! 91.6%
      _MockCategoryBudget(name: 'Transport', limit: 50000, spent: 18500, color: AppColors.accent, icon: Icons.directions_car_rounded),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Mes Budgets'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Circular overview
              _buildOverviewCard(context, totalBudget, spentTotal, remainingTotal),

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
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final pct = (cat.spent / cat.limit * 100).clamp(0, 100);
                  
                  // Alerts based on category budget rule
                  final isCritique = pct >= 90;
                  final isAlerte = pct >= 70;
                  
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
                      context.push('/budget/${cat.name}');
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
                                  color: cat.color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(cat.icon, color: cat.color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(alertIcon, color: statusColor, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          alertMessage,
                                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${pct.toInt()}%',
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Restant : ${(cat.limit - cat.spent).toDouble().toFCFA()}',
                                    style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Custom Modern Progress Line
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
                              Text(
                                'Dépensé : ${cat.spent.toDouble().toFCFA()}',
                                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                              ),
                              Text(
                                'Limite : ${cat.limit.toDouble().toFCFA()}',
                                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
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
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, double total, double spent, double remaining) {
    final pctSpent = (spent / total * 100).toInt();

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dépenses totales', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(spent.toFCFA(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Budget Global : ${total.toFCFA()}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stack containing dynamic horizontal progress block
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
              Text(
                '$pctSpent% utilisé ce mois',
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
              ),
              Text(
                'Restant : ${remaining.toFCFA()}',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
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
            children: const [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Méthode budgétaire active',
                style: TextStyle(color: AppColors.secondary, fontSize: 14, fontWeight: FontWeight.bold),
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
}

class _MockCategoryBudget {
  final String name;
  final int limit;
  final int spent;
  final Color color;
  final IconData icon;
  _MockCategoryBudget({required this.name, required this.limit, required this.spent, required this.color, required this.icon});
}
