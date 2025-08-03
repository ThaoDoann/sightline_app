import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/caption_entry.dart';
import 'auth_services.dart';

class CaptionService extends ChangeNotifier {
  final AuthService _authService;

  CaptionService(this._authService);
  String? _caption;
  bool _isLoading = false;
  bool _isHistoryLoading = false;
  String? _error;
  List<CaptionEntry> _history = [];

  String? get caption => _caption;
  bool get isLoading => _isLoading;
  bool get isHistoryLoading => _isHistoryLoading;
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

  Future<bool> _shouldAutoSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_save') ?? true; // Default to true
  }

  Future<void> _reloadHistoryWithLoading() async {
    _isHistoryLoading = true;
    notifyListeners();
    
    final token = _authService.token;
    if (token == null) {
      _isHistoryLoading = false;
      notifyListeners();
      return;
    }

    try {
      final user_id = _authService.userId;
      debugPrint('🔍 Caption: Reloading history for user_id: $user_id');
      
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/captions?user_id=$user_id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        _history = data.map((item) => CaptionEntry.fromJson(item)).toList();
        debugPrint('✅ Caption: Reloaded ${_history.length} history items');
      } else {
        debugPrint('❌ Caption: Failed to reload history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Caption: Error reloading history: $e');
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
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
      debugPrint('🔍 Caption: Starting caption generation (Mobile)...');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${dotenv.env['API_URL']}/generate-caption'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add user_id as form field (required by backend)
      final userId = _authService.userId;
      if (userId == null) {
        _setError("User ID not found");
        _setLoading(false);
        return;
      }
      request.fields['user_id'] = userId;
      
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _caption = _parseCaption(responseBody);
        debugPrint('✅ Caption: Caption generated successfully = $_caption');
        
        // Stop caption loading and display caption immediately
        _setLoading(false);
        
        // Check if auto-save is enabled and reload history separately
        final shouldAutoSave = await _shouldAutoSave();
        if (shouldAutoSave) {
          debugPrint('🔍 Caption: Auto-save enabled, reloading history...');
          await _reloadHistoryWithLoading();
        } else {
          debugPrint('🔍 Caption: Auto-save disabled, skipping history reload');
        }
        return; // Early return to avoid setting loading false again
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
      debugPrint('🔍 Caption: Starting caption generation (Web)...');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${dotenv.env['API_URL']}/generate-caption'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add user_id as form field (required by backend)
      final userId = _authService.userId;
      if (userId == null) {
        _setError("User ID not found");
        _setLoading(false);
        return;
      }
      request.fields['user_id'] = userId;
      
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.jpg'),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _caption = _parseCaption(responseBody);
        debugPrint('✅ Caption: Caption generated successfully = $_caption');
        
        // Stop caption loading and display caption immediately
        _setLoading(false);
        
        // Check if auto-save is enabled and reload history separately
        final shouldAutoSave = await _shouldAutoSave();
        if (shouldAutoSave) {
          debugPrint('🔍 Caption: Auto-save enabled, reloading history...');
          await _reloadHistoryWithLoading();
        } else {
          debugPrint('🔍 Caption: Auto-save disabled, skipping history reload');
        }
        return; // Early return to avoid setting loading false again
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
      final user_id = _authService.userId;
      debugPrint('🔍 Caption: Fetching history for user_id: $user_id');
      
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/captions?user_id=$user_id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('🔍 Caption: History response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        _history = data.map((item) => CaptionEntry.fromJson(item)).toList();
        debugPrint('✅ Caption: Loaded ${_history.length} history items');
        notifyListeners();
      } else {
        debugPrint('❌ Caption: Failed to fetch history: ${response.statusCode}');
        _setError('Failed to fetch history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Caption: Error fetching history: $e');
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

  // Clear only caption history data
  Future<void> clearCaptionHistory() async {
    try {
      final user_id = _authService.userId;
      final token = _authService.token;
      if (token == null) {
        debugPrint('❌ Caption: User not authenticated, cannot clear history');
        return;
      }

      if (user_id == null) {
        debugPrint('❌ Caption: User ID not found, cannot clear history');
        _setError('User ID not found');
        return;
      }

      debugPrint('🗑️ Caption: Clearing caption history for user_id: $user_id');
      final response = await http.delete(
        Uri.parse('${dotenv.env['API_URL']}/all-captions?user_id=$user_id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _history.clear();
        debugPrint('✅ Caption: History cleared successfully');
        notifyListeners();
      } else {
        debugPrint('❌ Caption: Failed to clear history: ${response.statusCode}');
        _setError('Failed to clear history');
      }
    } catch (e) {
      debugPrint('❌ Caption: Error clearing history: $e');
      _setError('Error clearing history: $e');
    }
  }

  // Clear all data when user logs out or switches users
  void clearAllData() {
    debugPrint('Caption: Clearing all caption data');
    _caption = null;
    _error = null;
    _history.clear();
    notifyListeners();
  }
}
