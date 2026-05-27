import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  double _monthlyIncome = 250000; // 250k FCFA as standard default
  
  final List<String> _goals = [
    'Épargner pour un projet',
    'Suivre mes dépenses quotidiennes',
    'Créer un budget équilibré',
    'Gérer mes Tontines',
    'Rembourser mes dettes',
    'Parler au Coach IA'
  ];
  
  final Set<int> _selectedGoals = {};

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      context.go('/dashboard');
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Progress Indicator
              Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? AppColors.primary : AppColors.darkBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // Dynamic content based on current step
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(),
                ),
              ),

              // Bottom Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _prevStep,
                      child: const Text(
                        'Retour',
                        style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 16),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _nextStep,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentStep == 2 ? 'Commencer' : 'Continuer'),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quels sont vos objectifs ?',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez tout ce qui vous intéresse. Cela nous aidera à personnaliser votre expérience.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedGoals.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedGoals.remove(index);
                        } else {
                          _selectedGoals.add(index);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.darkSurface,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.darkBorder,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _goals[index],
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.darkTextPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                            color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quel est votre revenu ?',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saisissez votre revenu mensuel moyen. Nous l’utiliserons pour concevoir votre premier budget.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Text(
                    _monthlyIncome.toFCFA(),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'par mois',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.darkBorder,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.2),
                trackHeight: 6,
              ),
              child: Slider(
                value: _monthlyIncome,
                min: 50000,
                max: 2000000,
                divisions: 39,
                onChanged: (val) {
                  setState(() {
                    _monthlyIncome = val;
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('50 000 FCFA', style: TextStyle(color: AppColors.darkTextSecondary)),
                Text('2 000 000 FCFA+', style: TextStyle(color: AppColors.darkTextSecondary)),
              ],
            ),
            const SizedBox(height: 60),
          ],
        );
      case 2:
        final besoins = _monthlyIncome * 0.50;
        final envies = _monthlyIncome * 0.30;
        final epargne = _monthlyIncome * 0.20;

        return SingleChildScrollView(
          key: const ValueKey(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre plan 50/30/20',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Voici comment nous vous conseillons de répartir votre budget pour maximiser votre épargne.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Needs Card
              _buildAllocationCard(
                title: 'Besoins indispensables (50%)',
                subtitle: 'Loyer, factures, nourriture, santé',
                amount: besoins,
                color: AppColors.info,
                icon: Icons.home_repair_service_outlined,
              ),
              
              const SizedBox(height: 16),
              
              // Wants Card
              _buildAllocationCard(
                title: 'Envies & Plaisirs (30%)',
                subtitle: 'Sorties, restaurants, shopping, loisirs',
                amount: envies,
                color: AppColors.secondary,
                icon: Icons.celebration_outlined,
              ),
              
              const SizedBox(height: 16),
              
              // Savings Card
              _buildAllocationCard(
                title: 'Épargne & Dettes (20%)',
                subtitle: 'Épargne projet, investissement, secours',
                amount: epargne,
                color: AppColors.primary,
                icon: Icons.savings_outlined,
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAllocationCard({
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border.all(color: AppColors.darkBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount.toFCFA(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }
}
