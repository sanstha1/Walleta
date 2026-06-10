import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:walleta/config/api_config.dart';
import 'package:walleta/services/token_service.dart';

class ProfileViewModel extends ChangeNotifier {
  String _name = "User";
  String _profileImage = 'https://i.pravatar.cc/150';
  bool _isLoading = false;
  String _email = "";

  String get name => _name;
  String get profileImage => _profileImage;
  bool get isLoading => _isLoading;
  String get email => _email;

  final String _apiUrl = '${ApiConfig.baseUrl}/api/auth/profile';

  void updateProfileImage(String newUrl) {
    _profileImage = newUrl;
    notifyListeners();
  }

  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      String? token = await TokenService.getToken();

      if (token == null || token.isEmpty) {
        debugPrint("No JWT found — user not logged in");
        _isLoading = false;
        notifyListeners();
        return;
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _email = firebaseUser.email ?? _email;
        if (_name == "User" && firebaseUser.displayName != null) {
          _name = firebaseUser.displayName!;
        }
      }

      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final userData = decoded['data'] ?? decoded['user'] ?? decoded;

        _name = userData['name'] ?? _name;
        _profileImage = userData['profileImage'] ?? _profileImage;
        _email = userData['email'] ?? _email;

        debugPrint("Profile loaded");
      } else {
        debugPrint(
          "! Profile fetch failed: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("loadUserData error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _name = "User";
    _profileImage = 'https://i.pravatar.cc/150';
    _email = "";
    notifyListeners();
  }
}
