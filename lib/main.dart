import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/firebase_options.dart';
import 'package:walleta/screen/profile/viewmodel/profile_viewmodel.dart';
import 'package:walleta/screen/profile/viewmodel/notification_viewmodel.dart';
import 'package:walleta/screen/home/viewmodel/home_viewmodel.dart';
import 'package:walleta/screen/splash/splash_view.dart';
import 'package:walleta/services/currency_service.dart';
import 'package:walleta/services/transaction_service.dart';
import 'package:walleta/theme/app_theme_manager.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const WalletaApp());
}

class WalletaApp extends StatelessWidget {
  const WalletaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeManager()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => TransactionService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
