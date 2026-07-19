import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const scaffold = Color(0xFFF7F6F2);
  static const navy = Color(0xFF071943);
  static const textMuted = Color(0xFF687492);
  static const fieldBorder = Color(0xFFE0E5EF);
  static const fieldFill = Colors.white;
  static const blue = Color(0xFF0D6EFF);
  static const indigo = Color(0xFF1327A8);
  static const purple = Color(0xFF653CF2);
  static const orange = Color(0xFFFF9F0A);
  static const cyan = Color(0xFF20A9C8);
  static const mint = Color(0xFFE2FAF4);
  static const success = Color(0xFF16B46F);
  static const danger = Color(0xFFE84A5F);
  static const shadow = Color(0x1A071943);

  static const primaryGradient = LinearGradient(
    colors: [blue, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const darkHeroGradient = LinearGradient(
    colors: [Color(0xFF122EBC), Color(0xFF07115D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
