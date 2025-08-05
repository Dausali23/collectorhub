import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class EbayAuthService {
  static String? _accessToken;
  static DateTime? _tokenExpiry;
  
  static Future<String?> getAccessToken() async {
    // Return cached token if still valid
    if (_accessToken != null && 
        _tokenExpiry != null && 
        DateTime.now().isBefore(_tokenExpiry!)) {
      if (kDebugMode) {
        print('🔄 Using cached eBay access token');
      }
      return _accessToken;
    }
    
    if (kDebugMode) {
      print('🔑 Requesting new eBay access token...');
      print('🌐 Using endpoint: https://${ApiConfig.ebayAuthUrl}/identity/v1/oauth2/token');
    }
    
    try {
      // Create basic auth header
      final credentials = base64Encode(
        utf8.encode('${ApiConfig.ebayAppId}:${ApiConfig.ebayClientSecret}')
      );
      
      final response = await http.post(
        Uri.parse('https://${ApiConfig.ebayAuthUrl}/identity/v1/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type': 'client_credentials',
          'scope': 'https://api.ebay.com/oauth/api_scope',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
        
        if (kDebugMode) {
          print('✅ eBay access token obtained successfully');
          print('🕒 Token expires in ${expiresIn} seconds');
          print('🔑 Token starts with: ${_accessToken!.substring(0, 20)}...');
        }
        
        return _accessToken;
      } else {
        if (kDebugMode) {
          print('❌ Failed to get eBay access token: ${response.statusCode}');
          print('🔍 Response: ${response.body}');
          print('🔧 Check your credentials and endpoint URL');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting eBay access token: $e');
        print('🔧 Check your internet connection and API configuration');
      }
    }
    
    return null;
  }
} 