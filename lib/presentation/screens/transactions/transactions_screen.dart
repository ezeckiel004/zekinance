import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _activeFilter = 0; // 0 = Tout, 1 = Dépenses, 2 = Revenus
  String _searchQuery = '';

  final List<_MockTransaction> _allTransactions = [
    _MockTransaction(title: 'Supermarché Siga', amount: 15500, category: 'Alimentation', date: 'Aujourd\'hui à 14h30', isExpense: true),
    _MockTransaction(title: 'Salaire Mensuel', amount: 350000, category: 'Revenus', date: 'Hier à 08h00', isExpense: false),
    _MockTransaction(title: 'Abonnement Netflix', amount: 6500, category: 'Divertissement', date: '25 Mai 2026', isExpense: true),
    _MockTransaction(title: 'Achat fruits au marché', amount: 4500, category: 'Alimentation', date: '23 Mai 2026', isExpense: true),
    _MockTransaction(title: 'Remboursement Tontine', amount: 50000, category: 'Tontines', date: '20 Mai 2026', isExpense: false),
    _MockTransaction(title: 'Course de taxia Yango', amount: 2500, category: 'Transport', date: '18 Mai 2026', isExpense: true),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final filteredTxs = _allTransactions.where((tx) {
      final matchesSearch = tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;
      
      if (_activeFilter == 1) return tx.isExpense;
      if (_activeFilter == 2) return !tx.isExpense;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Mes Flux Financiers'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un commerce, une catégorie...',
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.darkTextSecondary),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Custom Capsule Filters
                  Row(
                    children: [
                      _buildFilterChip(0, 'Tout'),
                      const SizedBox(width: 8),
                      _buildFilterChip(1, 'Dépenses'),
                      const SizedBox(width: 8),
                      _buildFilterChip(2, 'Revenus'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Transactions list
            Expanded(
              child: filteredTxs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.darkTextSecondary),
                        SizedBox(height: 16),
                        Text(
                          'Aucune transaction trouvée',
                          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredTxs.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTxs[index];
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
                                color: (tx.isExpense ? AppColors.error : AppColors.primary).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tx.isExpense ? Icons.shopping_bag_outlined : Icons.monetization_on_outlined,
                                color: tx.isExpense ? AppColors.error : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${tx.category} • ${tx.date}',
                                    style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              (tx.isExpense ? '-' : '+') + tx.amount.toDouble().toFCFA(),
                              style: TextStyle(
                                color: tx.isExpense ? Colors.white : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int filterIndex, String label) {
    final isActive = _activeFilter == filterIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeFilter = filterIndex;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.darkSurface,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.darkBorder,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : AppColors.darkTextPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MockTransaction {
  final String title;
  final double amount;
  final String category;
  final String date;
  final bool isExpense;
  _MockTransaction({required this.title, required this.amount, required this.category, required this.date, required this.isExpense});
}
