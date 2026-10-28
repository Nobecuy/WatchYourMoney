import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'goal_model.g.dart';

/// Status of a goal
enum GoalStatus {
  active,
  completed,
  archived,
}

/// Category for goals
enum GoalCategory {
  savings,
  investment,
  emergency,
  travel,
  education,
  purchase,
  other,
}

@HiveType(typeId: 15)
class GoalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final double targetAmount;

  @HiveField(4)
  double currentAmount;

  @HiveField(5)
  final String category; // Store as string for flexibility

  @HiveField(6)
  final DateTime targetDate;

  @HiveField(7)
  final double initialAmount;

  @HiveField(8)
  final String status; // 'active', 'completed', 'archived'

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  DateTime? updatedAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.category,
    required this.targetDate,
    this.initialAmount = 0.0,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        targetAmount: (json['target_amount'] as num).toDouble(),
        currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
        category: json['category'] as String? ?? 'savings',
        targetDate: DateTime.parse(json['target_date'] as String),
        initialAmount: (json['initial_amount'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'active',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'category': category,
        'target_date': targetDate.toIso8601String(),
        'initial_amount': initialAmount,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Serializes to JSON for Supabase
  Map<String, dynamic> toSupabaseJson() => toJson();

  /// Progress percentage (0.0 to 1.0), capped at 1.0 for visual display
  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);

  /// Remaining amount to reach target
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Whether the goal is completed (current amount >= target amount)
  bool get isCompleted => currentAmount >= targetAmount;

  /// Whether the goal is overdue
  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;

  /// Days remaining until target date
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;

  /// Copy with modifications
  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    String? category,
    DateTime? targetDate,
    double? initialAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      GoalModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        category: category ?? this.category,
        targetDate: targetDate ?? this.targetDate,
        initialAmount: initialAmount ?? this.initialAmount,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case 'savings':
        return 'Tabungan';
      case 'investment':
        return 'Investasi';
      case 'emergency':
        return 'Dana Darurat';
      case 'travel':
        return 'Perjalanan';
      case 'education':
        return 'Pendidikan';
      case 'purchase':
        return 'Pembelian';
      case 'other':
      default:
        return 'Lainnya';
    }
  }

  /// Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'savings':
        return Icons.savings_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'emergency':
        return Icons.health_and_safety_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'purchase':
        return Icons.shopping_bag_rounded;
      case 'other':
      default:
        return Icons.flag_rounded;
    }
  }

  /// Get category color
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'savings':
        return const Color(0xFF10B981); // Emerald
      case 'investment':
        return const Color(0xFF6366F1); // Indigo
      case 'emergency':
        return const Color(0xFFF43F5E); // Rose
      case 'travel':
        return const Color(0xFFF59E0B); // Amber
      case 'education':
        return const Color(0xFF06B6D4); // Cyan
      case 'purchase':
        return const Color(0xFFA855F7); // Purple
      case 'other':
      default:
        return const Color(0xFF38BDF8); // Sky
    }
  }

  /// List of available categories for selection
  static const List<Map<String, dynamic>> categories = [
    {'value': 'savings', 'label': 'Tabungan', 'icon': Icons.savings_rounded, 'color': Color(0xFF10B981)},
    {'value': 'investment', 'label': 'Investasi', 'icon': Icons.trending_up_rounded, 'color': Color(0xFF6366F1)},
    {'value': 'emergency', 'label': 'Dana Darurat', 'icon': Icons.health_and_safety_rounded, 'color': Color(0xFFF43F5E)},
    {'value': 'travel', 'label': 'Perjalanan', 'icon': Icons.flight_rounded, 'color': Color(0xFFF59E0B)},
    {'value': 'education', 'label': 'Pendidikan', 'icon': Icons.school_rounded, 'color': Color(0xFF06B6D4)},
    {'value': 'purchase', 'label': 'Pembelian', 'icon': Icons.shopping_bag_rounded, 'color': Color(0xFFA855F7)},
    {'value': 'other', 'label': 'Lainnya', 'icon': Icons.flag_rounded, 'color': Color(0xFF38BDF8)},
  ];
}