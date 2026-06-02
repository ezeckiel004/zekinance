import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/settings_provider.dart';
import '../../../core/localization/translations.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Alimentation';
  bool _isExpense = true;
  
  bool _isListening = false;
  bool _isScanning = false;

  final List<String> _categories = [
    'Alimentation',
    'Loyer & Factures',
    'Divertissement',
    'Transport',
    'Santé',
    'Autres'
  ];

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

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleVoiceSaisie(bool isFr) async {
    setState(() {
      _isListening = true;
    });

    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      setState(() {
        _isListening = false;
        _amountController.text = '5000';
        _descController.text = isFr ? 'Courses au marché local (Saisie vocale)' : 'Groceries at local market (Voice entry)';
        _selectedCategory = 'Alimentation';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFr 
              ? 'Saisie vocale décodée : "5 000 FCFA pour Alimentation"' 
              : 'Voice entry decoded: "5 000 FCFA for Food & Groceries"'
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleScanOcr(bool isFr) async {
    setState(() {
      _isScanning = true;
    });

    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _amountController.text = '18500';
        _descController.text = isFr ? 'Supermarché Carrefour (Scan OCR)' : 'Carrefour Supermarket (OCR Scan)';
        _selectedCategory = 'Alimentation';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFr 
              ? 'Reçu analysé avec succès : 18 500 FCFA chez Carrefour !' 
              : 'Receipt successfully analyzed: 18 500 FCFA at Carrefour!'
          ),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  void _saveTransaction(bool isFr) async {
    final user = ref.read(authStateProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFr 
              ? "Vous devez être connecté pour ajouter une transaction" 
              : "You must be logged in to add a transaction"
          )
        ),
      );
      return;
    }

    final amtStr = _amountController.text.trim();
    final desc = _descController.text.trim();

    if (amtStr.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFr 
              ? 'Veuillez remplir tous les champs obligatoires' 
              : 'Please fill in all required fields'
          )
        ),
      );
      return;
    }

    final double? amt = double.tryParse(amtStr);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFr 
              ? 'Veuillez entrer un montant valide' 
              : 'Please enter a valid amount'
          )
        ),
      );
      return;
    }

    final String txId = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc()
        .id;

    final activeBudget = ref.read(activeBudgetStreamProvider).valueOrNull;
    final List<String> budgetCategories = activeBudget != null && activeBudget.categories.isNotEmpty
        ? activeBudget.categories.keys.toList()
        : _categories;
    final String resolvedCategory = budgetCategories.contains(_selectedCategory)
        ? _selectedCategory
        : (budgetCategories.isNotEmpty ? budgetCategories.first : 'Alimentation');

    final transaction = TransactionModel(
      id: txId,
      type: _isExpense ? TransactionType.expense : TransactionType.income,
      amount: amt,
      category: resolvedCategory,
      description: desc,
      date: DateTime.now(),
    );

    try {
      await ref.read(transactionOperationsProvider.notifier).add(transaction);

      if (_isExpense) {
        final activeMonth = DateFormat('yyyy-MM').format(transaction.date);
        await ref.read(budgetRepositoryProvider).incrementCategorySpent(
          user.uid,
          activeMonth,
          resolvedCategory,
          amt,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFr 
                ? 'Transaction ajoutée avec succès !' 
                : 'Transaction added successfully!'
            ), 
            backgroundColor: AppColors.primary
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);
    final activeBudget = activeBudgetAsync.valueOrNull;
    final isFr = ref.watch(languageProvider) == 'fr';
    
    final List<String> budgetCategories = activeBudget != null && activeBudget.categories.isNotEmpty
        ? activeBudget.categories.keys.toList()
        : _categories;

    final String displayCategory = budgetCategories.contains(_selectedCategory)
        ? _selectedCategory
        : (budgetCategories.isNotEmpty ? budgetCategories.first : 'Alimentation');

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          context.tr(ref, 'add_tx_title'),
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flow selector (Expense vs Income)
              _buildTypeSelector(isFr),

              const SizedBox(height: 28),

              // Interactive Assist Actions (OCR / Voice)
              _buildSmartAssistSection(isFr),

              const SizedBox(height: 28),

              // Amount Input
              Text(
                context.tr(ref, 'add_tx_amount').toUpperCase() + ' (FCFA)', 
                style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixIcon: const Icon(Icons.monetization_on_outlined, size: 28, color: AppColors.primary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                ),
              ),

              const SizedBox(height: 20),

              // Description Input
              Text(
                context.tr(ref, 'add_tx_description').toUpperCase(), 
                style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                style: TextStyle(color: context.textPrimary),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: context.tr(ref, 'add_tx_description_hint'),
                  hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.description_outlined, color: context.textSecondary),
                ),
              ),

              const SizedBox(height: 20),

              // Category Selector
              Text(
                context.tr(ref, 'add_tx_category').toUpperCase(), 
                style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.surfaceColorLight.withOpacity(0.5),
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: displayCategory,
                    dropdownColor: context.surfaceColor,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.textSecondary),
                    items: budgetCategories.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          _getCategoryDisplayName(cat, isFr), 
                          style: TextStyle(color: context.textPrimary)
                        ),
                      );
                    }).toList(),
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveTransaction(isFr),
                  child: Text(context.tr(ref, 'add_tx_btn')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isFr) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpense = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isExpense ? AppColors.error : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    isFr ? 'Dépense' : 'Expense',
                    style: TextStyle(
                      color: _isExpense ? Colors.white : context.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpense = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isExpense ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    isFr ? 'Revenu' : 'Income',
                    style: TextStyle(
                      color: !_isExpense ? Colors.black : context.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAssistSection(bool isFr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFr ? 'ASSISTANCE INTELLIGENTE (MOCK)' : 'SMART ASSISTANT (MOCK)',
            style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isScanning ? null : () => _handleScanOcr(isFr),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _isScanning 
                          ? const SizedBox(
                              height: 24, 
                              width: 24, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)
                            )
                          : const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accent, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          _isScanning 
                            ? (isFr ? 'Scan en cours...' : 'Scanning...')
                            : (isFr ? 'Scanner Reçu' : 'Scan Receipt'),
                          style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _isListening ? null : () => _handleVoiceSaisie(isFr),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.08),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _isListening 
                          ? const SizedBox(
                              height: 24, 
                              width: 24, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary)
                            )
                          : const Icon(Icons.mic_rounded, color: AppColors.secondary, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          _isListening 
                            ? (isFr ? 'Écoute active...' : 'Listening...')
                            : (isFr ? 'Saisie Vocale' : 'Voice Entry'),
                          style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isListening) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                isFr 
                  ? '"Parlez maintenant... ex: J\'ai dépensé 5000 francs pour des courses"'
                  : '"Speak now... e.g. I spent 5000 francs for groceries"',
                style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontStyle: FontStyle.italic),
              ).animate().fadeIn().shimmer(duration: 1000.ms),
            ),
          ],
          if (_isScanning) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                isFr 
                  ? '"Analyse du ticket de caisse en cours..."'
                  : '"Analyzing receipt checkout in progress..."',
                style: const TextStyle(color: AppColors.accent, fontSize: 11, fontStyle: FontStyle.italic),
              ).animate().fadeIn().shimmer(duration: 1000.ms),
            ),
          ],
        ],
      ),
    );
  }
}
