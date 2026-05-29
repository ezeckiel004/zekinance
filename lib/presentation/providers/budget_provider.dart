import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/models/budget_model.dart';
import 'auth_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

// Stream of budget for a given month (format: 'YYYY-MM')
final budgetStreamProvider = StreamProvider.family<BudgetModel?, String>((ref, month) {
  final user = ref.watch(authStateProvider);
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(budgetRepositoryProvider).watchBudget(user.uid, month);
});

// Current active month provider (default: current calendar month)
final activeMonthProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

// Stream of the active month's budget
final activeBudgetStreamProvider = StreamProvider<BudgetModel?>((ref) {
  final activeMonth = ref.watch(activeMonthProvider);
  final user = ref.watch(authStateProvider);
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(budgetRepositoryProvider).watchBudget(user.uid, activeMonth);
});

// StateNotifier to perform budget management operations
final budgetOperationsProvider = StateNotifierProvider<BudgetOperationsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  final user = ref.watch(authStateProvider);
  return BudgetOperationsNotifier(repository, user?.uid);
});

class BudgetOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final BudgetRepository _repository;
  final String? _uid;

  BudgetOperationsNotifier(this._repository, this._uid) : super(const AsyncData(null));

  Future<void> initializeBudget(String month, double totalBudget, Map<String, double> categoryLimits) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      final categories = categoryLimits.map((key, value) {
        return MapEntry(key, CategoryBudget(limit: value, spent: 0.0));
      });
      final budget = BudgetModel(
        month: month,
        categories: categories,
        totalBudget: totalBudget,
      );
      await _repository.setBudget(_uid, budget);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateCategoryLimit(BudgetModel currentBudget, String category, double newLimit) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      final categories = Map<String, CategoryBudget>.from(currentBudget.categories);
      final currentCat = categories[category] ?? CategoryBudget(limit: 0.0);
      categories[category] = currentCat.copyWith(limit: newLimit);

      // Re-calculate total budget
      double newTotal = categories.values.fold(0.0, (sum, cat) => sum + cat.limit);

      final updatedBudget = currentBudget.copyWith(
        categories: categories,
        totalBudget: newTotal,
      );

      await _repository.setBudget(_uid, updatedBudget);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
