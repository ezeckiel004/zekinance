import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<BudgetModel?> watchBudget(String uid, String month) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(month)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return BudgetModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<void> setBudget(String uid, BudgetModel budget) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(budget.month)
        .set(budget.toFirestore());
  }

  Future<void> updateCategorySpent(String uid, String month, String category, double spent) async {
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(month);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final budget = BudgetModel.fromFirestore(snapshot);
        final categories = Map<String, CategoryBudget>.from(budget.categories);
        final currentCat = categories[category] ?? CategoryBudget(limit: 0.0);
        categories[category] = currentCat.copyWith(spent: spent);

        transaction.update(docRef, {
          'categories': categories.map((key, value) => MapEntry(key, value.toMap())),
        });
      }
    });
  }

  Future<void> incrementCategorySpent(String uid, String month, String category, double amount) async {
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(month);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final budget = BudgetModel.fromFirestore(snapshot);
        final categories = Map<String, CategoryBudget>.from(budget.categories);
        final currentCat = categories[category] ?? CategoryBudget(limit: 0.0);
        categories[category] = currentCat.copyWith(
          spent: (currentCat.spent + amount).clamp(0.0, double.infinity),
        );

        transaction.update(docRef, {
          'categories': categories.map((key, value) => MapEntry(key, value.toMap())),
        });
      }
    });
  }
}
