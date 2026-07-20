import 'package:flutter/material.dart';

class AuthConstants {
  const AuthConstants._();

  static const splashDelay = Duration(milliseconds: 1500);
  static const splashAnimationDuration = Duration(milliseconds: 650);
  static const otpTick = Duration(seconds: 1);
  static const requestTimeout = Duration(seconds: 15);
  static const onboardingCompletedKey = 'onboarding_completed';

  static const screenPadding = EdgeInsets.fromLTRB(12, 10, 12, 20);
  static const cardPadding = EdgeInsets.all(16);
  static const fieldGap = 12.0;

  static const headingColor = Color(0xFF101828);
  static const mutedColor = Color(0xFF667085);
  static const errorColor = Color(0xFFDC2626);
  static const primaryBlue = Color(0xFF2457E6);

  static final uppercasePattern = RegExp(r'[A-Z]');
  static final digitPattern = RegExp(r'\d');
  static final specialCharacterPattern = RegExp(r'[^A-Za-z0-9]');

  static bool isStrongPassword(String value) {
    return value.length >= 8 &&
        uppercasePattern.hasMatch(value) &&
        digitPattern.hasMatch(value) &&
        specialCharacterPattern.hasMatch(value);
  }
}
