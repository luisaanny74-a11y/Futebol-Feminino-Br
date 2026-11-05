import 'package:flutter/material.dart';

/// Paleta inspirada na referência de 3 telas (fundo escuro + verde-limão).
class AppColors {
  static const bg = Color(0xFF0A0D0B);
  static const surface = Color(0xFF121712);
  static const surfaceHigh = Color(0xFF1A211A);
  static const lime = Color(0xFFC6F432);
  static const limeDim = Color(0xFF4A5A1C);
  static const text = Color(0xFFEFF3EA);
  static const textMuted = Color(0xFF93A08C);
  static const danger = Color(0xFFFF6B6B);
}

/// Forma com cantos chanfrados e contorno fino, como os cartões da referência.
BeveledRectangleBorder chamfer({double radius = 14, Color? border, double width = 1}) =>
    BeveledRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: border ?? AppColors.limeDim, width: width),
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.lime,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.lime,
    onPrimary: Colors.black,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.lime,
      foregroundColor: Colors.black,
      shape: chamfer(radius: 14, border: AppColors.lime),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: Colors.black,
        shape: chamfer(radius: 10, border: AppColors.lime),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.lime),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.lime,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? Colors.black : AppColors.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected) ? AppColors.lime : AppColors.textMuted,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.lime,
      selectedIconTheme: IconThemeData(color: Colors.black),
      unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
      selectedLabelTextStyle:
          TextStyle(color: AppColors.lime, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: AppColors.textMuted),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: chamfer(radius: 18),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.limeDim),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.limeDim),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.lime, width: 1.6),
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: const TextStyle(color: AppColors.text),
      shape: chamfer(radius: 10),
    ),
  );
}
