import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stacked/stacked.dart';
import 'package:walleta/config/api_config.dart';
import 'package:walleta/services/token_service.dart';

class CategoryModel {
  final String id;
  final String title;
  final String emoji;
  final bool isCustom;

  CategoryModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.isCustom,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Other',
      emoji: json['emoji'] ?? '📁',
      isCustom: json['isCustom'] ?? false,
    );
  }
}

class AddCategoryViewModel extends BaseViewModel {
  final TextEditingController titleController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();

  static final String _baseUrl = '${ApiConfig.baseUrl}/api';

  final List<String> emojis = const [
    '😊',
    '💰',
    '🍕',
    '🚗',
    '🏠',
    '💼',
    '🎓',
    '🛒',
    '🍔',
    '☕',
    '✈️',
    '🎬',
    '🏥',
    '💳',
    '📱',
    '🎁',
    '🍎',
    '⚽',
    '🎮',
    '📚',
    '🎵',
    '🎨',
    '🏋️',
    '🚲',
    '🏖️',
    '🎯',
    '💎',
    '🌮',
    '🍣',
    '🍦',
    '🎂',
    '🍷',
  ];

  String _selectedEmoji = '';
  String get selectedEmoji => _selectedEmoji;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  bool get canAddCategory =>
      titleController.text.trim().isNotEmpty && _selectedEmoji.isNotEmpty;

  void selectEmoji(String emoji) {
    _selectedEmoji = emoji;
    notifyListeners();
  }

  void updateCanAddCategory() {
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    setBusy(true);
    try {
      final String? userEmail = await TokenService.getUserEmail();
      final cleanEmail = userEmail?.trim() ?? "";

      final response = await http.get(
        Uri.parse('$_baseUrl/categories?email=$cleanEmail'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _categories = data.map((item) => CategoryModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Fetch Categories Error: $e');
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future<void> onSaveCategoryPressed(BuildContext context) async {
    if (!canAddCategory) return;

    setBusy(true);
    try {
      final String? userEmail = await TokenService.getUserEmail();

      if (userEmail == null) {
        // ignore: use_build_context_synchronously
        _showSnackBar(context, "User session not found. Please login again.");
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': userEmail,
          'title': titleController.text.trim(),
          'emoji': _selectedEmoji,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        titleController.clear();
        _selectedEmoji = '';
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      } else {
        final errorData = jsonDecode(response.body);
        // ignore: use_build_context_synchronously
        _showSnackBar(
          context,
          errorData['message'] ?? "Failed to save category",
        );
      }
    } catch (e) {
      debugPrint("Error saving category: $e");
      // ignore: use_build_context_synchronously
      _showSnackBar(context, "Connection error. Is the server running?");
    } finally {
      setBusy(false);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final String? userEmail = await TokenService.getUserEmail();
      final response = await http.delete(
        Uri.parse('$_baseUrl/categories/$id?email=$userEmail'),
      );

      if (response.statusCode == 200) {
        await fetchCategories();
      }
    } catch (e) {
      debugPrint('Delete Category Error: $e');
    }
  }

  void onCancelPressed(BuildContext context) {
    Navigator.pop(context);
  }

  void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }
}
