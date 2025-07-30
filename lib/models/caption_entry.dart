import 'dart:convert';
import 'dart:typed_data';

class CaptionEntry {
  final String caption;
  final DateTime timestamp;
  final Uint8List? imageBytes; // optional, not from backend currently

  CaptionEntry({
    required this.caption,
    required this.timestamp,
    this.imageBytes,
  });

  factory CaptionEntry.fromJson(Map<String, dynamic> json) {
    return CaptionEntry(
      caption: json['caption'],
      timestamp: DateTime.parse(json['timestamp']),
      imageBytes: base64Decode(json['image_base64']),
    );
  }
}
