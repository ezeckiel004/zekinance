import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryBudget {
  final double limit;
  final double spent;

  CategoryBudget({
    required this.limit,
    this.spent = 0.0,
  });

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      limit: (map['limit'] as num?)?.toDouble() ?? 0.0,
      spent: (map['spent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'limit': limit,
      'spent': spent,
    };
  }

  CategoryBudget copyWith({
    double? limit,
    double? spent,
  }) {
    return CategoryBudget(
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
    );
  }

  double get percentage => limit > 0 ? (spent / limit * 100).clamp(0, 100) : 0.0;
  double get remaining => (limit - spent).clamp(0, double.infinity);
  bool get isAlert => percentage >= 70.0;
  bool get isCritical => percentage >= 90.0;
}

class BudgetModel {
  final String month; // Format: 'YYYY-MM'
  final Map<String, CategoryBudget> categories;
  final double totalBudget;

  BudgetModel({
    required this.month,
    required this.categories,
    required this.totalBudget,
  });

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final categoryMaps = data['categories'] as Map<String, dynamic>? ?? {};
    final categories = categoryMaps.map((key, value) {
      return MapEntry(key, CategoryBudget.fromMap(Map<String, dynamic>.from(value)));
    });

    return BudgetModel(
      month: doc.id,
      categories: categories,
      totalBudget: (data['totalBudget'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalBudget': totalBudget,
      'categories': categories.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  BudgetModel copyWith({
    String? month,
    Map<String, CategoryBudget>? categories,
    double? totalBudget,
  }) {
    return BudgetModel(
      month: month ?? this.month,
      categories: categories ?? this.categories,
      totalBudget: totalBudget ?? this.totalBudget,
    );
  }
}
