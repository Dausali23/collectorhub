import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  // Base URL of your Node.js backend
  // Using actual IP address for real device connection
  static const String _baseUrl = 'http://192.168.1.162:3002/api';
  
  // Create a new user
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? phoneNumber,
  }) async {
    try {
      print('Attempting to connect to: $_baseUrl/users');
      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'displayName': displayName,
          'role': role,
          'phoneNumber': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('Response status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('Error in createUser: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get all users
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users'));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get a specific user
  static Future<Map<String, dynamic>> getUser(String uid) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users/$uid'));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update a user
  static Future<Map<String, dynamic>> updateUser({
    required String uid,
    String? displayName,
    String? password,
    String? role,
    String? phoneNumber,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (displayName != null) updateData['displayName'] = displayName;
      if (password != null) updateData['password'] = password;
      if (role != null) updateData['role'] = role;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$uid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete a user
  static Future<Map<String, dynamic>> deleteUser(String uid) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/users/$uid'));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Test server connectivity
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(Uri.parse('${_baseUrl.replaceAll('/api', '')}/test'));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      return {
        'success': false,
        'error': responseData['error'] ?? 'Unknown error occurred',
      };
    }
  }
} 