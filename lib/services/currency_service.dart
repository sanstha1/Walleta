import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  static const String _key = 'selected_currency';

  static const List<Map<String, String>> supportedCurrencies = [
    {'symbol': 'Rs.', 'name': 'Nepali Rupee',   'code': 'NPR'},
    {'symbol': '\$',  'name': 'US Dollar',       'code': 'USD'},
    {'symbol': '€',   'name': 'Euro',            'code': 'EUR'},
    {'symbol': '£',   'name': 'British Pound',   'code': 'GBP'},
    {'symbol': '₹',   'name': 'Indian Rupee',    'code': 'INR'},
    {'symbol': '¥',   'name': 'Japanese Yen',    'code': 'JPY'},
    {'symbol': 'A\$', 'name': 'Australian Dollar','code': 'AUD'},
    {'symbol': 'C\$', 'name': 'Canadian Dollar', 'code': 'CAD'},
  ];

  String _symbol = 'Rs.';
  String _code   = 'NPR';
  bool   _loaded = false;

  String get symbol => _symbol;
  String get code   => _code;
  bool   get loaded => _loaded;

  /// Call once at startup — reads from SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      final match = supportedCurrencies.firstWhere(
        (c) => c['code'] == saved,
        orElse: () => supportedCurrencies.first,
      );
      _symbol = match['symbol']!;
      _code   = match['code']!;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setCurrency(Map<String, String> currency) async {
    _symbol = currency['symbol']!;
    _code   = currency['code']!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _code);
    notifyListeners();
  }

  /// Returns true if no currency has been chosen yet (first launch)
  Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) == null;
  }

  /// Helper — formats an amount with the current symbol
  String format(double amount) => '$_symbol ${amount.toStringAsFixed(2)}';
}