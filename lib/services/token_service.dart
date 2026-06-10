import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey          = 'auth_token';
  static const String _verificationKey   = 'email_verified';
  static const String _userEmailKey      = 'user_email';
  static const String _biometricKey      = 'biometric_enabled';
  static const String _biometricTokenKey = 'biometric_token';
  static const String _biometricEmailKey = 'biometric_email';

  // ── Save token ─────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (kDebugMode) print('TokenService: Token saved successfully');
  }
static Future<void> fixEmailIfWrong() async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getString('user_email');
  final fixed = current?.trim().toLowerCase();
  if (current != fixed) {
    await prefs.setString('user_email', fixed ?? '');
    debugPrint('📧 Email fixed: $current → $fixed');
  }
}
  static Future<void> save(String token) async => saveToken(token);

  // ── Get token ──────────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ── Check token exists ─────────────────────────────────────────────────────
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Verification status ────────────────────────────────────────────────────
  static Future<void> saveVerificationStatus(bool isVerified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_verificationKey, isVerified);
    if (kDebugMode) print('TokenService: Verification status saved');
  }

  static Future<bool> isVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_verificationKey) ?? false;
  }

  static Future<void> saveUserEmail(String email) async {
  final prefs = await SharedPreferences.getInstance();
  // Strip ALL whitespace and lowercase — fixes any typo from old saves
  final normalized = email.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  await prefs.setString('user_email', normalized);
  debugPrint('TokenService: Email saved: $normalized');
}

static Future<String?> getUserEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_email')
      ?.replaceAll(RegExp(r'\s+'), '')
      .toLowerCase();
}
  static Future<String?> getEmail() async => getUserEmail();

  // ── Biometric preference ───────────────────────────────────────────────────
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  // ── Biometric session (survives logout) ────────────────────────────────────
  static Future<void> saveBiometricSession(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_biometricTokenKey, token);
    await prefs.setString(_biometricEmailKey, email);
    if (kDebugMode) print('TokenService: Biometric session saved for $email');
  }

  static Future<String?> getBiometricToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricTokenKey);
  }

  static Future<String?> getBiometricEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricEmailKey);
  }

  // ── Save Google Sign-In session ────────────────────────────────────────────
  static Future<void> saveGoogleSession({
    required String token,
    required String email,
  }) async {
    await saveToken(token);
    await saveUserEmail(email);
    await saveVerificationStatus(true);
    if (kDebugMode) print('TokenService: Google session saved for $email');
  }

  // ── Clear everything on logout (biometric session survives) ───────────────
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_verificationKey);
    await prefs.remove(_userEmailKey);
    // _biometricKey, _biometricTokenKey, _biometricEmailKey intentionally kept
    if (kDebugMode) print('TokenService: All auth data cleared');
  }
}