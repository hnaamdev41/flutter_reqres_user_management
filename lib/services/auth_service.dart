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
      final response = await _apiService.post('/login', request.toJson());
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        if (authResponse.isSuccess) {
          _token = authResponse.token;
          await _secureStorage.write(key: 'auth_token', value: _token);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = authResponse.error ?? 'Authentication failed';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        _error = errorResponse['error'] ?? 'Authentication failed';
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