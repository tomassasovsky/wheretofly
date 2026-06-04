import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:where_to_fly/map/wind/om/wind_arrow_math.dart';

/// Draws fixed-size arrow glyphs in map pixel space (shaft + filled head).
class WindArrowPainter extends CustomPainter {
  WindArrowPainter({
    required this.samples,
    required this.map,
    required this.color,
    required this.outlineColor,
  });

  final List<WindArrowSample> samples;
  final MapCamera map;
  final Color color;
  final Color outlineColor;

  static const _shaftPx = 13.0;
  static const _headLenPx = 8.0;
  static const _headHalfWidthPx = 4.5;

  @override
  void paint(Canvas canvas, Size size) {
    final shaftPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final headStroke = Paint()
      ..color = outlineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final origin = map.pixelOrigin;

    for (final s in samples) {
      final center = _offset(map.project(LatLng(s.lat, s.lon)) - origin);
      final hint = _offset(
        map.project(windArrowTip(s, lengthMeters: 800)) - origin,
      );
      final dx = hint.dx - center.dx;
      final dy = hint.dy - center.dy;
      final len = sqrt(dx * dx + dy * dy);
      if (len < 0.5) continue;

      final dir = Offset(dx / len, dy / len);
      final tail = center - dir * _shaftPx;
      final tip = center + dir * _shaftPx;
      final headBase = tip - dir * _headLenPx;

      canvas.drawLine(tail, headBase, shaftPaint);

      final perp = Offset(-dir.dy, dir.dx);
      final wing = perp * _headHalfWidthPx;
      final path = ui.Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(headBase.dx + wing.dx, headBase.dy + wing.dy)
        ..lineTo(headBase.dx - wing.dx, headBase.dy - wing.dy)
        ..close();
      canvas
        ..drawPath(path, headFill)
        ..drawPath(path, headStroke);
    }
  }

  @override
  bool shouldRepaint(covariant WindArrowPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.map != map ||
      oldDelegate.color != color;

  static Offset _offset(Point<double> p) => Offset(p.x, p.y);
}
