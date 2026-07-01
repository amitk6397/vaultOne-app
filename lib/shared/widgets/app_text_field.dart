import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefix,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 10),
        SizedBox(
          height: AppSizes.fieldHeight,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: AppTextStyles.body.copyWith(color: AppColors.navy),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.fieldFill,
              hintText: hint,
              hintStyle: AppTextStyles.body,
              prefixIcon: Icon(icon, color: AppColors.textMuted),
              prefix: prefix,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              enabledBorder: _border(),
              focusedBorder: _border(AppColors.blue),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border([Color color = AppColors.fieldBorder]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius),
      borderSide: BorderSide(color: color),
    );
  }
}
