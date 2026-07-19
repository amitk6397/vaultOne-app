import 'package:flutter/material.dart';

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
    final colors = Theme.of(context).colorScheme;
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
            style: AppTextStyles.body.copyWith(color: colors.onSurface),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.surface,
              hintText: hint,
              hintStyle: AppTextStyles.body,
              prefixIcon: Icon(icon, color: colors.onSurfaceVariant),
              prefix: prefix,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              enabledBorder: _border(colors.outlineVariant),
              focusedBorder: _border(colors.primary),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius),
      borderSide: BorderSide(color: color),
    );
  }
}
