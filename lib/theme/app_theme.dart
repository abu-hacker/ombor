import 'package:flutter/material.dart';

class AppTheme {
  static const Color seed = Color(0xFF2563EB);
  static const Color okColor = Color(0xFF2E9E5B);
  static const Color lowColor = Color(0xFFE59A0B);
  static const Color outColor = Color(0xFFE5484D);
  static const Color okBg = Color(0x1F2E9E5B);
  static const Color lowBg = Color(0x24E59A0B);
  static const Color outBg = Color(0x1FE5484D);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor:
          b == Brightness.light ? const Color(0xFFF5F7FB) : const Color(0xFF0F1115),
    );
  }
}
