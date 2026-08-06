import 'package:flutter/material.dart';

class FoxColors {
  static const navy950 = Color(0xFF050C18);
  static const navy900 = Color(0xFF08111F);
  static const navy800 = Color(0xFF0D1A2C);
  static const navy700 = Color(0xFF12243A);
  static const cyan = Color(0xFF2ED4F4);
  static const cyanBright = Color(0xFF53E4FF);
  static const blue = Color(0xFF1597D4);
  static const border = Color(0xFF20344D);
  static const success = Color(0xFF55D68B);
  static const warning = Color(0xFFFFB85C);
  static const danger = Color(0xFFFF6B7A);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanBright, cyan, blue],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: FoxColors.cyan,
      brightness: Brightness.dark,
      surface: FoxColors.navy800,
    ).copyWith(
      primary: FoxColors.cyan,
      secondary: FoxColors.cyanBright,
      surface: FoxColors.navy800,
      error: FoxColors.danger,
      outline: FoxColors.border,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: FoxColors.navy900,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: FoxColors.navy900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: FoxColors.navy800,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: FoxColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: FoxColors.border,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FoxColors.navy800,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIconColor: FoxColors.cyan,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FoxColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FoxColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FoxColors.cyan, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FoxColors.cyan,
          foregroundColor: FoxColors.navy950,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FoxColors.cyan,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: FoxColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FoxColors.navy700,
        side: const BorderSide(color: FoxColors.border),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FoxColors.navy800,
        indicatorColor: FoxColors.cyan.withValues(alpha: 0.16),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? FoxColors.cyan
                : Colors.white60,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? FoxColors.cyan
                : Colors.white60,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FoxColors.cyan,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FoxColors.cyan,
        foregroundColor: FoxColors.navy950,
      ),
    );
  }
}
