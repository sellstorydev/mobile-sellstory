import 'package:flutter/material.dart';
import '../constants/app_font.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryOrange = Color(0xFFFF6A00);
  static const Color secondaryOrange = Color(0xFFE55A00);
  static const Color gradientStart = Color(0xFFFF7A00);
  static const Color gradientEnd = Color(0xFFFF3D00);
  
  // Figma Design Colors
  static const Color figmaOrange = Color(0xFFFF6C0C);
  static const Color figmaRed = Color(0xFFFF3312);
  static const Color figmaYellow = Color(0xFFFAB73F);
  static const Color figmaPink = Color(0xFFFF92A6);
  static const Color figmaBlue = Color(0xFF2151C5);
  static const Color figmaLightBlue = Color(0xFF3C8BE9);
  static const Color figmaGreen = Color(0xFF349466);
  static const Color figmaTeal = Color(0xFF4CA0A0);
  static const Color figmaPurple = Color(0xFFDE2FAD);
  static const Color figmaGold = Color(0xFFB6A617);
  static const Color figmaLightGold = Color(0xFFF6C517);
  
  // Enhanced Brand Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryPurple = Color(0xFF9C27B0);
  
  // Header Gradient
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );
  
  // Status Bar Gradient
  static const LinearGradient statusBarGradient = LinearGradient(
    begin: Alignment(1.00, 1.00),
    end: Alignment(-0.00, -0.03),
    colors: [figmaRed, figmaOrange],
  );
  
  // Logo Gradient
  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment(1.00, 1.00),
    end: Alignment(-0.00, -0.03),
    colors: [Color(0xFFFF0000), figmaOrange],
  );
  
  // FAB Gradient
  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment(0.50, -0.00),
    end: Alignment(0.50, 1.00),
    colors: [figmaRed, figmaOrange],
  );
  
  // Background Colors
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  static const Color laneBackground = Color(0xFFFFF0E7);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textGrey = Color(0xFF999999);
  static const Color textLightGrey = Color(0xFFCCCCCC);
  static const Color textDark = Color(0xFF333333);
  static const Color textMedium = Color(0xFF4D4D4D);
  
  // Border Colors
  static const Color borderGrey = Color(0xFFE0E0E0);
  static const Color borderLightGrey = Color(0xFFF0F0F0);
  
  // Button Colors
  static const Color buttonDisabled = Color(0xFFE0E0E0);
  static const Color buttonDisabledText = Color(0xFF999999);
  
  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
  static const Color warningYellow = Color(0xFFFF9800);
  static const Color infoBlue = Color(0xFF2196F3);
  
  // Shadow Colors
  static const Color shadowColor = Color(0x19000000);
  static const Color fabShadowColor = Color(0x4CFB3327);
  
  // Font Sizes
  static const double fontSize8 = 8.0;
  static const double fontSize10 = 10.0;
  static const double fontSize11 = 11.0;
  static const double fontSize12 = 12.0;
  static const double fontSize14 = 14.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize24 = 24.0;
  static const double fontSize28 = 28.0;
  static const double fontSize32 = 32.0;
  
  // Spacing
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing28 = 28.0;
  
  // Border Radius
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius60 = 60.0;
  static const double radius120 = 120.0;
  
  // Icon Sizes
  static const double iconSize12 = 12.0;
  static const double iconSize14 = 14.0;
  static const double iconSize16 = 16.0;
  static const double iconSize20 = 20.0;
  static const double iconSize24 = 24.0;
  static const double iconSize28 = 28.0;
  
  // Container Sizes
  static const double statusBarHeight = 44.0;
  static const double headerHeight = 60.0;
  static const double bottomNavHeight = 80.0;
  static const double fabSize = 48.0;
  static const double fabMargin = 16.0;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      colorSchemeSeed: primaryOrange,
      scaffoldBackgroundColor: backgroundWhite,
      fontFamily: AppFont.family,

      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: buttonDisabled,
          disabledForegroundColor: buttonDisabledText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius8),
          ),
          padding: const EdgeInsets.symmetric(vertical: spacing16),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundWhite,
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderGrey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius8),
          ),
          padding: const EdgeInsets.symmetric(vertical: spacing16),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryOrange,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius8),
          borderSide: const BorderSide(color: borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius8),
          borderSide: const BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius8),
          borderSide: const BorderSide(color: primaryOrange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius8),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
        hintStyle: const TextStyle(color: textGrey),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize14,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize12,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize12,
          color: textSecondary,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: iconSize24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: borderLightGrey,
        thickness: 1,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorSchemeSeed: primaryOrange,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: AppFont.family,
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF424242),
          disabledForegroundColor: const Color(0xFF757575),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius8),
          ),
          padding: const EdgeInsets.symmetric(vertical: spacing16),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF424242)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius8),
          ),
          padding: const EdgeInsets.symmetric(vertical: spacing16),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryOrange,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius8),
          borderSide: const BorderSide(color: primaryOrange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius8),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
        hintStyle: const TextStyle(color: Color(0xFF757575)),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFBDBDBD),
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize14,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize12,
          color: Color(0xFFBDBDBD),
        ),
        labelLarge: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelSmall: TextStyle(
          fontFamily: AppFont.family,
          fontSize: fontSize12,
          color: Color(0xFFBDBDBD),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFFBDBDBD),
        size: iconSize24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
      ),
    );
  }
}
