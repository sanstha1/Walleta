import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:walleta/theme/app_colors.dart';

class AppTheme {
  static ThemeData dark(AppColors c) {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: c.backgroundColor,
      primaryColor: c.primary,
      colorScheme: ColorScheme.dark(
        primary: c.primary,
        secondary: c.secondary,
        surface: c.containerBG,
        onSurface: c.primaryText,
        error: c.error,
      ),
      cardColor: c.cardBackground,
      dividerColor: c.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: c.backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: c.primaryText),
        titleTextStyle: TextStyle(
          color: c.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.navBackground,
        selectedItemColor: c.navActiveIcon,
        unselectedItemColor: c.navInactiveIcon,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.fabBackground,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputFill,
        hintStyle: TextStyle(color: c.subtitleText, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.containerBG2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.containerBG2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.tileBG,
        selectedColor: c.primary,
        labelStyle: TextStyle(color: c.primaryText, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: c.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
        displayMedium: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        displaySmall: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        headlineLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        headlineMedium: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        headlineSmall: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleMedium: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        titleSmall: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        bodyLarge: TextStyle(color: c.primaryText, fontSize: 16),
        bodyMedium: TextStyle(color: c.primaryText, fontSize: 14),
        bodySmall: TextStyle(color: c.subtitleText, fontSize: 12),
        labelLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelMedium: TextStyle(color: c.subtitleText, fontSize: 12),
        labelSmall: TextStyle(color: c.subtitleText, fontSize: 11),
      ),
    );
  }

  static ThemeData light(AppColors c) {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: c.backgroundColor,
      primaryColor: c.primary,
      colorScheme: ColorScheme.light(
        primary: c.primary,
        secondary: c.secondary,
        surface: c.containerBG,
        onSurface: c.primaryText,
        error: c.error,
      ),
      cardColor: c.cardBackground,
      dividerColor: c.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: c.backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: c.primaryText),
        titleTextStyle: TextStyle(
          color: c.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.navBackground,
        selectedItemColor: c.navActiveIcon,
        unselectedItemColor: c.navInactiveIcon,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.fabBackground,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputFill,
        hintStyle: TextStyle(color: c.subtitleText, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.containerBG2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.containerBG2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.tileBG,
        selectedColor: c.primary,
        labelStyle: TextStyle(color: c.primaryText, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: c.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
        displayMedium: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        displaySmall: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        headlineLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        headlineMedium: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        headlineSmall: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleMedium: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        titleSmall: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        bodyLarge: TextStyle(color: c.primaryText, fontSize: 16),
        bodyMedium: TextStyle(color: c.primaryText, fontSize: 14),
        bodySmall: TextStyle(color: c.subtitleText, fontSize: 12),
        labelLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelMedium: TextStyle(color: c.subtitleText, fontSize: 12),
        labelSmall: TextStyle(color: c.subtitleText, fontSize: 11),
      ),
    );
  }
}
