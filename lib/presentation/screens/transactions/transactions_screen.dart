import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/double_ext.dart';
import '../../../core/localization/translations.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/settings_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int _activeFilter = 0; // 0 = Tout, 1 = Dépenses, 2 = Revenus
  String _searchQuery = '';

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
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final isFr = ref.watch(languageProvider) == 'fr';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          isFr ? 'Mes Flux Financiers' : 'My Financial Flows',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, stack) => Center(child: Text('${context.tr(ref, 'error')}: $err', style: TextStyle(color: context.textPrimary))),
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
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: isFr 
                              ? 'Rechercher un commerce, une catégorie...' 
                              : 'Search commercial, category...',
                          hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.search_rounded, color: context.textSecondary),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Custom Capsule Filters
                      Row(
                        children: [
                          _buildFilterChip(0, isFr ? 'Tout' : 'All'),
                          const SizedBox(width: 8),
                          _buildFilterChip(1, isFr ? 'Dépenses' : 'Expenses'),
                          const SizedBox(width: 8),
                          _buildFilterChip(2, isFr ? 'Revenus' : 'Incomes'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Transactions list
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: context.surfaceColor,
                    onRefresh: () async {
                      ref.invalidate(transactionsStreamProvider);
                      await Future.delayed(const Duration(milliseconds: 800));
                    },
                    child: filteredTxs.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.hourglass_empty_rounded, size: 48, color: context.textSecondary),
                                  const SizedBox(height: 16),
                                  Text(
                                    context.tr(ref, 'tx_no_results'),
                                    style: TextStyle(color: context.textSecondary, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: filteredTxs.length,
                          itemBuilder: (context, index) {
                            final tx = filteredTxs[index];
                            final isExpense = tx.type == TransactionType.expense;
                            final formattedDate = isFr
                                ? DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(tx.date)
                                : DateFormat('dd MMMM yyyy at HH:mm', 'en_US').format(tx.date);

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
                                final textStyle = TextStyle(color: context.textPrimary);
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: context.surfaceColor,
                                    title: Text(
                                      isFr ? 'Supprimer la transaction ?' : 'Delete transaction?', 
                                      style: textStyle
                                    ),
                                    content: Text(
                                      isFr 
                                        ? 'Voulez-vous vraiment supprimer cette transaction ? Cette action recalculera vos budgets.' 
                                        : 'Do you really want to delete this transaction? This action will recalculate your budgets.',
                                      style: TextStyle(color: context.textSecondary),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: Text(context.tr(ref, 'cancel'), style: TextStyle(color: context.textSecondary)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: Text(context.tr(ref, 'delete'), style: const TextStyle(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) async {
                                try {
                                  await ref.read(transactionOperationsProvider.notifier).delete(tx.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isFr ? 'Transaction supprimée !' : 'Transaction deleted!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${context.tr(ref, 'error')}: $e')),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: context.surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isExpense 
                                          ? AppColors.error.withOpacity(0.12)
                                          : AppColors.primary.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isExpense ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
                                        color: isExpense ? AppColors.error : AppColors.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.description,
                                            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_getCategoryDisplayName(tx.category, isFr)} • $formattedDate',
                                            style: TextStyle(color: context.textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      (isExpense ? '-' : '+') + tx.amount.toFCFA(),
                                      style: TextStyle(
                                        color: isExpense ? context.textPrimary : AppColors.primary,
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
            color: isActive ? AppColors.primary : context.surfaceColor,
            border: Border.all(
              color: isActive ? AppColors.primary : context.borderColor,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : context.textPrimary,
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
