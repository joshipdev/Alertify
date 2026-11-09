import 'dart:math';
import 'package:flutter/material.dart';
import 'device_service.dart';
import 'theme.dart';

/// Simulated live CCTV feed (drawn in code, no network or assets required).
/// Replace the CustomPaint with an MJPEG / RTSP player to show a real camera.
class CameraView extends StatefulWidget {
  final double? height;
  final bool showExpand;
  const CameraView({super.key, this.height, this.showExpand = false});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _stamp() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final view = ListenableBuilder(
      listenable: Listenable.merge([_c, device]),
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ScenePainter(
                t: _c.value,
                motion: device.motionActive,
                online: device.cameraOnline,
                night: device.nightVision,
              ),
            ),
            if (device.cameraOnline) ...[
              Positioned(
                left: 10,
                top: 10,
                child: _badge(
                  const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, size: 9, color: AppColors.red),
                    SizedBox(width: 5),
                    Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ]),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 8,
                child: Text('CAM 1 - Front Door\n${_stamp()}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        height: 1.3)),
              ),
              Positioned(
                right: 10,
                bottom: 8,
                child: Text('${device.battery}%',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'monospace')),
              ),
            ],
            if (widget.showExpand)
              const Positioned(
                right: 10,
                top: 10,
                child: Icon(Icons.open_in_full, color: Colors.white70, size: 18),
              ),
          ],
        );
      },
    );

    if (widget.height != null) {
      return SizedBox(height: widget.height, width: double.infinity, child: view);
    }
    return SizedBox.expand(child: view);
  }

  Widget _badge(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
}

class _ScenePainter extends CustomPainter {
  final double t;
  final bool motion;
  final bool online;
  final bool night;

  _ScenePainter({
    required this.t,
    required this.motion,
    required this.online,
    required this.night,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    if (!online) {
      canvas.drawRect(rect, Paint()..color = const Color(0xFF111827));
      final tp = TextPainter(
        text: const TextSpan(
            text: 'Camera offline',
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((w - tp.width) / 2, (h - tp.height) / 2));
      return;
    }

    // Sky
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night
              ? const [Color(0xFF0B1B3A), Color(0xFF2B4A7F)]
              : const [Color(0xFF5B8FD6), Color(0xFFBBD4F2)],
        ).createShader(rect),
    );

    // Ground
    final groundTop = h * 0.66;
    canvas.drawRect(
      Rect.fromLTRB(0, groundTop, w, h),
      Paint()..color = const Color(0xFF3A4254),
    );
    // Driveway
    final drive = Path()
      ..moveTo(w * 0.40, groundTop)
      ..lineTo(w * 0.60, groundTop)
      ..lineTo(w * 0.85, h)
      ..lineTo(w * 0.15, h)
      ..close();
    canvas.drawPath(drive, Paint()..color = const Color(0xFF59627A));

    // Trees
    final tree = Paint()..color = const Color(0xFF123524);
    for (final x in [0.06, 0.14, 0.9, 0.96]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(w * x, groundTop - h * 0.08),
              width: w * 0.12,
              height: h * 0.38),
          tree);
    }

    // House body
    final body = Rect.fromLTRB(w * 0.24, h * 0.34, w * 0.76, groundTop);
    canvas.drawRect(body, Paint()..color = const Color(0xFFD9DEE8));
    // Upper block
    final upper = Rect.fromLTRB(w * 0.36, h * 0.2, w * 0.7, h * 0.36);
    canvas.drawRect(upper, Paint()..color = const Color(0xFFE6EAF2));
    // Roofs
    final roof = Paint()..color = const Color(0xFF2A2F3C);
    canvas.drawRect(
        Rect.fromLTRB(w * 0.22, h * 0.31, w * 0.78, h * 0.345), roof);
    canvas.drawRect(
        Rect.fromLTRB(w * 0.34, h * 0.18, w * 0.72, h * 0.205), roof);

    // Windows (lit)
    final glow = Paint()..color = const Color(0xFFFFD36B);
    final win = <Rect>[
      Rect.fromLTWH(w * 0.28, h * 0.42, w * 0.08, h * 0.14),
      Rect.fromLTWH(w * 0.39, h * 0.42, w * 0.08, h * 0.14),
      Rect.fromLTWH(w * 0.54, h * 0.42, w * 0.08, h * 0.14),
      Rect.fromLTWH(w * 0.65, h * 0.42, w * 0.07, h * 0.14),
      Rect.fromLTWH(w * 0.42, h * 0.24, w * 0.07, h * 0.09),
      Rect.fromLTWH(w * 0.55, h * 0.24, w * 0.07, h * 0.09),
    ];
    for (final r in win) {
      canvas.drawRect(r, glow);
    }
    // Door
    canvas.drawRect(
        Rect.fromLTWH(w * 0.485, h * 0.5, w * 0.05, groundTop - h * 0.5),
        Paint()..color = const Color(0xFF3B3F4F));

    // Moving person when motion is active
    if (motion) {
      final px = w * (0.05 + 0.9 * t);
      final base = h * 0.9;
      final sway = sin(t * pi * 24) * 4;
      final skin = Paint()..color = const Color(0xFF111111);
      canvas.drawCircle(Offset(px, base - h * 0.34), h * 0.035, skin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(px, base - h * 0.21),
              width: w * 0.05,
              height: h * 0.2),
          const Radius.circular(6),
        ),
        skin,
      );
      canvas.drawLine(Offset(px - 4, base - h * 0.11),
          Offset(px - 4 + sway, base), skin..strokeWidth = 5);
      canvas.drawLine(Offset(px + 4, base - h * 0.11),
          Offset(px + 4 - sway, base), skin..strokeWidth = 5);

      final box = Rect.fromLTRB(
          px - w * 0.05, base - h * 0.4, px + w * 0.05, base + 2);
      canvas.drawRect(
        box,
        Paint()
          ..color = AppColors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tp = TextPainter(
        text: const TextSpan(
            text: 'MOTION',
            style: TextStyle(
                color: AppColors.red, fontSize: 10, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(box.left, box.top - 13));
    }

    // CCTV scanlines
    final scan = Paint()..color = Colors.black.withValues(alpha: 0.06);
    for (double y = 0; y < h; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, w, 1.5), scan);
    }
    // Vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => true;
}
