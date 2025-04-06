import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reqres_user_management/models/auth_model.dart';
import 'package:reqres_user_management/services/api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  String? _token;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthService() {
    // Check for stored token on initialization
    _loadToken();
  }

  Future<void> _loadToken() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _token = await _secureStorage.read(key: 'auth_token');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load authentication data';
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = LoginRequest(email: email, password: password);
      print('Login request: ${request.toJson()}');
      
      final response = await _apiService.post('/login', request.toJson());
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Parsed login response: $jsonData');
        
        // reqres.in returns token directly, not nested in a "token" field
        if (jsonData.containsKey('token')) {
          _token = jsonData['token'];
          print('Got token: $_token');
          await _secureStorage.write(key: 'auth_token', value: _token);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = 'Token not found in response';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        try {
          final errorResponse = jsonDecode(response.body);
          _error = errorResponse['error'] ?? 'Authentication failed';
        } catch (e) {
          _error = 'Authentication failed (${response.statusCode})';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = RegisterRequest(email: email, password: password);
      final response = await _apiService.post('/register', request.toJson());
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        if (authResponse.isSuccess) {
          _token = authResponse.token;
          await _secureStorage.write(key: 'auth_token', value: _token);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = authResponse.error ?? 'Registration failed';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        _error = errorResponse['error'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error, please try again';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    await _secureStorage.delete(key: 'auth_token');
    notifyListeners();
  }
}