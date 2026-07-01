import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  int get _score {
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp('[A-Z]').hasMatch(password)) score++;
    if (RegExp('[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  String get _label {
    return switch (_score) {
      0 || 1 => 'Weak',
      2 => 'Fair',
      3 => 'Good',
      _ => 'Strong',
    };
  }

  Color get _color {
    return switch (_score) {
      0 || 1 => AppColors.danger,
      2 => AppColors.orange,
      3 => AppColors.blue,
      _ => AppColors.success,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Strength Indicator', style: AppTextStyles.label),
            ),
            Text(_label, style: AppTextStyles.label.copyWith(color: _color)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: _score / 4,
            minHeight: 10,
            color: _color,
            backgroundColor: AppColors.fieldBorder,
          ),
        ),
      ],
    );
  }
}
