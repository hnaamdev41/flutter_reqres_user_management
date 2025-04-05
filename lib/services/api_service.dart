import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://reqres.in/api';
  final http.Client _client = http.Client();

  Future<http.Response> get(String endpoint, {String? token}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(token),
    );
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(token),
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final response = await _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(token),
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> delete(String endpoint, {String? token}) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(token),
    );
    return response;
  }

  Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
}