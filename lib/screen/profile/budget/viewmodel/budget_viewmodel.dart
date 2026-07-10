class BudgetModel {
  final String? id;
  final String? email;
  final String? category;
  final double? limitAmount;
  final String? period;
  final String? periodKey;
  final String? monthYear;
  final int? alertThreshold;
  final bool? alertsEnabled;
  final double? spent;
  final bool? alertSent;
  final DateTime? createdAt;

  BudgetModel({
    this.id,
    this.email,
    this.category,
    this.limitAmount,
    this.period,
    this.periodKey,
    this.monthYear,
    this.alertThreshold,
    this.alertsEnabled,
    this.spent,
    this.alertSent,
    this.createdAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseCreatedAt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        parseCreatedAt = DateTime.tryParse(json['createdAt']);
      } else if (json['createdAt'] is int) {
        parseCreatedAt = DateTime.fromMillisecondsSinceEpoch(
          json['createdAt'] * 1000,
        );
      } else if (json['createdAt'] is Map<String, dynamic>) {
        final dateMap = json['createdAt'] as Map<String, dynamic>;
        if (dateMap['\$date'] != null) {
          final ms = dateMap['\$date'] is String
              ? int.tryParse(dateMap['\$date'])
              : (dateMap['\$date'] as num?)?.toInt();
          if (ms != null) {
            parseCreatedAt = DateTime.fromMillisecondsSinceEpoch(ms);
          }
        }
      }
    }

    return BudgetModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      email: json['email'] as String?,
      category: json['category'] as String?,
      limitAmount: (json['limitAmount'] as num?)?.toDouble(),
      period: json['period'] as String? ?? 'monthly',
      periodKey: json['periodKey'] as String?,
      monthYear: json['monthYear'] as String?,
      alertThreshold: json['alertThreshold'] as int?,
      alertsEnabled: json['alertsEnabled'] as bool?,
      spent: (json['spent'] as num?)?.toDouble(),
      alertSent: json['alertSent'] as bool?,
      createdAt: parseCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'category': category,
      'limitAmount': limitAmount,
      'period': period,
      'periodKey': periodKey,
      'monthYear': monthYear,
      'alertThreshold': alertThreshold,
      'alertsEnabled': alertsEnabled,
    };
  }

  double get percentageUsed {
    if (limitAmount == null || limitAmount == 0) return 0;
    return ((spent ?? 0) / limitAmount!) * 100;
  }

  double get remaining {
    if (limitAmount == null) return 0;
    final rem = limitAmount! - (spent ?? 0);
    return rem > 0 ? rem : 0;
  }

  bool get isExceeded {
    if (limitAmount == null) return false;
    return (spent ?? 0) > limitAmount!;
  }

  bool get isNearLimit {
    if (limitAmount == null || alertThreshold == null) return false;
    final threshold = (alertThreshold! / 100) * limitAmount!;
    return (spent ?? 0) >= threshold;
  }

  String get budgetType {
    return category == null ? 'Overall' : category!;
  }

  String get periodLabel {
    final p = period ?? 'monthly';
    return p == 'daily'
        ? 'Daily'
        : p == 'weekly'
        ? 'Weekly'
        : 'Monthly';
  }

  BudgetModel copyWith({
    String? id,
    String? email,
    String? category,
    double? limitAmount,
    String? monthYear,
    int? alertThreshold,
    bool? alertsEnabled,
    double? spent,
    bool? alertSent,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      email: email ?? this.email,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      monthYear: monthYear ?? this.monthYear,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      spent: spent ?? this.spent,
      alertSent: alertSent ?? this.alertSent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
