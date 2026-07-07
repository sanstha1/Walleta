import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:http/http.dart' as http;
import 'package:walleta/config/api_config.dart';
import 'package:walleta/services/token_service.dart';

class Category {
  final String id;
  final String title;
  final String emoji;
  final bool isCustom;

  Category({
    required this.id,
    required this.title,
    required this.emoji,
    required this.isCustom,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Other',
      emoji: json['emoji'] ?? '📁',
      isCustom: json['isCustom'] ?? false,
    );
  }
}

class AddTransactionViewModel extends BaseViewModel {
  AddTransactionViewModel({
    String? description,
    bool? isIncome,
    double? amount,
    String? category,
  }) {
    if (description != null) transactionTitle.text = description;
    if (amount != null) transactionAmount.text = amount.toString();
    if (isIncome != null) this.isIncome = isIncome;
    if (category != null) _selectedCategory = category;
  }

  static final String _baseUrl = '${ApiConfig.baseUrl}/api';

  bool _isDisposed = false;

  final FocusNode titleFocusNode = FocusNode();
  final FocusNode amountFocusNode = FocusNode();

  bool isIncome = false;
  final transactionTitle = TextEditingController();
  final transactionAmount = TextEditingController();

  String _selectedCategory = "";
  String get selectedCategory => _selectedCategory;

  bool isEditing = false;
  String? editingId;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  bool get canAddTransaction =>
      transactionTitle.text.isNotEmpty &&
      transactionAmount.text.isNotEmpty &&
      selectedCategory.isNotEmpty;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void setBusy(bool value) {
    if (_isDisposed) return;
    super.setBusy(value);
  }

  void selectCategory(String category) {
    if (_isDisposed) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void onSignChange(bool value) {
    if (_isDisposed) return;
    isIncome = value;
    notifyListeners();
  }

  void editTransaction(dynamic transaction) {
    if (_isDisposed) return;
    isEditing = true;
    editingId = transaction['_id'];
    transactionTitle.text = transaction['title'];
    transactionAmount.text = transaction['amount'].toString();
    isIncome = transaction['isIncome'] ?? false;
    _selectedCategory = transaction['category'] ?? "";
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    if (_isDisposed) return;
    setBusy(true);
    try {
      final String? userEmail = await TokenService.getUserEmail();
      if (_isDisposed) return;

      final cleanEmail = userEmail?.trim() ?? "";
      final response = await http.get(
        Uri.parse('$_baseUrl/categories?email=$cleanEmail'),
      );
      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _categories = data.map((item) => Category.fromJson(item)).toList();
        debugPrint(
          'DEBUG: Found ${_categories.length} categories for $cleanEmail',
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (!_isDisposed) {
        setBusy(false);
        notifyListeners();
      }
    }
  }

  Future<void> updateTransaction() async {
    if (_isDisposed) return;
    setBusy(true);
    try {
      final String? userEmail = await TokenService.getUserEmail();
      if (_isDisposed) return;
      if (userEmail == null || editingId == null) return;

      final response = await http.put(
        Uri.parse(
          '$_baseUrl/transactions/$editingId?email=${userEmail.trim()}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': transactionTitle.text.trim(),
          'amount': double.tryParse(transactionAmount.text),
          'category': _selectedCategory,
          'isIncome': isIncome,
        }),
      );
      if (_isDisposed) return;

      if (response.statusCode == 200) {
        transactionTitle.clear();
        transactionAmount.clear();
        isEditing = false;
      }
    } catch (e) {
      debugPrint('Update Error: $e');
    } finally {
      if (!_isDisposed) setBusy(false);
    }
  }

  Future<void> onSaveTransactionPressed() async {
    if (_isDisposed) return;
    return runBusyFuture(_onSaveTransactionPressed());
  }

  Future<void> _onSaveTransactionPressed() async {
    if (_isDisposed) return;
    final title = transactionTitle.text.trim();
    final amountText = transactionAmount.text.trim();
    final amount = double.tryParse(amountText);
    final String? userEmail = await TokenService.getUserEmail();
    if (_isDisposed) return;

    if (userEmail == null || amount == null || amount <= 0) return;

    String selectedEmoji = isIncome ? "💰" : "💸";
    try {
      final matchedCategory = _categories.firstWhere(
        (c) =>
            c.title.toLowerCase().trim() ==
            _selectedCategory.toLowerCase().trim(),
      );
      selectedEmoji = matchedCategory.emoji;
    } catch (_) {}

    final response = await http.post(
      Uri.parse('$_baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': userEmail,
        'title': title,
        'amount': amount,
        'category': _selectedCategory,
        'emoji': selectedEmoji,
        'isIncome': isIncome,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
    if (_isDisposed) return;

    if (response.statusCode == 201 || response.statusCode == 200) {
      transactionTitle.clear();
      transactionAmount.clear();
      _selectedCategory = "";
      notifyListeners();
    }
  }

  Future<void> saveTransaction() async {
    if (_isDisposed) return;
    final title = transactionTitle.text.trim();
    final amountText = transactionAmount.text.trim();
    final amount = double.tryParse(amountText);
    final String? userEmail = await TokenService.getUserEmail();
    if (_isDisposed) return;

    if (userEmail == null || amount == null || amount <= 0) return;

    String selectedEmoji = isIncome ? "💰" : "💸";
    try {
      final matchedCategory = _categories.firstWhere(
        (c) =>
            c.title.toLowerCase().trim() ==
            _selectedCategory.toLowerCase().trim(),
      );
      selectedEmoji = matchedCategory.emoji;
    } catch (_) {}

    final response = await http.post(
      Uri.parse('$_baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': userEmail,
        'title': title,
        'amount': amount,
        'category': _selectedCategory,
        'emoji': selectedEmoji,
        'isIncome': isIncome,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
    if (_isDisposed) return;

    if (response.statusCode == 201 || response.statusCode == 200) {
      transactionTitle.clear();
      transactionAmount.clear();
      _selectedCategory = "";
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    if (_isDisposed) return;
    final String? userEmail = await TokenService.getUserEmail();
    if (_isDisposed) return;
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/categories/$id?email=$userEmail'),
      );
      if (_isDisposed) return;

      if (response.statusCode == 200) {
        await fetchCategories();
      }
    } catch (e) {
      debugPrint('Delete Error: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    titleFocusNode.dispose();
    amountFocusNode.dispose();
    transactionTitle.dispose();
    transactionAmount.dispose();
    super.dispose();
  }
}
