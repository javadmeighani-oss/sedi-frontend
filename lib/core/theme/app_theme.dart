import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF9BCF88); // سبز پسته‌ای
  static const Color backgroundWhite = Colors.white;
  static const Color softGray = Color(0xFFF2F2F2); // خاکستری روشن متال
  static const Color textBlack = Colors.black;

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundWhite,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: softGray,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontSize: 16,
        color: textBlack,
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        color: textBlack,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: softGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
