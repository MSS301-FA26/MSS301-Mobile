import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final posterAmbientLoaderProvider = Provider<Future<Color> Function(String)>(
  (ref) => posterAmbientColor,
);

// Tiny decoded images, cached per URL/asset; never sample on animation frames.
final _colors = <String, Future<Color>>{};
Future<Color> posterAmbientColor(String source) {
  if (_colors.length > 80) _colors.clear();
  return _colors.putIfAbsent(source, () async {
    const neutral = Color(0xFF232631);
    if (source.isEmpty) return neutral;
    final uri = Uri.tryParse(source);
    final ImageProvider provider =
        uri != null && ['http', 'https'].contains(uri.scheme)
        ? NetworkImage(source)
        : AssetImage(source);
    final stream = ResizeImage.resizeIfNeeded(
      24,
      24,
      provider,
    ).resolve(ImageConfiguration.empty);
    final result = Completer<Color>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) async {
        stream.removeListener(listener);
        final image = info.image.clone();
        try {
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (bytes == null) {
            if (!result.isCompleted) result.complete(neutral);
            return;
          }
          double red = 0, green = 0, blue = 0, weights = 0;
          for (int i = 0; i < bytes.lengthInBytes; i += 4) {
            final r = bytes.getUint8(i),
                g = bytes.getUint8(i + 1),
                b = bytes.getUint8(i + 2);
            final high = [r, g, b].reduce((a, b) => a > b ? a : b);
            final low = [r, g, b].reduce((a, b) => a < b ? a : b);
            if (high < 30 || low > 220 || bytes.getUint8(i + 3) < 128) continue;
            final weight = 0.1 + (high - low) / 255;
            red += r * weight;
            green += g * weight;
            blue += b * weight;
            weights += weight;
          }
          if (!result.isCompleted) {
            result.complete(
              weights == 0
                  ? neutral
                  : Color.fromARGB(
                      255,
                      (red / weights).round(),
                      (green / weights).round(),
                      (blue / weights).round(),
                    ),
            );
          }
        } catch (_) {
          if (!result.isCompleted) result.complete(neutral);
        } finally {
          image.dispose();
        }
      },
      onError: (_, _) {
        stream.removeListener(listener);
        if (!result.isCompleted) result.complete(neutral);
      },
    );
    stream.addListener(listener);
    try {
      return await result.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => neutral,
      );
    } finally {
      stream.removeListener(listener);
    }
  });
}
