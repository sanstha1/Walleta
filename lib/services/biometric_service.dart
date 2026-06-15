import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_android/local_auth_android.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      return isDeviceSupported && canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to login to Walleta',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Walleta Login',
            cancelButton: 'Cancel',
          ),
          IOSAuthMessages(cancelButton: 'Cancel'),
        ],
      );
    } on PlatformException catch (e) {
      debugPrint('[BIO] PlatformException: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[BIO] Unknown error: $e');
      return false;
    }
  }
}
