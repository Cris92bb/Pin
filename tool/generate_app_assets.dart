import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Asset generator for Pin Android, Wear OS, and Web platforms.
///
/// Slices and scales [assets/icons/pin.png] to generate:
/// - Android legacy & round mipmaps (`ic_launcher.png`, `ic_launcher_round.png`)
/// - Adaptive icon foregrounds (`ic_launcher_foreground.png`) & XML configs
/// - Splash screen drawables (`splash_icon.png`)
/// - Web launcher & maskable icons and favicon
void main() {
  final masterFile = File('assets/icons/pin.png');
  if (!masterFile.existsSync()) {
    stderr.writeln('Error: assets/icons/pin.png not found.');
    exit(1);
  }

  stdout.writeln('Decoding master icon...');
  final master = img.decodeImage(masterFile.readAsBytesSync())!;

  // 1. Extract squircle icon and build masks
  final cropped = img.copyCrop(master, x: 148, y: 140, width: 728, height: 728);
  final cleanSquircle = _applyMask(cropped, isCircle: false, cornerRadius: 160);
  final roundIcon = _applyMask(cropped, isCircle: true);
  final pinForeground = _extractPinForeground(master);

  // 2. Android Mipmap densities
  final androidResDir = Directory('android/app/src/main/res');
  final mipmaps = {'mipmap-mdpi': 48, 'mipmap-hdpi': 72, 'mipmap-xhdpi': 96, 'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192};

  for (final entry in mipmaps.entries) {
    final dir = Directory('${androidResDir.path}/${entry.key}')..createSync(recursive: true);
    final size = entry.value;

    _save(dir, 'ic_launcher.png', img.copyResize(cleanSquircle, width: size, height: size, interpolation: img.Interpolation.cubic));
    _save(dir, 'ic_launcher_round.png', img.copyResize(roundIcon, width: size, height: size, interpolation: img.Interpolation.cubic));

    final adaptiveSize = (size * 108) ~/ 48;
    _save(dir, 'ic_launcher_foreground.png', _centerInCanvas(pinForeground, adaptiveSize, 0.72));
  }

  // 3. Splash Icon drawables (160dp window)
  final splashes = {'drawable-mdpi': 160, 'drawable-hdpi': 240, 'drawable-xhdpi': 320, 'drawable-xxhdpi': 480, 'drawable-xxxhdpi': 640};
  for (final entry in splashes.entries) {
    final dir = Directory('${androidResDir.path}/${entry.key}')..createSync(recursive: true);
    _save(dir, 'splash_icon.png', _centerInCanvas(pinForeground, entry.value, 0.75));
  }
  final defaultDrawDir = Directory('${androidResDir.path}/drawable')..createSync(recursive: true);
  _save(defaultDrawDir, 'splash_icon.png', _centerInCanvas(pinForeground, 320, 0.75));

  // 4. Web icons & favicon
  if (Directory('web/icons').existsSync()) {
    _save(Directory('web/icons'), 'Icon-192.png', img.copyResize(cleanSquircle, width: 192, height: 192, interpolation: img.Interpolation.cubic));
    _save(Directory('web/icons'), 'Icon-512.png', img.copyResize(cleanSquircle, width: 512, height: 512, interpolation: img.Interpolation.cubic));
    _save(Directory('web/icons'), 'Icon-maskable-192.png', _buildMaskableWeb(cleanSquircle, 192));
    _save(Directory('web/icons'), 'Icon-maskable-512.png', _buildMaskableWeb(cleanSquircle, 512));
    _save(Directory('web'), 'favicon.png', img.copyResize(cleanSquircle, width: 64, height: 64, interpolation: img.Interpolation.cubic));
  }

  stdout.writeln('Asset generation completed successfully!');
}

void _save(Directory dir, String filename, img.Image image) {
  File('${dir.path}/$filename').writeAsBytesSync(img.encodePng(image));
}

/// Applies either a squircle (rounded-corner) or circle alpha mask.
img.Image _applyMask(img.Image src, {required bool isCircle, int cornerRadius = 0}) {
  final out = img.Image(width: src.width, height: src.height, numChannels: 4);
  final w = src.width;
  final h = src.height;
  final cx = w / 2.0;
  final cy = h / 2.0;
  final r = cornerRadius.toDouble();
  final circleRadius = math.min(cx, cy) - 2.0;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      double alpha = 1.0;

      if (isCircle) {
        final dist = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2));
        if (dist > circleRadius) alpha = math.max(0.0, 1.0 - (dist - circleRadius));
      } else {
        final dx = x < r ? r - x : (x > w - r ? x - (w - r) : 0.0);
        final dy = y < r ? r - y : (y > h - r ? y - (h - r) : 0.0);
        if (dx > 0 && dy > 0) {
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist > r) alpha = math.max(0.0, 1.0 - (dist - r));
        }
      }

      out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), (alpha * 255).round().clamp(0, 255));
    }
  }
  return out;
}

