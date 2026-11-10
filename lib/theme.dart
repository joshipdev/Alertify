import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF0F2A5E);
  static const blue = Color(0xFF2F6FDB);
  static const lightBlue = Color(0xFF6FA3F2);
  static const bg = Color(0xFFF3F6FC);
  static const border = Color(0xFFD6E0F2);
  static const green = Color(0xFF2E9E4F);
  static const red = Color(0xFFE53935);
  static const orange = Color(0xFFF59E0B);
  static const grey = Color(0xFF6B7280);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
    scaffoldBackgroundColor: Colors.white,
  );
}

class AlertifyLogo extends StatelessWidget {
  final double size;

  const AlertifyLogo({
    super.key,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/branding/alertify_mark.png',
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  final double heightFactor;
  WavePainter(this.color, {this.heightFactor = 0.45});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * heightFactor)
      ..cubicTo(size.width * 0.3, 0, size.width * 0.6, size.height * 0.9,
          size.width, size.height * 0.25)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant WavePainter old) => old.color != color;
}
