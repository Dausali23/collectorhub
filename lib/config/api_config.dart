import 'secrets.dart';

class ApiConfig {
  // eBay Sandbox credentials - imported from secure secrets file
  static const String ebayAppId = Secrets.ebayAppId;
  static const String ebayDevId = Secrets.ebayDevId;
  static const String ebayClientSecret = Secrets.ebayClientSecret;
  
  // Sandbox API endpoints - FIXED OAuth URL
  static const String ebayBaseUrl = 'api.sandbox.ebay.com';
  static const String ebayApiVersion = 'v1';
  static const String ebayAuthUrl = 'api.sandbox.ebay.com'; // FIXED: OAuth tokens use same base URL as API
} 