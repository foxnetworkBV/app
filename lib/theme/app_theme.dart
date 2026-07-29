import 'package:flutter/material.dart';

class FoxColors {
  static const orange = Color(0xFFEA5411);
  static const orangeDark = Color(0xFFC94308);
  static const navy = Color(0xFF0F1A30);
  static const ink = Color(0xFF3F3D59);
  static const muted = Color(0xFF526489);
  static const blue = Color(0xFF1886EB);
  static const page = Color(0xFFF7F6F8);
  static const surface = Colors.white;
  static const border = Color(0xFFE9E6EC);
  static const success = Color(0xFF24A36A);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, orangeDark],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: FoxColors.orange,
      brightness: Brightness.light,
      primary: FoxColors.orange,
      secondary: FoxColors.blue,
      surface: FoxColors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: FoxColors.page,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: FoxColors.page,
        foregroundColor: FoxColors.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: FoxColors.navy),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: FoxColors.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: FoxColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: FoxColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: FoxColors.orange, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: FoxColors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      )),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: FoxColors.orange.withValues(alpha: .12),
        labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(color: states.contains(WidgetState.selected) ? FoxColors.orange : FoxColors.muted)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: FoxColors.orange.withValues(alpha: .12),
        side: const BorderSide(color: FoxColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dividerColor: FoxColors.border,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: FoxColors.navy, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(color: FoxColors.navy, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: FoxColors.ink, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: FoxColors.ink),
        bodyMedium: TextStyle(color: FoxColors.muted),
      ),
    );
  }
}
