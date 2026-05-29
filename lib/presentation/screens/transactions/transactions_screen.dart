import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int _activeFilter = 0; // 0 = Tout, 1 = Dépenses, 2 = Revenus
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

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
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.white))),
          data: (transactions) {
            final filteredTxs = transactions.where((tx) {
              final matchesSearch = tx.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  tx.category.toLowerCase().contains(_searchQuery.toLowerCase());
              
              if (!matchesSearch) return false;
              
              if (_activeFilter == 1) return tx.type == TransactionType.expense;
              if (_activeFilter == 2) return tx.type == TransactionType.income;
              return true;
            }).toList();

            return Column(
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
                          final isExpense = tx.type == TransactionType.expense;
                          final formattedDate = DateFormat('dd MMMM yyyy à HH:mm').format(tx.date);

                          return Dismissible(
                            key: Key(tx.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.darkSurface,
                                  title: const Text('Supprimer la transaction ?', style: TextStyle(color: Colors.white)),
                                  content: const Text(
                                    'Voulez-vous vraiment supprimer cette transaction ? Cette action recalculera vos budgets.',
                                    style: TextStyle(color: AppColors.darkTextSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Annuler', style: TextStyle(color: AppColors.darkTextSecondary)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              // Perform deletion in Firestore
                              await ref.read(transactionOperationsProvider.notifier).delete(tx.id);
                              
                              // Recalculate and decrement budget if it was an expense
                              if (isExpense) {
                                final activeMonth = DateFormat('yyyy-MM').format(tx.date);
                                await ref.read(budgetRepositoryProvider).incrementCategorySpent(
                                  ref.read(authStateProvider)!.uid,
                                  activeMonth,
                                  tx.category,
                                  -tx.amount,
                                );
                              }

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaction supprimée avec succès')),
                                );
                              }
                            },
                            child: Container(
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
                                      color: (isExpense ? AppColors.error : AppColors.primary).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isExpense ? Icons.shopping_bag_outlined : Icons.monetization_on_outlined,
                                      color: isExpense ? AppColors.error : AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.description,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${tx.category} • $formattedDate',
                                          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    (isExpense ? '-' : '+') + tx.amount.toFCFA(),
                                    style: TextStyle(
                                      color: isExpense ? Colors.white : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
                        },
                      ),
                ),
              ],
            );
          },
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
