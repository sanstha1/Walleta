import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walleta/theme/app_theme_manager.dart';

class AppColors {
  final Color backgroundColor;
  final Color primaryText;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondary;
  final Color accent;
  final Color solidBlack;
  final Color imageBackground;
  final Color onboardingBackground;
  final Color containerBG;
  final Color tileBG;
  final Color disabledText;
  final Color barchartBG;
  final Color transactionPage;
  final Color containerBG2;
  final Color secondaryBG;
  final Color primaryGrey;
  final Color secondaryGrey;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color disabled;
  final Color cardBackground;
  final Color subtitleText;
  final Color divider;
  final Color inputFill;
  final Color lostColor;
  final Color foundColor;
  final Color claimedColor;
  final Color navBackground;
  final Color navActiveIcon;
  final Color navInactiveIcon;
  final Color fabBackground;

  AppColors({
    required this.backgroundColor,
    required this.primaryText,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
    required this.solidBlack,
    required this.imageBackground,
    required this.onboardingBackground,
    required this.containerBG,
    required this.tileBG,
    required this.disabledText,
    required this.barchartBG,
    required this.transactionPage,
    required this.containerBG2,
    required this.secondaryBG,
    required this.primaryGrey,
    required this.secondaryGrey,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.disabled,
    required this.cardBackground,
    required this.subtitleText,
    required this.divider,
    required this.inputFill,
    required this.lostColor,
    required this.foundColor,
    required this.claimedColor,
    required this.navBackground,
    required this.navActiveIcon,
    required this.navInactiveIcon,
    required this.fabBackground,
  });

  static AppColors dark() {
    return AppColors(
      backgroundColor: const Color(0xFF000000),
      primaryText: const Color(0xFFE8EAED),
      primary: const Color(0xFF6C63FF),
      primaryDark: const Color(0xFF5B54E8),
      primaryLight: const Color(0xFF8F87FF),
      secondary: const Color(0xFF4ECDC4),
      accent: const Color(0xFFFF6584),
      solidBlack: const Color(0xFF000000),
      imageBackground: const Color(0xFF1A1F26),
      onboardingBackground: const Color(0xFF0F1419),
      containerBG: const Color(0xFF1A1F26),
      tileBG: const Color(0xFF242A32),
      disabledText: const Color(0xFF7C8186),
      barchartBG: const Color(0xFF1E242C),
      transactionPage: const Color(0xFF161B22),
      containerBG2: const Color(0xFF2D3339),
      secondaryBG: const Color(0xFF131820),
      primaryGrey: const Color(0xFFB4B8BB),
      secondaryGrey: const Color(0xFF7C8186),
      success: const Color(0xFF4CAF50),
      warning: const Color(0xFFFFA726),
      error: const Color(0xFFEF4444),
      info: const Color(0xFF3B82F6),
      disabled: const Color(0xFF2D3339),
      cardBackground: const Color(0xFF1A1F26),
      subtitleText: const Color(0xFFB4B8BB),
      divider: const Color(0xFF252B33),
      inputFill: const Color(0xFF1E242C),
      lostColor: const Color(0xFFE53935),
      foundColor: const Color(0xFF43A047),
      claimedColor: const Color(0xFF9E9E9E),
      navBackground: const Color(0xFF1A1F26),
      navActiveIcon: const Color(0xFFFFFFFF),
      navInactiveIcon: const Color(0xFF7C8186),
      fabBackground: const Color(0xFF4ECDC4),
    );
  }

  static AppColors light() {
    return AppColors(
      backgroundColor: const Color(0xFFB0C4DE),
      primaryText: const Color(0xFF2D3142),
      primary: const Color(0xFF6C63FF),
      primaryDark: const Color(0xFF5B54E8),
      primaryLight: const Color(0xFF8F87FF),
      secondary: const Color(0xFF4ECDC4),
      accent: const Color(0xFFFF6584),
      solidBlack: const Color(0xFF000000),
      imageBackground: const Color(0xFFFFFFFF),
      onboardingBackground: const Color(0xFFF0F2FF),
      containerBG: const Color(0xFFFFFFFF),
      tileBG: const Color(0xFFF5F6FA),
      disabledText: const Color(0xFF9CA3AF),
      barchartBG: const Color(0xFFEFF0F6),
      transactionPage: const Color(0xFFF8F9FE),
      containerBG2: const Color(0xFFE5E7EB),
      secondaryBG: const Color(0xFFEEF0F8),
      primaryGrey: const Color(0xFF6B7280),
      secondaryGrey: const Color(0xFF374151),
      success: const Color(0xFF4CAF50),
      warning: const Color(0xFFFFA726),
      error: const Color(0xFFEF4444),
      info: const Color(0xFF3B82F6),
      disabled: const Color(0xFFD1D5DB),
      cardBackground: const Color(0xFFFFFFFF),
      subtitleText: const Color(0xFF6B7280),
      divider: const Color(0xFFE5E7EB),
      inputFill: const Color(0xFFF5F5F5),
      lostColor: const Color(0xFFE53935),
      foundColor: const Color(0xFF43A047),
      claimedColor: const Color(0xFF9E9E9E),
      navBackground: const Color(0xFF1A1F26),
      navActiveIcon: const Color(0xFFFFFFFF),
      navInactiveIcon: const Color(0xFF7C8186),
      fabBackground: const Color(0xFF4ECDC4),
    );
  }

  static AppColors data() => dark();

  static AppColors of(BuildContext context) =>
      Provider.of<AppThemeManager>(context, listen: false).colors;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF5B54E8)],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4ECDC4), Color(0xFF98D8C8)],
  );

  static const LinearGradient onboarding1Gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
  );

  static const LinearGradient onboarding2Gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
  );

  static const LinearGradient onboarding3Gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4ECDC4), Color(0xFF6C63FF)],
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x146C63FF), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(color: Color(0x404ECDC4), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> navShadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, -4)),
  ];
}
