// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:walleta/config/api_config.dart';
// import 'package:walleta/services/token_service.dart';

// class BudgetService extends ChangeNotifier {
//   static final String _baseUrl = '${ApiConfig.baseUrl}/api';

//   List<BudgetModel> _budgets = [];
//   List<BudgetModel> get budgets => _budgets;

//   BudgetModel? _overallBudget;
//   BudgetModel? get overallBudget => _overallBudget;

//   Map<String, BudgetModel> _categoryBudgets = {};
//   Map<String, BudgetModel> get categoryBudgets => _categoryBudgets;

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   String? _error;
//   String? get error => _error;

//   // Fetch budgets for current month
//   Future<void> fetchBudgets(String email, {String? monthYear}) async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final token = await TokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final params = {'email': email};
//       if (monthYear != null) {
//         params['monthYear'] = monthYear;
//       }

//       final uri = Uri.parse(
//         '$_baseUrl/budgets',
//       ).replace(queryParameters: params);

//       final response = await http
//           .get(
//             uri,
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         _budgets = data.map((item) => BudgetModel.fromJson(item)).toList();

//         // Separate overall and category budgets
//         _overallBudget = _budgets.firstWhere(
//           (b) => b.category == null,
//           orElse: () => BudgetModel(),
//         );

//         _categoryBudgets = {};
//         for (var budget in _budgets) {
//           if (budget.category != null) {
//             _categoryBudgets[budget.category!] = budget;
//           }
//         }

