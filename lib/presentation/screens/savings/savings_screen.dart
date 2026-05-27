import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = [
      _MockSavingsGoal(name: 'Voyage au Kenya', target: 1500000.0, current: 350000.0, deadline: DateTime.now().add(const Duration(days: 180)), category: 'Vacances'),
      _MockSavingsGoal(name: 'Achat MacBook Pro', target: 800000.0, current: 640000.0, deadline: DateTime.now().add(const Duration(days: 60)), category: 'High-Tech'),
      _MockSavingsGoal(name: 'Fonds d\'Urgence', target: 1000000.0, current: 250000.0, deadline: DateTime.now().add(const Duration(days: 365)), category: 'Sécurité'),
    ];

    double totalEpargne = 0;
    for (var g in goals) {
      totalEpargne += g.current;
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Mon Épargne'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),

              // List of savings goals
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final progression = (goal.current / goal.target * 100).clamp(0, 100);
                  
                  // Calculate monthly payment needed (deadline in months)
                  final monthsLeft = (goal.deadline.difference(DateTime.now()).inDays / 30).clamp(1.0, 120.0);
                  final monthlyNeeded = (goal.target - goal.current) / monthsLeft;

                  return Container(
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal.category,
                                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${progression.toInt()}%',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
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
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ACTUEL', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(goal.current.toFCFA(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('CIBLE', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(goal.target.toFCFA(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: AppColors.darkBorder),
                        const SizedBox(height: 12),
                        // Necessary Monthly Deposit
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppColors.secondary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mensualité recommandée :',
                                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                              ),
                            ),
                            Text(
                              monthlyNeeded.toFCFA() + '/mois',
                              style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms).slideY(begin: 0.05, end: 0);
                },
              ),
            ],
          ),
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
}

class _MockSavingsGoal {
  final String name;
  final double target;
  final double current;
  final DateTime deadline;
  final String category;
  _MockSavingsGoal({required this.name, required this.target, required this.current, required this.deadline, required this.category});
}
