import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/caption_entry.dart';

class CaptionService extends ChangeNotifier {
  String? _caption;
  bool _isLoading = false;
  String? _error;
  final List<CaptionEntry> _history = [];

  String? get caption => _caption;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CaptionEntry> get history => List.unmodifiable(_history);

  String _parseCaption(String responseBody) {
    try {
      final Map<String, dynamic> json = jsonDecode(responseBody);
      return json['caption'] as String;
    } catch (e) {
      return responseBody;
    }
  }

  Future<void> generateCaption(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${dotenv.env['API_URL']}/caption'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _caption = _parseCaption(responseBody);
        _error = null;
        _addToHistory(await imageFile.readAsBytes(), _caption!);
      } else {
        _error = 'Failed to generate caption: ${response.statusCode}';
        _caption = null;
      }
    } catch (e) {
      _error = 'Error: $e';
      _caption = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateCaptionWeb(Uint8List imageBytes) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${dotenv.env['API_URL']}/caption'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _caption = _parseCaption(responseBody);
        _error = null;
        _addToHistory(imageBytes, _caption!);
      } else {
        _error = 'Failed to generate caption: ${response.statusCode}';
        _caption = null;
      }
    } catch (e) {
      _error = 'Error: $e';
      _caption = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addToHistory(Uint8List imageBytes, String caption) {
    _history.insert(0, CaptionEntry(
      imageBytes: imageBytes,
      caption: caption,
      timestamp: DateTime.now(),
    ));
  }

  void clearCaption() {
    _caption = null;
    _error = null;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
} 