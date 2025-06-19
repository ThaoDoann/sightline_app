import 'dart:typed_data';

class CaptionEntry {
  final Uint8List imageBytes;
  final String caption;
  final DateTime timestamp;

  CaptionEntry({
    required this.imageBytes,
    required this.caption,
    required this.timestamp,
  });
} 