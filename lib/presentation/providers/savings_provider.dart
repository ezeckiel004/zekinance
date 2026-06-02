import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/savings_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/transaction_model.dart';
import 'auth_provider.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepository();
});

// Stream of savings goals for the logged-in user
final savingsGoalsStreamProvider = StreamProvider<List<SavingsGoalModel>>((ref) {
  final user = ref.watch(authStateProvider);
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(savingsRepositoryProvider).watchSavingsGoals(user.uid);
});

// StateNotifier for performing operations on savings goals
final savingsOperationsProvider = StateNotifierProvider<SavingsOperationsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(savingsRepositoryProvider);
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final user = ref.watch(authStateProvider);
  return SavingsOperationsNotifier(repository, transactionRepository, ref, user?.uid);
});

class SavingsOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final SavingsRepository _repository;
  final TransactionRepository _transactionRepository;
  final Ref? _ref;
  final String? _uid;

  SavingsOperationsNotifier(this._repository, this._transactionRepository, this._ref, this._uid)
      : super(const AsyncData(null));

  Future<void> addGoal({
    required String name,
    required double target,
    required double current,
    required DateTime deadline,
    required String category,
  }) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      final goalId = DateTime.now().millisecondsSinceEpoch.toString();
      final goal = SavingsGoalModel(
        id: goalId,
        name: name,
        target: target,
        current: current,
        deadline: deadline,
        category: category,
        createdAt: DateTime.now(),
      );
      await _repository.addSavingsGoal(_uid, goal);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateGoal({
    required String id,
    required String name,
    required double target,
    required double current,
    required DateTime deadline,
    required String category,
    required DateTime createdAt,
  }) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      final goal = SavingsGoalModel(
        id: id,
        name: name,
        target: target,
        current: current,
        deadline: deadline,
        category: category,
        createdAt: createdAt,
      );
      await _repository.updateSavingsGoal(_uid, goal);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      await _repository.deleteSavingsGoal(_uid, goalId);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> makeDeposit(SavingsGoalModel goal, double amount) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      // 1. Enregistrer le dépôt dans les objectifs d'épargne
      await _repository.addSavingsDeposit(_uid, goal.id, amount);

      // 2. Chercher si une catégorie personnalisée "Épargne" ou "Epargne" existe dans le budget
      String categoryToUse = 'Autres';
      try {
        final activeBudget = _ref?.read(activeBudgetStreamProvider).valueOrNull;
        if (activeBudget != null) {
          final matchedCategory = activeBudget.categories.keys.firstWhere(
            (k) => k.toLowerCase() == 'épargne' || k.toLowerCase() == 'epargne',
            orElse: () => '',
          );
          if (matchedCategory.isNotEmpty) {
            categoryToUse = matchedCategory;
          }
        }
      } catch (_) {}

      // 3. Créer automatiquement une transaction de dépense correspondante
      final txId = FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('transactions')
          .doc()
          .id;

      final transaction = TransactionModel(
        id: txId,
        type: TransactionType.expense,
        amount: amount,
        category: categoryToUse,
        description: 'Épargne : ${goal.name}',
        date: DateTime.now(),
      );

      await _transactionRepository.addTransaction(_uid, transaction);
      
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