/// Extracts the push-pin with crisp transparency and soft drop shadow.
img.Image _extractPinForeground(img.Image master) {
  final out = img.Image(width: 1024, height: 1024, numChannels: 4);
  const minX = 305, maxX = 740, minY = 225, maxY = 785;
  final mask = List<bool>.filled(1024 * 1024, false);

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final p = master.getPixel(x, y);
      final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
      final isRed = (r > 75 && r > g * 1.25 && r > b * 1.25);
      final isSpecular = (r > 180 && g > 150 && b > 150);
      final isNeedle = (y > 510 && x < 480 && r > 60 && g > 60 && b > 60 && (r - g).abs() < 35 && (g - b).abs() < 35);
      if (isRed || isSpecular || isNeedle) mask[y * 1024 + x] = true;
    }
  }

  // Soft drop shadow offset
  final shadowMask = List<double>.filled(1024 * 1024, 0.0);
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      if (!mask[y * 1024 + x]) continue;
      for (var sy = -8; sy <= 8; sy++) {
        for (var sx = -8; sx <= 8; sx++) {
          final tx = x + 8 + sx, ty = y + 12 + sy;
          if (tx < 0 || tx >= 1024 || ty < 0 || ty >= 1024) continue;
          final distSq = sx * sx + sy * sy;
          if (distSq > 64) continue;
          final strength = (1.0 - (distSq / 64.0)) * 0.35;
          final idx = ty * 1024 + tx;
          if (strength > shadowMask[idx]) shadowMask[idx] = strength;
        }
      }
    }
  }

  for (var y = 0; y < 1024; y++) {
    for (var x = 0; x < 1024; x++) {
      final idx = y * 1024 + x;
      if (mask[idx]) {
        final p = master.getPixel(x, y);
        out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      } else if (shadowMask[idx] > 0.02) {
        out.setPixelRgba(x, y, 0, 0, 0, (shadowMask[idx] * 255).round().clamp(0, 100));
      } else {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  return out;
}

/// Centers [imgToCenter] scaled by [scaleRatio] onto a transparent canvas of size [canvasSize].
img.Image _centerInCanvas(img.Image imgToCenter, int canvasSize, double scaleRatio) {
  final out = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  final targetSize = (canvasSize * scaleRatio).round();
  final resized = img.copyResize(imgToCenter, width: targetSize, height: targetSize, interpolation: img.Interpolation.cubic);
  final offset = (canvasSize - targetSize) ~/ 2;
  img.compositeImage(out, resized, dstX: offset, dstY: offset);
  return out;
}

/// Builds maskable web icon with dark background `#15181E`.
img.Image _buildMaskableWeb(img.Image squircleImg, int canvasSize) {
  final out = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  img.fill(out, color: img.ColorRgba8(0x15, 0x18, 0x1E, 0xFF));
  final contentSize = (canvasSize * 0.80).round();
  final resized = img.copyResize(squircleImg, width: contentSize, height: contentSize, interpolation: img.Interpolation.cubic);
  final offset = (canvasSize - contentSize) ~/ 2;
  img.compositeImage(out, resized, dstX: offset, dstY: offset);
  return out;
}
