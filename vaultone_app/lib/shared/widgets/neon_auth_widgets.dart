import 'package:flutter/material.dart';

import '../../constants/app_image.dart';

class NeonAuthBackground extends StatelessWidget {
  const NeonAuthBackground({
    super.key,
    required this.child,
    this.showWave = false,
  });

  final Widget child;
  final bool showWave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF020528), Color(0xFF050743), Color(0xFF01021A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _NeonBackgroundPainter()),
          ),
          if (showWave)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 82,
              height: 220,
              child: CustomPaint(painter: _NeonWavePainter()),
            ),
          child,
        ],
      ),
    );
  }
}

class VaultShieldLogo extends StatelessWidget {
  const VaultShieldLogo({super.key, this.size = 120, this.glass = true});

  final double size;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: glass
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size * .22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7048FF).withValues(alpha: .28),
                  blurRadius: size * .22,
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .22),
        child: Image.asset(
          AppImages.appLogo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => Icon(
            Icons.shield_rounded,
            size: size * .7,
            color: const Color(0xFF7B4DFF),
          ),
        ),
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [Color(0xFF18C9FF), Color(0xFF8E35FF)],
      ).createShader(rect),
      child: Text(
        text,
        textAlign: textAlign,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

class NeonDots extends StatelessWidget {
  const NeonDots({super.key, required this.length, required this.index});

  final int length;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: active ? 13 : 12,
          height: active ? 13 : 12,
          margin: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF1ED6FF), Color(0xFF9438FF)],
                  )
                : null,
            border: active
                ? null
                : Border.all(color: const Color(0xFF6756FF), width: 2),
            color: active ? null : Colors.transparent,
            boxShadow: active
                ? [const BoxShadow(color: Color(0xAA21CFFF), blurRadius: 14)]
                : null,
          ),
        );
      }),
    );
  }
}

class NeonButton extends StatelessWidget {
  const NeonButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF12C8FF), Color(0xFF9B20FF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F30FF).withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 18),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeonBackgroundPainter extends CustomPainter {
  const _NeonBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cyan = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF00D4FF).withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 1.03, size.height * 0.18),
              radius: size.width * 0.42,
            ),
          );
    final violet = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF8B26FF).withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(-size.width * 0.06, size.height * 0.35),
              radius: size.width * 0.36,
            ),
          );
    final blue = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF2148FF).withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.92, size.height * 0.75),
              radius: size.width * 0.48,
            ),
          );
    canvas
      ..drawRect(Offset.zero & size, cyan)
      ..drawRect(Offset.zero & size, violet)
      ..drawRect(Offset.zero & size, blue);

    final orbit = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.31),
      size.width * 0.48,
      orbit,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.50, size.height * 0.32),
        radius: size.width * 0.38,
      ),
      -1.1,
      3.9,
      false,
      orbit..color = const Color(0xFF4B5CFF).withValues(alpha: 0.18),
    );

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (final p in const [
      Offset(.12, .19),
      Offset(.28, .09),
      Offset(.58, .14),
      Offset(.90, .27),
      Offset(.22, .70),
      Offset(.78, .86),
      Offset(.50, .07),
    ]) {
      canvas.drawCircle(
        Offset(size.width * p.dx, size.height * p.dy),
        1.2,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeonWavePainter extends CustomPainter {
  const _NeonWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = const LinearGradient(
        colors: [Color(0xFF9A22FF), Color(0xFF12D7FF), Color(0xFF5A4DFF)],
      ).createShader(Offset.zero & size);
    final path = Path()..moveTo(0, size.height * .50);
    path.cubicTo(
      size.width * .20,
      size.height * .18,
      size.width * .34,
      size.height * .86,
      size.width * .52,
      size.height * .56,
    );
    path.cubicTo(
      size.width * .67,
      size.height * .30,
      size.width * .78,
      size.height * .62,
      size.width,
      size.height * .26,
    );
    canvas.drawPath(path, line);

    final dot = Paint()..color = const Color(0xFF31D2FF).withValues(alpha: .70);
    for (var row = 0; row < 42; row++) {
      final y = size.height * .40 + row * 5.0;
      for (var col = 0; col < 70; col++) {
        final x = col * (size.width / 69);
        final wave = (row / 42) * 34 + 14 * (0.5 - (col % 9) / 9).abs();
        canvas.drawCircle(
          Offset(x, y + wave),
          0.75,
          dot
            ..color = (col + row).isEven
                ? const Color(0xFF29CFFF).withValues(alpha: .46)
                : const Color(0xFF9A2DFF).withValues(alpha: .42),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
