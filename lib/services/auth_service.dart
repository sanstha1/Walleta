import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    if (kDebugMode) {
      print("signup called with: name=$name, email=$email");
    }
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/auth/signup"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": name.trim(),
              "email": email.trim().toLowerCase(),
              "password": password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print("here ${res.statusCode} ${res.body}");
      }

      return _parse(res);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      debugPrint("Signup error: $e");
      return _error(e.toString());
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email.trim().toLowerCase(),
              "password": password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      return _parse(res);
    } catch (e) {
      debugPrint("Login error: $e");
      return _error(e.toString());
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/auth/verify-otp"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email.trim().toLowerCase(),
              "otp": otp.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      return _parse(res);
    } catch (e) {
      debugPrint("VerifyOtp error: $e");
      return _error(e.toString());
    }
  }

  Future<Map<String, dynamic>> googleSignIn(String firebaseIdToken) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/auth/google"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"idToken": firebaseIdToken}),
          )
          .timeout(const Duration(seconds: 10));

      return _parse(res);
    } catch (e) {
      debugPrint("GoogleSignIn error: $e");
      return _error(e.toString());
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      debugPrint(
        "📡 Forgot password request → $baseUrl/api/auth/forgot-password",
      );
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/auth/forgot-password"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email.trim().toLowerCase()}),
          )
          .timeout(const Duration(seconds: 10));

      return _parse(res);
    } catch (e) {
      debugPrint("ForgotPassword error: $e");
      return _error(e.toString());
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      debugPrint(
        "📡 Reset password request → $baseUrl/api/auth/reset-password",
      );
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/auth/reset-password"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email.trim().toLowerCase(),
              "otp": otp.trim(),
              "newPassword": newPassword.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("Reset response: ${res.statusCode} ${res.body}");
      return _parse(res);
    } catch (e) {
      debugPrint("ResetPassword error: $e");
      return _error(e.toString());
    }
  }

  static Future<String?> getToken() async {
    return null;
  }

  Map<String, dynamic> _parse(http.Response res) {
    try {
      return {"status": res.statusCode, "data": jsonDecode(res.body)};
    } catch (_) {
      return {
        "status": res.statusCode,
        "data": {"message": res.body},
      };
    }
  }

  Map<String, dynamic> _error(String message) {
    return {
      "status": 500,
      "data": {"message": message},
    };
  }
}
