import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:walleta/config/api_config.dart';
import 'package:walleta/services/token_service.dart';

class TransactionModel {
  final String? id;
  final String? title;
  final double? amount;
  final String? category;
  final String? emoji;
  final bool? isIncome;
  final DateTime? createdAt;

  TransactionModel({
    this.id,
    this.title,
    this.amount,
    this.category,
    this.emoji,
    this.isIncome,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
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
          if (ms != null)
            parseCreatedAt = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }
    }

    return TransactionModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      title: json['title'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      category: json['category'] as String?,
      emoji: json['emoji'] as String?,
      isIncome: json['isIncome'] as bool?,
      createdAt: parseCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'emoji': emoji,
      'isIncome': isIncome,
    };
  }
}

class GetTransactionViewModel extends ChangeNotifier {
  static final String _baseUrl = '${ApiConfig.baseUrl}/api';

  final List<String> days = ["M", "T", "W", "T", "F", "S", "S"];
  final List<String> fullDayNames = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  DateTime _currentWeekStart = _getStartOfWeek(DateTime.now());
  int? selectedDayIndex;

  DateTime get currentWeekStart => _currentWeekStart;
  DateTime get currentWeekEnd => _currentWeekStart.add(const Duration(days: 6));

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  void clearTransactions() {
    _transactions.clear();
    notifyListeners();
  }

  void setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  static DateTime _getStartOfWeek(DateTime date) {
    final local = date.toLocal();
    final dateOnly = DateTime(local.year, local.month, local.day);
    final day = dateOnly.weekday;
    return dateOnly.subtract(Duration(days: day - 1));
  }

  void goToNextWeek() =>
      _updateWeek(_currentWeekStart.add(const Duration(days: 7)));
  void goToPreviousWeek() =>
      _updateWeek(_currentWeekStart.subtract(const Duration(days: 7)));

  void _updateWeek(DateTime newStart) {
    _currentWeekStart = newStart;
    selectedDayIndex = null;
    getSyncedTransactions();
  }

  void setSelectedDay(int? index) {
    selectedDayIndex = index;
    notifyListeners();
  }

  Future<void> getSyncedTransactions() async {
    setBusy(true);
    try {
      final String? userEmail = await TokenService.getUserEmail();
      if (userEmail == null) {
        _transactions = [];
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/transactions?email=$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _transactions = data.map((e) => TransactionModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      setBusy(false);
    }
  }

  Future<ApiResponse> deleteTransaction(String id) async {
    try {
      final String? userEmail = await TokenService.getUserEmail();
      final url = '$_baseUrl/transactions/$id?email=$userEmail';

      debugPrint("📡 DELETE REQUEST TO: $url");

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
        "📥 SERVER RESPONSE: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true);
      } else {
        return ApiResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint("❌ NETWORK ERROR: $e");
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<bool> updateTransaction(
    String transactionId,
    TransactionModel updatedTx,
  ) async {
    setBusy(true);
    try {
      final String? userEmail = await TokenService.getUserEmail();
      final response = await http.put(
        Uri.parse('$_baseUrl/transactions/$transactionId?email=$userEmail'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedTx.toJson()),
      );

      if (response.statusCode == 200) {
        final index = _transactions.indexWhere((tx) => tx.id == transactionId);
        if (index != -1) {
          await getSyncedTransactions();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error updating: $e");
      return false;
    } finally {
      setBusy(false);
    }
  }

  List<TransactionModel> get filteredTransactionsForSelectedDay {
    if (selectedDayIndex == null) return _transactions;
    final selectedDate = currentWeekStart.add(
      Duration(days: selectedDayIndex!),
    );
    return _transactions
        .where(
          (tx) =>
              tx.createdAt != null &&
              _isSameDay(tx.createdAt!.toLocal(), selectedDate),
        )
        .toList();
  }

  double get totalExpense => _sumTransactions(isIncome: false);
  double get totalIncome => _sumTransactions(isIncome: true);

  double _sumTransactions({required bool isIncome}) {
    final list = selectedDayIndex == null
        ? _transactions
        : filteredTransactionsForSelectedDay;
    return list
        .where((tx) => (tx.isIncome ?? false) == isIncome)
        .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));
  }

  List<double> get expenseHeights => _calculateBarHeights(isIncome: false);
  List<double> get incomeHeights => _calculateBarHeights(isIncome: true);

  List<double> _calculateBarHeights({required bool isIncome}) {
    final maxAmount = _maxTransactionAmountThisWeek;
    return List.generate(7, (index) {
      final date = _currentWeekStart.add(Duration(days: index));
      double dayTotal = _transactions
          .where(
            (tx) =>
                tx.createdAt != null &&
                _isSameDay(tx.createdAt!.toLocal(), date) &&
                (tx.isIncome ?? false) == isIncome,
          )
          .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));
      return maxAmount > 0 ? (dayTotal / maxAmount) * 100.0 : 0;
    });
  }

  double get _maxTransactionAmountThisWeek {
    double maxAmount = 0;
    for (int i = 0; i < 7; i++) {
      final date = _currentWeekStart.add(Duration(days: i));
      double dayTotal = _transactions
          .where(
            (tx) => tx.createdAt != null && _isSameDay(tx.createdAt!, date),
          )
          .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));
      if (dayTotal > maxAmount) maxAmount = dayTotal;
    }
    return maxAmount > 0 ? maxAmount : 1.0;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    final local1 = d1.toLocal();
    final local2 = d2.toLocal();
    return local1.year == local2.year &&
        local1.month == local2.month &&
        local1.day == local2.day;
  }

  String get formattedWeekRange {
    final start = currentWeekStart;
    final end = currentWeekEnd;
    return "${start.day} ${_monthName(start.month)} - ${end.day} ${_monthName(end.month)}, ${start.year}";
  }

  String _monthName(int month) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return m[month];
  }

  void initialize() => getSyncedTransactions();
}

class ApiResponse {
  final bool success;
  final String message;

  ApiResponse({required this.success, this.message = ''});
}

class ApiService {
  static final String _baseUrl = '${ApiConfig.baseUrl}/api';

  Future<ApiResponse> deleteTransaction(String id) async {
    try {
      final String? userEmail = await TokenService.getUserEmail();

      final response = await http.delete(
        Uri.parse('$_baseUrl/transactions/$id?email=$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to delete',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
