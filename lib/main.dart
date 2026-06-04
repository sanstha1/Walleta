import 'package:flutter/material.dart';
import 'screen/splash/splash_view.dart';

void main() {
  runApp(const WalletaApp());
}

class WalletaApp extends StatelessWidget {
  const WalletaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walleta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A5EA8)),
      ),
      home: const SplashScreen(),
    );
  }
}