//         _error = null;
//       } else {
//         throw Exception('Failed to fetch budgets: ${response.statusCode}');
//       }
//     } on SocketException catch (e) {
//       _error = 'Network error: cannot reach server (${e.message})';
//       if (kDebugMode) {
//         print('SocketException fetching budgets: $e');
//       }
//     } on TimeoutException catch (e) {
//       _error = 'Request timed out while fetching budgets';
//       if (kDebugMode) {
//         print('TimeoutException fetching budgets: $e');
//       }
//     } catch (e) {
//       _error = e.toString();
//       if (kDebugMode) {
//         print('Error fetching budgets: $e');
//       }
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   Future<Map<String, dynamic>> getBudgetSummary(
//     String email, {
//     String? monthYear,
//   }) async {
//     try {
//       final token = await TokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final params = {'email': email};
//       if (monthYear != null) {
//         params['monthYear'] = monthYear;
//       }

//       final uri = Uri.parse(
//         '$_baseUrl/budgets/summary',
//       ).replace(queryParameters: params);

//       final response = await http
//           .get(
//             uri,
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         throw Exception(
//           'Failed to fetch budget summary: ${response.statusCode}',
//         );
//       }
//     } on SocketException catch (e) {
//       if (kDebugMode) {
//         print('SocketException fetching budget summary: $e');
//       }
//       throw Exception('Network error: cannot reach server (${e.message})');
//     } on TimeoutException catch (e) {
//       if (kDebugMode) {
//         print('TimeoutException fetching budget summary: $e');
//       }
//       throw Exception('Request timed out while fetching budget summary');
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error fetching budget summary: $e');
//       }
//       rethrow;
//     }
//   }

//   // Create budget
//   Future<BudgetModel> createBudget({
//     required String email,
//     required double limitAmount,
//     String? category,
//     String period = 'monthly',
//     String? monthYear,
//     int alertThreshold = 80,
//     bool alertsEnabled = true,
//   }) async {
//     try {
//       final token = await TokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final response = await http
//           .post(
//             Uri.parse('$_baseUrl/budgets'),
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//             body: jsonEncode({
//               'email': email,
//               'limitAmount': limitAmount,
//               'category': category,
//               'period': period,
//               'monthYear': monthYear,
//               'alertThreshold': alertThreshold,
//               'alertsEnabled': alertsEnabled,
//             }),
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 201) {
//         final data = jsonDecode(response.body);
//         final budget = BudgetModel.fromJson(data['budget']);

//         // Update local list
//         _budgets.add(budget);
//         if (category == null) {
//           _overallBudget = budget;
//         } else {
//           _categoryBudgets[category] = budget;
//         }

//         notifyListeners();
//         return budget;
//       } else {
//         debugPrint('❌ CREATE BUDGET FAILED');
//         debugPrint('   Status: ${response.statusCode}');
//         debugPrint('   Body: ${response.body}');
//         final error = jsonDecode(response.body);
//         throw Exception(
//           error['message'] ??
//               'Failed to create budget: ${response.statusCode} — ${response.body}',
//         );
//       }
//     } on SocketException catch (e) {
//       if (kDebugMode) {
//         print('SocketException creating budget: $e');
//       }
//       throw Exception('Network error: cannot reach server (${e.message})');
//     } on TimeoutException catch (e) {
//       if (kDebugMode) {
//         print('TimeoutException creating budget: $e');
//       }
//       throw Exception('Request timed out while creating budget');
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error creating budget: $e');
//       }
//       rethrow;
//     }
//   }

//   Future<BudgetModel> updateBudget({
//     required String budgetId,
//     double? limitAmount,
//     int? alertThreshold,
//     bool? alertsEnabled,
//     String? period,
//   }) async {
//     try {
//       final token = await TokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final body = <String, dynamic>{};
//       if (limitAmount != null) body['limitAmount'] = limitAmount;
//       if (alertThreshold != null) body['alertThreshold'] = alertThreshold;
//       if (alertsEnabled != null) body['alertsEnabled'] = alertsEnabled;

//       final response = await http
//           .put(
//             Uri.parse('$_baseUrl/budgets/$budgetId'),
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//             body: jsonEncode(body),
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final updatedBudget = BudgetModel.fromJson(data['budget']);

//         // Update local list
//         final index = _budgets.indexWhere((b) => b.id == budgetId);
//         if (index != -1) {
//           _budgets[index] = updatedBudget;
//         }

//         if (updatedBudget.category == null) {
//           _overallBudget = updatedBudget;
//         } else {
//           _categoryBudgets[updatedBudget.category!] = updatedBudget;
//         }

//         notifyListeners();
//         return updatedBudget;
//       } else {
//         throw Exception('Failed to update budget: ${response.statusCode}');
//       }
//     } on SocketException catch (e) {
//       if (kDebugMode) {
//         print('SocketException updating budget: $e');
//       }
//       throw Exception('Network error: cannot reach server (${e.message})');
//     } on TimeoutException catch (e) {
//       if (kDebugMode) {
//         print('TimeoutException updating budget: $e');
//       }
//       throw Exception('Request timed out while updating budget');
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error updating budget: $e');
//       }
//       rethrow;
//     }
//   }

//   Future<void> deleteBudget(String budgetId, String email) async {
//     try {
//       final token = await TokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final response = await http
//           .delete(
//             Uri.parse(
//               '$_baseUrl/budgets/$budgetId',
//             ).replace(queryParameters: {'email': email}),
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         // Update local list
//         _budgets.removeWhere((b) => b.id == budgetId);

//         if (_overallBudget?.id == budgetId) {
//           _overallBudget = null;
//         }

//         _categoryBudgets.removeWhere((k, v) => v.id == budgetId);

//         notifyListeners();
//       } else {
//         throw Exception('Failed to delete budget: ${response.statusCode}');
//       }
//     } on SocketException catch (e) {
//       if (kDebugMode) {
//         print('SocketException deleting budget: $e');
//       }
//       throw Exception('Network error: cannot reach server (${e.message})');
//     } on TimeoutException catch (e) {
//       if (kDebugMode) {
//         print('TimeoutException deleting budget: $e');
//       }
//       throw Exception('Request timed out while deleting budget');
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error deleting budget: $e');
//       }
//       rethrow;
//     }
//   }

//   Future<Map<String, dynamic>> checkBudgetLimit({
//     required String email,
//     required String category,
//     required double amount,
//   }) async {
//     try {
//       final token = await TokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final response = await http
//           .post(
//             Uri.parse('$_baseUrl/budgets/check'),
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//             body: jsonEncode({
//               'email': email,
//               'category': category,
//               'amount': amount,
//             }),
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         throw Exception('Failed to check budget limit: ${response.statusCode}');
//       }
//     } on SocketException catch (e) {
//       if (kDebugMode) {
//         print('SocketException checking budget limit: $e');
//       }
//       throw Exception('Network error: cannot reach server (${e.message})');
//     } on TimeoutException catch (e) {
//       if (kDebugMode) {
//         print('TimeoutException checking budget limit: $e');
//       }
//       throw Exception('Request timed out while checking budget limit');
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error checking budget limit: $e');
//       }
//       rethrow;
//     }
//   }

//   void checkAndNotifyAlerts({
//     required void Function(BudgetModel budget) onAlert,
//   }) {
//     for (final budget in _budgets) {
//       final alertsEnabled = budget.alertsEnabled ?? false;
//       final alreadySent = budget.alertSent ?? false;

//       if (!alertsEnabled) continue;
//       if (alreadySent) continue;
//       if (!budget.isNearLimit && !budget.isExceeded) continue;

//       onAlert(budget);
//     }
//   }

//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }
// }
