import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoalModel {
  final String id;
  final String name;
  final double target;
  final double current;
  final DateTime deadline;
  final String category;
  final DateTime createdAt;

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.target,
    required this.current,
    required this.deadline,
    required this.category,
    required this.createdAt,
  });

  factory SavingsGoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SavingsGoalModel(
      id: doc.id,
      name: data['name'] ?? '',
      target: (data['target'] as num?)?.toDouble() ?? 0.0,
      current: (data['current'] as num?)?.toDouble() ?? 0.0,
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category'] ?? 'Autre',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'target': target,
      'current': current,
      'deadline': Timestamp.fromDate(deadline),
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SavingsGoalModel copyWith({
    String? id,
    String? name,
    double? target,
    double? current,
    DateTime? deadline,
    String? category,
    DateTime? createdAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      target: target ?? this.target,
      current: current ?? this.current,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
