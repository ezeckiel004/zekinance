import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
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

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleVoiceSaisie() async {
    setState(() {
      _isListening = true;
    });

    // Mock speech to text analysis
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      setState(() {
        _isListening = false;
        _amountController.text = '5000';
        _descController.text = 'Courses au marché local (Saisie vocale)';
        _selectedCategory = 'Alimentation';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisie vocale décodée : "5 000 FCFA pour Alimentation"'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleScanOcr() async {
    setState(() {
      _isScanning = true;
    });

    // Mock OCR Receipt scanning analysis
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _amountController.text = '18500';
        _descController.text = 'Supermarché Carrefour (Scan OCR)';
        _selectedCategory = 'Alimentation';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reçu analysé avec succès : 18 500 FCFA chez Carrefour !'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  void _saveTransaction() {
    final amtStr = _amountController.text.trim();
    final desc = _descController.text.trim();

    if (amtStr.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    final double? amt = double.tryParse(amtStr);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    // Return to flow screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction ajoutée avec succès !'), backgroundColor: AppColors.primary),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Nouvelle Transaction'),
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
              // Flow selector (Expense vs Income)
              _buildTypeSelector(),

              const SizedBox(height: 28),

              // Interactive Assist Actions (OCR / Voice)
              _buildSmartAssistSection(),

              const SizedBox(height: 28),

              // Amount Input (Large visual style)
              const Text('MONTANT (FCFA)', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(Icons.monetization_on_outlined, size: 28, color: AppColors.primary),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                ),
              ),

              const SizedBox(height: 20),

              // Description Input
              const Text('DESCRIPTION', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Achat de fruits, Facture électricité...',
                  prefixIcon: Icon(Icons.description_outlined, color: AppColors.darkTextSecondary),
                ),
              ),

              const SizedBox(height: 20),

              // Category Selector
              const Text('CATÉGORIE', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceLight.withOpacity(0.5),
                  border: Border.all(color: AppColors.darkBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    dropdownColor: AppColors.darkSurface,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkTextSecondary),
                    items: _categories.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat, style: const TextStyle(color: Colors.white)),
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
                  onPressed: _saveTransaction,
                  child: const Text('Enregistrer la transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.darkBorder),
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
                    'Dépense',
                    style: TextStyle(
                      color: _isExpense ? Colors.white : AppColors.darkTextSecondary,
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
                    'Revenu',
                    style: TextStyle(
                      color: !_isExpense ? Colors.black : AppColors.darkTextSecondary,
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

  Widget _buildSmartAssistSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ASSISTANCE INTELLIGENTE (MOCK)',
            style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // OCR scanning trigger
              Expanded(
                child: GestureDetector(
                  onTap: _isScanning ? null : _handleScanOcr,
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
                          _isScanning ? 'Scan en cours...' : 'Scanner Reçu',
                          style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Voice input trigger
              Expanded(
                child: GestureDetector(
                  onTap: _isListening ? null : _handleVoiceSaisie,
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
                          _isListening ? 'Écoute active...' : 'Saisie Vocale',
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
              child: const Text(
                '"Parlez maintenant... ex: J\'ai dépensé 5000 francs pour des courses"',
                style: TextStyle(color: AppColors.secondary, fontSize: 11, fontStyle: FontStyle.italic),
              ).animate().fadeIn().shimmer(duration: 1000.ms),
            ),
          ],
          if (_isScanning) ...[
            const SizedBox(height: 12),
            Center(
              child: const Text(
                '"Analyse du ticket de caisse en cours..."',
                style: TextStyle(color: AppColors.accent, fontSize: 11, fontStyle: FontStyle.italic),
              ).animate().fadeIn().shimmer(duration: 1000.ms),
            ),
          ],
        ],
      ),
    );
  }
}
