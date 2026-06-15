// import 'dart:async';
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:walleta/config/api_config.dart';
// import 'package:walleta/services/token_service.dart';

// class TransactionService extends ChangeNotifier {
//   List<TransactionModel> _transactions = [];
//   List<TransactionModel> get transactions => _transactions;

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   DateTime _lastUpdated = DateTime.now();
//   DateTime get lastUpdated => _lastUpdated;

//   final StreamController<List<TransactionModel>> _transactionsStreamController =
//       StreamController<List<TransactionModel>>.broadcast();
//   Stream<List<TransactionModel>> get transactionsStream =>
//       _transactionsStreamController.stream;

//   String? _error;
//   String? get error => _error;

//   TransactionService() {
//     fetchTransactions();
//   }

//   void clearData() {
//     _transactions = [];
//     _error = null;
//     _transactionsStreamController.add([]);
//     notifyListeners();
//   }

//   void clearTransactions() {
//     clearData();
//   }

//   Future<void> fetchTransactions() async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final String? userEmail = await TokenService.getUserEmail();

//       if (userEmail == null || userEmail.isEmpty) {
//         _error = "User not logged in";
//         _transactions = [];
//         _transactionsStreamController.add([]);
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('${ApiConfig.transactions}?email=$userEmail'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         _transactions = data.map((e) => TransactionModel.fromJson(e)).toList();

//         _transactions.sort((a, b) {
//           final aDate = a.createdAt ?? DateTime(0);
//           final bDate = b.createdAt ?? DateTime(0);
//           return bDate.compareTo(aDate);
//         });

//         _lastUpdated = DateTime.now();
//         _transactionsStreamController.add(_transactions);
//       } else {
//         _error = 'Failed to load transactions: ${response.statusCode}';
//       }
//     } catch (e) {
//       _error = 'Sync Error: $e';
//       if (kDebugMode) {
//         print('Sync Error: $e');
//       }
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<bool> addTransaction({
//     required String title,
//     required double amount,
//     required String category,
//     required String emoji,
//     required bool isIncome,
//   }) async {
//     final String? userEmail =
//         (await TokenService.getUserEmail()) ??
//         FirebaseAuth.instance.currentUser?.email;

//     if (userEmail == null || userEmail.isEmpty) {
//       _error = "Session expired. Please login again.";
//       notifyListeners();
//       return false;
//     }

//     final body = jsonEncode({
//       'email': userEmail,
//       'title': title,
//       'amount': amount,
//       'category': category,
//       'emoji': emoji,
//       'isIncome': isIncome,
//       'createdAt': DateTime.now().toIso8601String(),
//     });

//     _isLoading = true;
//     notifyListeners();

//     try {
//       final response = await http.post(
//         Uri.parse(ApiConfig.transactions),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'ngrok-skip-browser-warning': 'true',
//         },
//         body: body,
//       );

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         await fetchTransactions();
//         return true;
//       } else {
//         _error = 'Failed to add transaction: ${response.statusCode}';
//         return false;
//       }
//     } catch (e) {
//       _error = 'Error adding transaction: $e';
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   bool _isSameDay(DateTime date1, DateTime date2) {
//     return date1.year == date2.year &&
//         date1.month == date2.month &&
//         date1.day == date2.day;
//   }

//   List<TransactionModel> getTransactionsForDay(DateTime day) {
//     return _transactions.where((tx) {
//       final created = tx.createdAt;
//       return created != null && _isSameDay(created, day);
//     }).toList();
//   }

//   List<TransactionModel> getTransactionsForDateRange(
//     DateTime startDate,
//     DateTime endDate,
//   ) {
//     final start = DateTime(startDate.year, startDate.month, startDate.day);
//     final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

//     return _transactions.where((tx) {
//       final created = tx.createdAt;
//       return created != null &&
//           (created.isAtSameMomentAs(start) || created.isAfter(start)) &&
//           (created.isAtSameMomentAs(end) || created.isBefore(end));
//     }).toList();
//   }

//   double getTotalExpenseForDateRange(DateTime startDate, DateTime endDate) {
//     return getTransactionsForDateRange(startDate, endDate)
//         .where((tx) => !(tx.isIncome ?? false))
//         .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));
//   }

//   double getTotalIncomeForDateRange(DateTime startDate, DateTime endDate) {
//     return getTransactionsForDateRange(startDate, endDate)
//         .where((tx) => tx.isIncome ?? false)
//         .fold(0.0, (sum, tx) => sum + (tx.amount ?? 0));
//   }

//   List<TransactionModel> getTransactionsForToday() {
//     return getTransactionsForDay(DateTime.now());
//   }

//   double getTodayExpense() =>
//       getTotalExpenseForDateRange(DateTime.now(), DateTime.now());
//   double getTodayIncome() =>
//       getTotalIncomeForDateRange(DateTime.now(), DateTime.now());

//   List<TransactionModel> getRecentTransactions({int limit = 5}) {
//     return _transactions.take(limit).toList();
//   }

//   Map<String, double> getCategoryExpenses(
//     DateTime startDate,
//     DateTime endDate,
//   ) {
//     final transactions = getTransactionsForDateRange(startDate, endDate);
//     final categoryMap = <String, double>{};

//     for (var tx in transactions) {
//       if (!(tx.isIncome ?? false) && tx.category != null) {
//         final category = tx.category!;
//         final amount = tx.amount ?? 0;
//         categoryMap[category] = (categoryMap[category] ?? 0) + amount;
//       }
//     }
//     return categoryMap;
//   }

//   @override
//   void dispose() {
//     _transactionsStreamController.close();
//     super.dispose();
//   }
// }
