import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/savings_repository.dart';
import '../../data/models/savings_goal_model.dart';
import 'auth_provider.dart';

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
  final user = ref.watch(authStateProvider);
  return SavingsOperationsNotifier(repository, user?.uid);
});

class SavingsOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final SavingsRepository _repository;
  final String? _uid;

  SavingsOperationsNotifier(this._repository, this._uid) : super(const AsyncData(null));

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

  Future<void> makeDeposit(String goalId, double amount) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      await _repository.addSavingsDeposit(_uid, goalId, amount);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
