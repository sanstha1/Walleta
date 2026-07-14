import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class ApiConfig {
  static const String _lanIp = '192.168.10.65';
  static const int _port = 5000;

  static String _baseUrl = 'http://10.0.2.2:$_port';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!Platform.isAndroid) {
      _baseUrl = 'http://$_lanIp:$_port';
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _baseUrl = androidInfo.isPhysicalDevice
          ? 'http://$_lanIp:$_port'
          : 'http://10.0.2.2:$_port';
    } catch (e) {
      _baseUrl = 'http://$_lanIp:$_port';
    }
  }

  static String get baseUrl => _baseUrl;

  static String get login => '$baseUrl/api/auth/login';
  static String get register => '$baseUrl/api/auth/signup';
  static String get googleAuth => '$baseUrl/api/auth/google';
  static String get verifyOtp => '$baseUrl/api/auth/verify-otp';
  static String get profile => '$baseUrl/api/auth/profile';
  static String get updateProfile => '$baseUrl/api/auth/update-profile';
  static String get updateFcmToken => '$baseUrl/api/auth/fcm-token';
  static String get uploadProfilePicture =>
      '$baseUrl/api/auth/upload-profile-picture';
  static String get forgotPassword => '$baseUrl/api/auth/forgot-password';
  static String get resetPassword => '$baseUrl/api/auth/reset-password';

  static String get transactions => '$baseUrl/api/transactions';
}
