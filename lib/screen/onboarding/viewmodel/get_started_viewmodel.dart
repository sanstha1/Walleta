import 'package:flutter/cupertino.dart';
import 'package:stacked/stacked.dart';
import 'package:walleta/screen/authentication/login_page.dart';
import 'package:walleta/screen/authentication/signup_page.dart';

class GetStartedViewModel extends BaseViewModel {
  void onSignInPressed(BuildContext context) {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => const LoginPage()));
  }

  void onCreateAccountPressed(BuildContext context) {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => const SignupPage()));
  }
}
