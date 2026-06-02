import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../core/localization/translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  double _monthlyIncome = 250000;
  
  final List<String> _goals = [
    'Épargner pour un projet',
    'Suivre mes dépenses quotidiennes',
    'Créer un budget équilibré',
    'Gérer mes Tontines',
    'Rembourser mes dettes',
    'Parler au Coach IA'
  ];

  final List<String> _goalsEn = [
    'Save for a project',
    'Track my daily expenses',
    'Create a balanced budget',
    'Manage my Tontines',
    'Repay my debts',
    'Talk to the AI Coach'
  ];
  
  final Set<int> _selectedGoals = {};
  Map<String, double> _categoryLimits = {};
  bool _isSaving = false;

  void _initializeCategoryLimits() {
    setState(() {
      _categoryLimits = {
        'Alimentation': _monthlyIncome * 0.20,
        'Loyer & Factures': _monthlyIncome * 0.30,
        'Divertissement': _monthlyIncome * 0.15,
        'Transport': _monthlyIncome * 0.10,
        'Santé': _monthlyIncome * 0.05,
        'Autres': 0.0,
      };
    });
  }

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

  void _nextStep() async {
    final isFr = ref.read(languageProvider) == 'fr';
    if (_currentStep < 2) {
      if (_currentStep == 0) {
        _initializeCategoryLimits();
      }
      setState(() {
        _currentStep++;
      });
    } else {
      if (_isSaving) return;

      final totalAlloue = _categoryLimits.values.fold(0.0, (sum, val) => sum + val);
      if (totalAlloue > _monthlyIncome) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFr 
                ? 'Le total alloué ne doit pas dépasser votre revenu mensuel' 
                : 'Total allocated must not exceed your monthly income'
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isSaving = true);
      try {
        await ref.read(authStateProvider.notifier).updateIncome(_monthlyIncome);
        
        final activeMonth = DateFormat('yyyy-MM').format(DateTime.now());
        final totalBudget = _monthlyIncome;
        
        await ref.read(budgetOperationsProvider.notifier).initializeBudget(
          activeMonth,
          totalBudget,
          _categoryLimits,
        );
        
        if (mounted) {
          context.go('/dashboard');
        }
      } catch (e) {
        if (mounted) {
          final errLabel = isFr ? 'Erreur lors de la configuration' : 'Error during configuration';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$errLabel: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
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
    final isFr = ref.watch(languageProvider) == 'fr';
    
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? AppColors.primary : context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(isFr),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _prevStep,
                      child: Text(
                        isFr ? 'Retour' : 'Back',
                        style: TextStyle(color: context.textSecondary, fontSize: 16),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _nextStep,
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentStep == 2 
                                  ? (isFr ? 'Commencer' : 'Start') 
                                  : (isFr ? 'Continuer' : 'Continue')
                              ),
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

  Widget _buildStepContent(bool isFr) {
    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFr ? 'Quels sont vos objectifs ?' : 'What are your goals?',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFr 
                ? 'Sélectionnez tout ce qui vous intéresse. Cela nous aidera à personnaliser votre expérience.' 
                : 'Select everything that interests you. This will help us customize your experience.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
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
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : context.surfaceColor,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : context.borderColor,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFr ? _goals[index] : _goalsEn[index],
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : context.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                            color: isSelected ? AppColors.primary : context.textSecondary,
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
              isFr ? 'Quel est votre revenu ?' : 'What is your income?',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFr 
                ? 'Saisissez votre revenu mensuel moyen. Nous l’utiliserons pour concevoir votre premier budget.' 
                : 'Enter your average monthly income. We will use it to design your first budget.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
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
                    isFr ? 'par mois' : 'per month',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: context.borderColor,
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
              children: const [
                Text('50 000 FCFA', style: TextStyle(color: AppColors.secondary)),
                Text('2 000 000 FCFA+', style: TextStyle(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 60),
          ],
        );
      case 2:
        final totalAlloue = _categoryLimits.values.fold(0.0, (sum, val) => sum + val);
        final epargne = (_monthlyIncome - totalAlloue).clamp(0.0, double.infinity);
        final exceeds = totalAlloue > _monthlyIncome;

        return SingleChildScrollView(
          key: const ValueKey(2),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFr ? 'Configurez vos limites' : 'Configure your limits',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFr 
                  ? 'Ajustez la part allouée à chaque catégorie. Le reste sera automatiquement placé en épargne.' 
                  : 'Adjust the share allocated to each category. The rest will be automatically saved.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: exceeds ? AppColors.error : context.borderColor,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isFr ? 'Revenu mensuel' : 'Monthly Income', 
                          style: TextStyle(color: context.textSecondary, fontSize: 13)
                        ),
                        Text(
                          _monthlyIncome.toFCFA(), 
                          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isFr ? 'Total alloué' : 'Total Allocated', 
                          style: TextStyle(color: context.textSecondary, fontSize: 13)
                        ),
                        Text(
                          totalAlloue.toFCFA(),
                          style: TextStyle(
                            color: exceeds ? AppColors.error : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24, color: context.borderColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isFr ? 'Épargne mensuelle' : 'Monthly Savings', 
                          style: TextStyle(color: context.textSecondary, fontSize: 13)
                        ),
                        Text(
                          epargne.toFCFA(),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (exceeds) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isFr 
                                ? 'Attention : Le total alloué dépasse votre revenu mensuel !' 
                                : 'Warning: Total allocated exceeds your monthly income!',
                              style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              ..._categoryLimits.keys.map((cat) {
                final currentLimit = _categoryLimits[cat] ?? 0.0;
                final pct = _monthlyIncome > 0 ? (currentLimit / _monthlyIncome * 100).toInt() : 0;
                final catColor = _getCategoryColor(cat);
                final catIcon = _getCategoryIcon(cat);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(catIcon, color: catColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _getCategoryDisplayName(cat, isFr),
                                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currentLimit.toFCFA(),
                                style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                isFr ? '$pct% du revenu' : '$pct% of income',
                                style: TextStyle(color: context.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: catColor,
                          inactiveTrackColor: context.borderColor,
                          thumbColor: catColor,
                          overlayColor: catColor.withOpacity(0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: currentLimit,
                          min: 0.0,
                          max: _monthlyIncome,
                          divisions: 100,
                          onChanged: (val) {
                            setState(() {
                              _categoryLimits[cat] = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
