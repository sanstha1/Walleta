import 'dart:async';
import 'package:flutter/material.dart';
import 'package:light_sensor/light_sensor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walleta/theme/app_colors.dart';
import 'package:walleta/theme/app_theme.dart';

class AppThemeManager extends ChangeNotifier {
  bool _isDark = false;
  bool _autoLight = false;
  StreamSubscription<int>? _lightSubscription;

  bool get isDark => _isDark;
  bool get autoLight => _autoLight;

  AppColors get colors => _isDark ? AppColors.dark() : AppColors.light();

  ThemeData get theme => _isDark
      ? AppTheme.dark(AppColors.dark())
      : AppTheme.light(AppColors.light());

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDarkMode') ?? false;
    _autoLight = prefs.getBool('autoLight') ?? false;
    if (_autoLight) _startLightSensor();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDark);
    notifyListeners();
  }

  Future<void> toggleAutoLight() async {
    _autoLight = !_autoLight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoLight', _autoLight);
    if (_autoLight) {
      _startLightSensor();
    } else {
      _stopLightSensor();
    }
    notifyListeners();
  }

  void _startLightSensor() {
    _lightSubscription?.cancel();
    _lightSubscription = LightSensor.luxStream().listen((lux) {
      final shouldBeDark = lux < 50;
      if (_isDark != shouldBeDark) {
        _isDark = shouldBeDark;
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setBool('isDarkMode', _isDark),
        );
        notifyListeners();
      }
    }, onError: (e) => debugPrint('[LIGHT] Sensor error: $e'));
  }

  void _stopLightSensor() {
    _lightSubscription?.cancel();
    _lightSubscription = null;
  }

  @override
  void dispose() {
    _stopLightSensor();
    super.dispose();
  }
}
