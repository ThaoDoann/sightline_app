import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/caption_entry.dart';
import 'auth_services.dart';

class CaptionService extends ChangeNotifier {
  final AuthService _authService;

  CaptionService(this._authService);
  String? _caption;
  bool _isLoading = false;
  String? _error;
  List<CaptionEntry> _history = [];

  String? get caption => _caption;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CaptionEntry> get history => List.unmodifiable(_history);

  String _parseCaption(String responseBody) {
    try {
      final Map<String, dynamic> json = jsonDecode(responseBody);
      return json['caption'] as String;
    } catch (_) {
      return responseBody;
    }
  }

  Future<void> generateCaption(File imageFile) async {
    _setLoading(true);
    final token = _authService.token;
    if (token == null) {
      _setError("User not authenticated");
      _setLoading(false);
      return;
    }
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${dotenv.env['API_URL']}/caption'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _caption = _parseCaption(responseBody);
      } else {
        _setError('Failed to generate caption: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> generateCaptionWeb(Uint8List imageBytes) async {
    _setLoading(true);
    final token = _authService.token;
    if (token == null) {
      _setError("User not authenticated");
      _setLoading(false);
      return;
    }
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${dotenv.env['API_URL']}/caption'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.jpg'),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _caption = _parseCaption(responseBody);
      } else {
        _setError('Failed to generate caption: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchHistoryFromBackend() async {
    _setLoading(true);
    final token = _authService.token;
    if (token == null) {
      _setError("User not authenticated");
      _setLoading(false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/captions'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        _history = data.map((item) => CaptionEntry.fromJson(item)).toList();
        notifyListeners();
      } else {
        _setError('Failed to fetch history: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Error fetching history: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _caption = null;
    notifyListeners();
  }

  void clearCaption() {
    _caption = null;
    _error = null;
    notifyListeners();
  }
}
