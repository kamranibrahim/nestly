import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';

/// Builds circular avatar-style map markers (cached by key).
class LocatorMarkerBitmaps {
  LocatorMarkerBitmaps._();

  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> avatar({
    required String initials,
    required Color color,
    required bool selected,
    required bool stale,
    double logicalSize = 48,
  }) async {
    final fill = AppColors.avatarFill(color);
    final drawnFill = stale ? Color.lerp(fill, Colors.white, 0.35)! : fill;
    final drawnOn = AppColors.onAvatarFill(drawnFill);
    final key =
        '${initials.toUpperCase()}|${drawnFill.toARGB32()}|${drawnOn.toARGB32()}|$selected|$stale|$logicalSize';
    final hit = _cache[key];
    if (hit != null) return hit;

    final dpr = ui.PlatformDispatcher.instance.views.isEmpty
        ? 2.0
        : ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final size = (logicalSize * dpr).roundToDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - (selected ? 2 * dpr : 1 * dpr);

    // Soft shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: stale ? 0.12 : 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * dpr);
    canvas.drawCircle(center.translate(0, 1.5 * dpr), radius, shadow);

    final fillPaint = Paint()..color = drawnFill;
    canvas.drawCircle(center, radius, fillPaint);

    final border = Paint()
      ..color = selected ? AppColors.ink : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = (selected ? 3.2 : 2.4) * dpr;
    canvas.drawCircle(center, radius - border.strokeWidth / 2, border);

    final text = TextPainter(
      text: TextSpan(
        text: initials.length <= 2
            ? initials.toUpperCase()
            : initials.substring(0, 2).toUpperCase(),
        style: TextStyle(
          color: drawnOn.withValues(alpha: stale ? 0.7 : 1),
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    text.paint(
      canvas,
      Offset(center.dx - text.width / 2, center.dy - text.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.round(), size.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      return BitmapDescriptor.defaultMarker;
    }
    final descriptor = BitmapDescriptor.bytes(
      Uint8List.view(bytes.buffer),
      imagePixelRatio: dpr,
    );
    _cache[key] = descriptor;
    return descriptor;
  }
}
