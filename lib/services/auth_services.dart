import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService extends ChangeNotifier {
  String get _baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000';
  String? _token;
  String? _error;
  bool _isLoading = false;

  String? get token => _token;
  String? get error => _error;
  bool get isLoading => _isLoading;

  String? _userId;
  String? _username;
  String? _email;

  String? get userId => _userId;
  String? get username => _username;
  String? get email => _email;

  AuthService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('token');
    _userId = prefs.getString('user_id');
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    notifyListeners();
  }

  Future<void> _saveToken(String token, String userId, String username, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user_id', userId);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    
    _token = token;
    _userId = userId;
    _username = username;
    _email = email;
    
    debugPrint('✅ Auth: Successfully saved and updated user data');
    notifyListeners();
  }

  Future<void> logout() async {    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Clear all auth data from SharedPreferences
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
    
    // Clear all instance variables
    _token = null;
    _userId = null;
    _username = null;
    _email = null;
    _error = null;
    
    debugPrint('✅ Auth: Logout completed - all data cleared');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    debugPrint('🔍 Auth: Attempting to login for: $email');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    _isLoading = false;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ Auth: Login successful - Response: $data');
      await _saveToken(data['access_token'], data['user_id'].toString(), data['username'], data['email']);
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      _error = errorData['detail'] ?? 'Login failed';
      debugPrint('❌ Auth: Login failed - Status: ${response.statusCode}, Error: $_error');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    _isLoading = false;

    if (response.statusCode == 200) {
      return true;
    } else {
      _error = jsonDecode(response.body)['detail'] ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }
}
