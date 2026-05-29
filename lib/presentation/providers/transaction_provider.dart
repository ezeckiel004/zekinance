import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/models/transaction_model.dart';
import 'auth_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// Stream of transactions for the authenticated user
final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(authStateProvider);
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(transactionRepositoryProvider).watchTransactions(user.uid);
});

// StateNotifier to handle adding/updating/deleting transactions
final transactionOperationsProvider = StateNotifierProvider<TransactionOperationsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final user = ref.watch(authStateProvider);
  return TransactionOperationsNotifier(repository, user?.uid);
});

class TransactionOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repository;
  final String? _uid;

  TransactionOperationsNotifier(this._repository, this._uid) : super(const AsyncData(null));

  Future<void> add(TransactionModel transaction) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      await _repository.addTransaction(_uid, transaction);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> update(TransactionModel transaction) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      await _repository.updateTransaction(_uid, transaction);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> delete(String transactionId) async {
    if (_uid == null) return;
    state = const AsyncLoading();
    try {
      await _repository.deleteTransaction(_uid, transactionId);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
