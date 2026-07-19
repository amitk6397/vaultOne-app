import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../routes/app_routes.dart';
import 'neon_auth_widgets.dart';
import 'app_loading_indicator.dart';
import '../../constants/auth_constants.dart';

class LightAuthShell extends StatelessWidget {
  const LightAuthShell({
    super.key,
    required this.children,
    this.showBack = true,
  });

  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F8FF), Colors.white, Color(0xFFF4F8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _SoftBgPainter()),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: AuthConstants.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBack)
                      _BackButton(
                        onTap: () => context.goNamed(AppRoutes.loginName),
                      )
                    else
                      const SizedBox(height: 8),
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key, this.center = false, this.logoSize = 88});

  final bool center;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        VaultShieldLogo(size: logoSize, glass: false),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'vault',
              style: AppTextStyles.heading.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w400,
                height: .95,
              ),
            ),
            GradientText(
              'One',
              style: AppTextStyles.heading.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                height: .95,
              ),
            ),
          ],
        ),
      ],
    );
    return center ? Center(child: child) : child;
  }
}

class AuthHeroArt extends StatelessWidget {
  const AuthHeroArt({super.key, required this.kind, this.height = 220});

  final AuthHeroKind kind;
  final double height;

  @override
  Widget build(BuildContext context) {
    final safeIcon = kind == AuthHeroKind.register
        ? Icons.inventory_2_rounded
        : Icons.phone_iphone_rounded;
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: height * .95,
            height: height * .85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEDEAFF).withValues(alpha: .8),
            ),
          ),
          Icon(
            safeIcon,
            size: kind == AuthHeroKind.register ? height * .72 : height * .82,
            color: const Color(0xFF7564F7),
            shadows: const [Shadow(color: Color(0x55735CFF), blurRadius: 22)],
          ),
          if (kind == AuthHeroKind.login || kind == AuthHeroKind.forgot)
            Positioned(
              top: height * .28,
              child: Icon(
                Icons.lock_rounded,
                size: height * .32,
                color: const Color(0xFF6F52FF),
              ),
            ),
          if (kind == AuthHeroKind.otp)
            Positioned(
              top: height * .30,
              child: Icon(
                Icons.sms_rounded,
                size: height * .38,
                color: const Color(0xFF6F52FF),
              ),
            ),
          if (kind == AuthHeroKind.register)
            Positioned(
              left: height * .18,
              bottom: height * .20,
              child: Icon(
                Icons.verified_user_rounded,
                size: height * .34,
                color: const Color(0xFF3C78FF),
              ),
            ),
          Positioned(
            right: height * .14,
            bottom: height * .14,
            child: Icon(
              Icons.mail_rounded,
              size: height * .30,
              color: const Color(0xFF9B67FF),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.child,
    this.padding = AuthConstants.cardPadding,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: const Color(0xFFEDEAF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6454C8).withValues(alpha: .10),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthInput extends StatelessWidget {
  const AuthInput({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLength,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 13)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: AppTextStyles.body.copyWith(
              color: const Color(0xFF9CA3AF),
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.fieldFill,
            prefixIcon: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.purple, size: 20),
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.purple),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
          ),
        ),
      ],
    );
  }
}

class GradientAuthButton extends StatelessWidget {
  const GradientAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6E42FF).withValues(alpha: .25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLoadingIndicator(size: 25),
                    if (loadingLabel != null) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          loadingLabel!,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.button.copyWith(fontSize: 15),
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 19),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 22),
                  ],
                ),
        ),
      ),
    );
  }
}

class DividerText extends StatelessWidget {
  const DividerText(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: Color(0xFFE7E4EF))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(text, style: AppTextStyles.body.copyWith(fontSize: 14)),
      ),
      const Expanded(child: Divider(color: Color(0xFFE7E4EF))),
    ],
  );
}

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onPressed,
  });
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE8E5EF)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon == null
            ? const Text(
                'G',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4285F4),
                ),
              )
            : Icon(icon, size: 27, color: color ?? Colors.black),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class BottomAuthLink extends StatelessWidget {
  const BottomAuthLink({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });
  final String text;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E4F2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF2F3340),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              action,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.link.copyWith(
                color: AppColors.purple,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_rounded, color: AppColors.purple),
        ],
      ),
    ),
  );
}

class SecurityStrip extends StatelessWidget {
  const SecurityStrip({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF1EEFF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const VaultShieldLogo(size: 42, glass: false),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    ),
  );
}

class BottomSafeArt extends StatelessWidget {
  const BottomSafeArt({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 112,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 8,
          child: Icon(
            Icons.inventory_2_rounded,
            color: Color(0xFFC7B9FF),
            size: 94,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Icon(
            Icons.donut_large_rounded,
            color: Color(0xFF6E67C8),
            size: 40,
          ),
        ),
        Positioned(
          right: 82,
          bottom: 20,
          child: Icon(
            Icons.description_rounded,
            color: Color(0xFFDCD5FF),
            size: 58,
          ),
        ),
        Positioned(
          right: 50,
          bottom: 22,
          child: Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF7FBBE8),
            size: 46,
          ),
        ),
        Positioned(
          right: 24,
          bottom: 16,
          child: Icon(Icons.lock_rounded, color: Color(0xFF8E65FF), size: 34),
        ),
      ],
    ),
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7D6DCA).withValues(alpha: .13),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: IconButton(
      onPressed: onTap,
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 20,
        color: Color(0xFF111827),
      ),
    ),
  );
}

class _SoftBgPainter extends CustomPainter {
  const _SoftBgPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFBDEBFF).withValues(alpha: .55),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(0, size.height * .05),
              radius: size.width * .55,
            ),
          );
    final purple = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFD5C7FF).withValues(alpha: .50),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width, size.height * .08),
              radius: size.width * .50,
            ),
          );
    canvas.drawRect(Offset.zero & size, blue);
    canvas.drawRect(Offset.zero & size, purple);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum AuthHeroKind { login, register, forgot, otp }
