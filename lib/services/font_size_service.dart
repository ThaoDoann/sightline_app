import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeService extends ChangeNotifier {
  double _fontSize = 16.0;
  static const String _fontSizePrefKey = 'font_size';

  double get fontSize => _fontSize;

  FontSizeService() {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(_fontSizePrefKey) ?? 16.0;
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizePrefKey, size);
    notifyListeners();
  }

  // Helper methods for different text styles
  TextStyle get bodyText => TextStyle(fontSize: _fontSize);
  TextStyle get bodyTextMedium => TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500);
  TextStyle get bodyTextBold => TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold);
  TextStyle get captionText => TextStyle(fontSize: _fontSize * 0.875); // Slightly smaller
  TextStyle get titleText => TextStyle(fontSize: _fontSize * 1.25, fontWeight: FontWeight.w600); // Larger
}