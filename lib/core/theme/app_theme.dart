import 'package:flutter/material.dart';

class AppTheme {
  // رنگ سازمانی: سبز پسته‌ای
  static const Color pistachioGreen = Color(0xFF9BCF88);
  
  // رنگ‌های متال
  static const Color metalGray = Color(0xFFB0B0B0); // خاکستری متال
  static const Color metalLight = Color(0xFFE8E8E8); // خاکستری روشن متال
  
  // رنگ‌های پایه
  static const Color backgroundWhite = Colors.white;
  static const Color textBlack = Colors.black;
  static const Color textBlack87 = Color(0xDD000000);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundWhite,
    primaryColor: pistachioGreen,
    colorScheme: const ColorScheme.light(
      primary: pistachioGreen,
      secondary: metalGray,
      surface: backgroundWhite,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontSize: 16,
        color: textBlack,
        fontWeight: FontWeight.w400,
        fontFamily: 'Roboto',
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        color: textBlack,
        fontWeight: FontWeight.w500,
        fontFamily: 'Roboto',
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        color: textBlack87,
        fontWeight: FontWeight.w400,
        fontFamily: 'Roboto',
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: backgroundWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide(
          color: metalGray,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide(
          color: metalGray,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide(
          color: pistachioGreen,
          width: 2,
        ),
      ),
    ),
  );
}
