import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:walleta/config/api_config.dart';

class NotificationSync {
  static Future<void> updateTokenOnBackend(String email) async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await http.post(
        Uri.parse(ApiConfig.updateFcmToken),
        body: {"email": email, "fcmToken": token},
      );
    }
  }
}

class GoogleSignInService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool isInitialize = false;

  static Future<void> initSignIn() async {
    if (!isInitialize) {
      await _googleSignIn.initialize(
        serverClientId:
            '118065038551-k2d1uekjv2vbv0agc6mgcgesf4fgbotf.apps.googleusercontent.com',
      );
    }
    isInitialize = true;
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      initSignIn();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final authorizationClient = googleUser.authorizationClient;
      GoogleSignInClientAuthorization? authorization = await authorizationClient
          .authorizationForScopes(['email', 'profile']);
      final accessToken = authorization?.accessToken;
      if (accessToken == null) {
        final authorization2 = await authorizationClient.authorizationForScopes(
          ['email', 'profile'],
        );
        if (authorization2?.accessToken == null) {
          throw FirebaseAuthException(code: "error", message: "error");
        }
        authorization = authorization2;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      rethrow;
    }
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static Future<void> updateTokenOnBackend(String email) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await http.post(
          Uri.parse(ApiConfig.updateFcmToken),
          body: {"email": email, "fcmToken": token},
        );
        debugPrint("FCM Token synced for $email");
      }
    } catch (e) {
      debugPrint("Token sync failed: $e");
    }
  }
}
