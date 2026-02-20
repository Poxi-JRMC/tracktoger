import 'package:flutter/material.dart';

class AppColors {
  // GEROTRACK Industrial Colors
  static const gerotrackBlack = Color(0xFF1A1A1A);
  static const gerotrackYellow = Color(0xFFFFDD00);
  static const gerotrackYellowBright = Color(0xFFFFFF00);
  static const gerotrackGray = Color(0xFF6B7280);
  static const gerotrackGrayDark = Color(0xFF374151);
  static const gerotrackGrayLight = Color(0xFFF3F4F6);
  static const gerotrackGrayMetallic = Color(0xFF8B949E);
  static const gerotrackSuccess = Color(0xFF059669);
  static const gerotrackWarning = Color(0xFFF59E0B);
  static const gerotrackDanger = Color(0xFFDC2626);
  static const gerotrackIndustrialBlue = Color(0xFF1E40AF);

  // Gradientes industriales
  static const industrialGradient = LinearGradient(
    colors: [gerotrackBlack, gerotrackGrayDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const industrialYellowGradient = LinearGradient(
    colors: [gerotrackYellow, gerotrackYellowBright],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const metallicGradient = LinearGradient(
    colors: [gerotrackGrayMetallic, gerotrackGray],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.gerotrackYellow,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w500), // h1
      displayMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500), // h2
      displaySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500), // h3
      headlineMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ), // h4
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400), // p
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ), // input, labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ), // botones
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.gerotrackYellow,
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w500), // h1
      displayMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500), // h2
      displaySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500), // h3
      headlineMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ), // h4
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400), // p
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ), // input, labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ), // botones
    ),
  );
}
