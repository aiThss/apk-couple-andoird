import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'app_theme.dart';

class DynamicThemeController extends ChangeNotifier {
  Color _seedColor = neonPink;
  String? _lastImageKey;

  Color get seedColor => _seedColor;

  Color get backgroundColor => darkBg;

  Color get backgroundAccentColor => deepPurple;

  Color get buttonColor => neonPink;

  Color get onButtonColor => Colors.white;

  Color get textColor => Colors.white;

  Future<void> updateFromUrl(String? imageUrl) async {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty || url == _lastImageKey) {
      return;
    }

    _lastImageKey = url;
    await _updateFromProvider(NetworkImage(url));
  }

  Future<void> updateFromFile(File file) async {
    final key = file.path;
    if (key == _lastImageKey) {
      return;
    }

    _lastImageKey = key;
    await _updateFromProvider(FileImage(file));
  }

  Future<void> _updateFromProvider(ImageProvider imageProvider) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 18,
        size: const Size(320, 320),
      );

      final picked =
          palette.mutedColor?.color ??
          palette.lightMutedColor?.color ??
          palette.dominantColor?.color ??
          palette.vibrantColor?.color;

      if (picked == null) {
        return;
      }

      final softened = _softenImageColor(picked);
      if (softened != _seedColor) {
        _seedColor = softened;
        notifyListeners();
      }
    } catch (_) {
      return;
    }
  }

  Color _softenImageColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final saturation = hsl.saturation.clamp(0.42, 0.78);
    final lightness = hsl.lightness.clamp(0.48, 0.62);
    return hsl.withSaturation(saturation).withLightness(lightness).toColor();
  }
}
