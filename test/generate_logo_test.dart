import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zekinance/app/theme/app_colors.dart';

void main() {
  testWidgets('Generate Logo PNG', (WidgetTester tester) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(1024, 1024);
    
    final rect = Offset.zero & size;
    
    // Background gradient (Luxurious dark gradient)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0D1527), Color(0xFF070B14)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Inner glowing ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..shader = AppColors.primaryGradient.createShader(rect);
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.44, ringPaint);

    final w = size.width;
    final h = size.height;

    // Upward financial trend curve (Glowing emerald to cyan line)
    final trendPath = Path()
      ..moveTo(w * 0.25, h * 0.75)
      ..cubicTo(w * 0.4, h * 0.78, w * 0.5, h * 0.45, w * 0.72, h * 0.32);

    final trendPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..shader = AppColors.primaryGradient.createShader(rect);
    canvas.drawPath(trendPath, trendPaint);

    // Dynamic Gold Coin / Accent Dot at the peak of the chart
    final goldPaint = Paint()
      ..shader = AppColors.goldGradient.createShader(
        Rect.fromCircle(center: Offset(w * 0.72, h * 0.32), radius: w * 0.1),
      );
    canvas.drawCircle(Offset(w * 0.72, h * 0.32), w * 0.09, goldPaint);

    // Draw stylized 'Z' outline crossing the trend (Futuristic feel)
    final zPath = Path()
      ..moveTo(w * 0.3, h * 0.32)
      ..lineTo(w * 0.6, h * 0.32)
      ..lineTo(w * 0.35, h * 0.65)
      ..lineTo(w * 0.65, h * 0.65);

    final zPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.85);
    canvas.drawPath(zPath, zPaint);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    
    File('assets/logo.png').writeAsBytesSync(buffer);
  });
}
