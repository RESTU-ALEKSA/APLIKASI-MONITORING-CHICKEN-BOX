import 'package:flutter/material.dart';

class KandangLogo extends StatelessWidget {
  final double size;
  final double borderWidth;

  const KandangLogo({
    Key? key,
    this.size = 100,
    this.borderWidth = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: KandangLogoPainter(borderWidth: borderWidth),
      ),
    );
  }
}

class KandangLogoPainter extends CustomPainter {
  final double borderWidth;

  KandangLogoPainter({required this.borderWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFA500)
      ..style = PaintingStyle.fill;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw base (foundation)
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.85)
        ..lineTo(size.width, size.height * 0.85)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      paint,
    );

    // Draw left wall
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.15, size.height * 0.85)
        ..lineTo(size.width * 0.15, size.height * 0.2)
        ..lineTo(size.width * 0.35, size.height * 0.05)
        ..lineTo(size.width * 0.35, size.height * 0.85)
        ..close(),
      paint,
    );

    // Draw right wall
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.65, size.height * 0.85)
        ..lineTo(size.width * 0.65, size.height * 0.05)
        ..lineTo(size.width * 0.85, size.height * 0.2)
        ..lineTo(size.width * 0.85, size.height * 0.85)
        ..close(),
      paint,
    );

    // Draw roof left side
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.35, size.height * 0.05)
        ..lineTo(size.width * 0.5, size.height * 0.02)
        ..lineTo(size.width * 0.5, size.height * 0.25)
        ..lineTo(size.width * 0.35, size.height * 0.15)
        ..close(),
      paint,
    );

    // Draw roof right side
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.02)
        ..lineTo(size.width * 0.65, size.height * 0.05)
        ..lineTo(size.width * 0.65, size.height * 0.15)
        ..lineTo(size.width * 0.5, size.height * 0.25)
        ..close(),
      paint,
    );

    // Draw antenna
    const antennaStartX = 0.75;
    const antennaStartY = 0.08;
    
    // Antenna curve 1
    final antennaPaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // First antenna curve
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.88, size.height * 0.15),
        width: size.width * 0.25,
        height: size.height * 0.25,
      ),
      -2.8,
      1.2,
      false,
      antennaPaint,
    );

    // Second antenna curve
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.92, size.height * 0.2),
        width: size.width * 0.32,
        height: size.height * 0.32,
      ),
      -2.8,
      1.2,
      false,
      antennaPaint,
    );

    // Third antenna curve
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.96, size.height * 0.25),
        width: size.width * 0.38,
        height: size.height * 0.38,
      ),
      -2.8,
      1.2,
      false,
      antennaPaint,
    );

    // Draw white border/inner frame
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Inner rectangle
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.25, size.height * 0.2)
        ..lineTo(size.width * 0.75, size.height * 0.2)
        ..lineTo(size.width * 0.75, size.height * 0.8)
        ..lineTo(size.width * 0.25, size.height * 0.8)
        ..close(),
      innerPaint,
    );

    // Draw chicken/ayam
    _drawChicken(canvas, centerX, centerY * 1.1, whitePaint, size);
  }

  void _drawChicken(Canvas canvas, double centerX, double centerY, Paint paint, Size size) {
    // Chicken body (oval)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size.width * 0.25,
        height: size.height * 0.3,
      ),
      paint,
    );

    // Chicken head (circle)
    canvas.drawCircle(
      Offset(centerX + size.width * 0.1, centerY - size.height * 0.15),
      size.width * 0.08,
      paint,
    );

    // Chicken comb
    final combPath = Path()
      ..moveTo(centerX + size.width * 0.12, centerY - size.height * 0.2)
      ..quadraticBezierTo(
        centerX + size.width * 0.15,
        centerY - size.height * 0.25,
        centerX + size.width * 0.12,
        centerY - size.height * 0.3,
      )
      ..lineTo(centerX + size.width * 0.12, centerY - size.height * 0.2);

    canvas.drawPath(combPath, paint);

    // Chicken beak
    final beakPath = Path()
      ..moveTo(centerX + size.width * 0.16, centerY - size.height * 0.12)
      ..lineTo(centerX + size.width * 0.22, centerY - size.height * 0.1)
      ..lineTo(centerX + size.width * 0.16, centerY - size.height * 0.08)
      ..close();

    canvas.drawPath(beakPath, paint);

    // Chicken tail
    final tailPath = Path()
      ..moveTo(centerX - size.width * 0.12, centerY)
      ..quadraticBezierTo(
        centerX - size.width * 0.2,
        centerY - size.height * 0.15,
        centerX - size.width * 0.15,
        centerY - size.height * 0.25,
      );

    canvas.drawPath(
      tailPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.05
        ..strokeCap = StrokeCap.round,
    );

    // Chicken legs
    final legPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    // Left leg
    canvas.drawLine(
      Offset(centerX - size.width * 0.08, centerY + size.height * 0.12),
      Offset(centerX - size.width * 0.08, centerY + size.height * 0.25),
      legPaint,
    );

    // Right leg
    canvas.drawLine(
      Offset(centerX + size.width * 0.08, centerY + size.height * 0.12),
      Offset(centerX + size.width * 0.08, centerY + size.height * 0.25),
      legPaint,
    );
  }

  @override
  bool shouldRepaint(KandangLogoPainter oldDelegate) => false;
}