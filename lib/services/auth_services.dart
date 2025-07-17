import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static const String _baseUrl =
      'http://localhost:8000'; // Change to your IP for Android/iOS
  String? _token;
  String? _error;
  bool _isLoading = false;

  String? get token => _token;
  String? get error => _error;
  bool get isLoading => _isLoading;

  String? _username;
  String? _email;

  String? get username => _username;
  String? get email => _email;

  AuthService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('token');
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    notifyListeners();
  }

  Future<void> _saveToken(String token, String username, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    _token = token;
    _username = username;
    _email = email;
    notifyListeners();
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
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
      debugPrint(data.toString());
      await _saveToken(data['access_token'], data['username'], data['email']);
      return true;
    } else {
      _error = jsonDecode(response.body)['detail'] ?? 'Login failed';
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
