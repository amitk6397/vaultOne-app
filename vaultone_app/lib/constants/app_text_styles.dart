import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get heading => GoogleFonts.inter(
    color: AppColors.navy,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.18,
  );

  static TextStyle get heroHeading => GoogleFonts.inter(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.18,
  );

  static TextStyle get body => GoogleFonts.inter(
    color: AppColors.textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static TextStyle get label => GoogleFonts.inter(
    color: AppColors.navy,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  static TextStyle get button => GoogleFonts.inter(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  static TextStyle get link => GoogleFonts.inter(
    color: AppColors.blue,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );
}
