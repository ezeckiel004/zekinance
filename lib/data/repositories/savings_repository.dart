import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/savings_goal_model.dart';

class SavingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<SavingsGoalModel>> watchSavingsGoals(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savingsGoals')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SavingsGoalModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addSavingsGoal(String uid, SavingsGoalModel goal) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savingsGoals')
        .doc(goal.id)
        .set(goal.toFirestore());
  }

  Future<void> updateSavingsGoal(String uid, SavingsGoalModel goal) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savingsGoals')
        .doc(goal.id)
        .update(goal.toFirestore());
  }

  Future<void> deleteSavingsGoal(String uid, String goalId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savingsGoals')
        .doc(goalId)
        .delete();
  }

  Future<void> addSavingsDeposit(String uid, String goalId, double amount) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savingsGoals')
        .doc(goalId)
        .update({
      'current': FieldValue.increment(amount),
    });
  }
}
