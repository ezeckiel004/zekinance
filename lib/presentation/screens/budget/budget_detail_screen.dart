import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';

class BudgetDetailScreen extends StatelessWidget {
  final String categoryId;

  const BudgetDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    // Premium custom data according to the category selected
    double limit = 80000.0;
    double spent = 74000.0;
    Color catColor = AppColors.secondary;
    IconData catIcon = Icons.restaurant_rounded;
    String methodType = 'Besoins stricts (50%)';

    if (categoryId == 'Loyer & Factures') {
      limit = 90000.0;
      spent = 45000.0;
      catColor = AppColors.info;
      catIcon = Icons.home_rounded;
      methodType = 'Besoins stricts (50%)';
    } else if (categoryId == 'Divertissement') {
      limit = 30000.0;
      spent = 27500.0;
      catColor = AppColors.error;
      catIcon = Icons.celebration_rounded;
      methodType = 'Envies & Plaisirs (30%)';
    } else if (categoryId == 'Transport') {
      limit = 50000.0;
      spent = 18500.0;
      catColor = AppColors.accent;
      catIcon = Icons.directions_car_rounded;
      methodType = 'Besoins stricts (50%)';
    }

    final remaining = (limit - spent).clamp(0.0, double.infinity);
    final pctSpent = (spent / limit * 100).clamp(0.0, 100.0);
    
    // Beautiful mock list of items in this category
    final items = [
      _MockExpenseItem(name: 'Achat de fruits au marché', amount: 4500.0, date: 'Aujourd\'hui à 11h43'),
      _MockExpenseItem(name: 'Supermarché Siga', amount: 15500.0, date: 'Hier à 18h12'),
      _MockExpenseItem(name: 'Épicerie du quartier', amount: 54000.0, date: '21 Mai à 09h30'),
    ];

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Radial Status Indicator
              _buildLargeRadialIndicator(context, categoryId, limit, spent, remaining, pctSpent, catColor, catIcon, methodType),

              const SizedBox(height: 32),

              // Actions banner
              _buildCategoryActions(context),

              const SizedBox(height: 32),

              // Recent Transactions for this category
              Text(
                'Dépenses de ce mois',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
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
                                item.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.date,
                                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '-' + item.amount.toFCFA(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
              // Beautiful thick double ring progress circle
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
                children: [
                  Icon(icon, color: color, size: 30),
                  const SizedBox(height: 6),
                  Text(
                    '${pct.toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  Text(
                    'utilisé',
                    style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 28),
          Divider(color: AppColors.darkBorder),
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

  Widget _buildCategoryActions(BuildContext context) {
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
            onPressed: () {},
            icon: const Icon(Icons.edit_rounded, color: AppColors.darkTextPrimary),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }
}

class _MockExpenseItem {
  final String name;
  final double amount;
  final String date;
  _MockExpenseItem({required this.name, required this.amount, required this.date});
}
