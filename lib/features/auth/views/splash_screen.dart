import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../shared/widgets/neon_auth_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.goNamed(AppRoutes.onboardingName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: NeonAuthBackground(
        showWave: true,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(34, 22, 34, 18),
            child: Column(
              children: [
                Spacer(flex: 2),
                VaultShieldLogo(size: 132),
                SizedBox(height: 28),
                _BrandName(),
                SizedBox(height: 26),
                _Tagline(),
                SizedBox(height: 46),
                _CapabilityRow(),
                SizedBox(height: 54),
                NeonDots(length: 3, index: 1),
                SizedBox(height: 24),
                Text(
                  'L o a d i n g . . .',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 16,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Spacer(flex: 3),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Color(0xBFFFFFFF),
                    fontSize: 13,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Made with heart',
                  style: TextStyle(
                    color: Color(0xBFFFFFFF),
                    fontSize: 13,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandName extends StatelessWidget {
  const _BrandName();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        Text(
          'vault',
          style: TextStyle(
            color: Colors.white,
            fontSize: 50,
            fontWeight: FontWeight.w300,
            height: .95,
            letterSpacing: -1,
          ),
        ),
        GradientText(
          'One',
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.w600,
            height: .95,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text(
          'Secure Everything.',
          style: TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 18,
            letterSpacing: 4.2,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Access Anywhere.',
          style: TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 18,
            letterSpacing: 4.2,
          ),
        ),
      ],
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow();

  static const items = [
    (Icons.lock_outline_rounded, 'AES-256\nENCRYPTION', Color(0xFF8B39FF)),
    (Icons.document_scanner_outlined, 'OCR\nSCANNER', Color(0xFF1BD3FF)),
    (Icons.key_rounded, 'PASSWORD\nVAULT', Color(0xFF9F39FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in items) ...[
          Expanded(
            child: _CapabilityPill(
              icon: item.$1,
              label: item.$2,
              color: item.$3,
            ),
          ),
          if (item != items.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
                letterSpacing: .8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
