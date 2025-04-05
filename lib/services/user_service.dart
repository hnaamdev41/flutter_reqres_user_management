import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:reqres_user_management/models/user_model.dart';
import 'package:reqres_user_management/services/api_service.dart';

class UserService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<User> _users = [];
  User? _selectedUser;
  bool _isLoading = false;
  String? _error;

  List<User> get users => _users;
  User? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsers({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/users?per_page=12', token: token);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> userData = jsonData['data'];
        
        _users = userData.map((user) => User.fromJson(user)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Failed to fetch users';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error, please try again';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> getUserById(int id, {String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/users/$id', token: token);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        _selectedUser = User.fromJson(jsonData['data']);
        _isLoading = false;
        notifyListeners();
        return _selectedUser;
      } else {
        _error = 'Failed to fetch user details';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Network error, please try again';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> createUser(User user, {String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/users', user.toJson(), token: token);
      
      if (response.statusCode == 201) {
        // In a real app, we would add the created user to the list
        // For ReqRes API, the response doesn't contain all fields, so we'll refresh the list
        await fetchUsers(token: token);
        return true;
      } else {
        _error = 'Failed to create user';
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

  Future<bool> updateUser(User user, {String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/users/${user.id}', user.toJson(), token: token);
      
      if (response.statusCode == 200) {
        // Update the user in the list
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = user;
        }
        _selectedUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update user';
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

  Future<bool> deleteUser(int id, {String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/users/$id', token: token);
      
      if (response.statusCode == 204) {
        // Remove the user from the list
        _users.removeWhere((u) => u.id == id);
        if (_selectedUser?.id == id) {
          _selectedUser = null;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete user';
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

  List<User> searchUsers(String query) {
    if (query.isEmpty) {
      return _users;
    }
    
    final lowercaseQuery = query.toLowerCase();
    
    return _users.where((user) {
      final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
      final email = user.email.toLowerCase();
      
      return fullName.contains(lowercaseQuery) || email.contains(lowercaseQuery);
    }).toList();
  }
}