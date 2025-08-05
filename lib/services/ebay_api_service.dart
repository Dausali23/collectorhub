import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EbayApiService {
  // API Constants
  // Note: In a real app, these would be securely stored 
  static const String _baseUrl = 'api.ebay.com';
  static const String _apiVersion = 'v1';
  static const String _appId = 'YOUR_EBAY_APP_ID';  // Would be stored securely
  static const String _searchEndpoint = '/buy/browse/$_apiVersion/item_summary/search';
  
  // Cache to store market prices and reduce API calls
  final Map<String, _CachedPrice> _priceCache = {};

  // Get market price for a collectible
  Future<double?> getMarketPrice(String itemName, String category, {String? subcategory}) async {
    // Create a cache key based on search parameters
    final cacheKey = '${itemName.toLowerCase()}_${category.toLowerCase()}_${subcategory?.toLowerCase() ?? ""}';
    
    // Check cache first
    if (_priceCache.containsKey(cacheKey)) {
      final cachedPrice = _priceCache[cacheKey]!;
      
      // If cache is still valid (less than 24 hours old)
      if (DateTime.now().difference(cachedPrice.timestamp).inHours < 24) {
        return cachedPrice.price;
      }
    }
    
    // For development/demo purposes, we'll use a mock implementation
    // In a real app, we'd make actual API calls to eBay
    if (kDebugMode) {
      final mockPrice = await _getMockMarketPrice(itemName, category, subcategory);
      
      // Cache the result
      _priceCache[cacheKey] = _CachedPrice(
        price: mockPrice,
        timestamp: DateTime.now(),
      );
      
      return mockPrice;
    }
    
    // Real implementation would look something like this:
    try {
      final queryParams = {
        'q': itemName,
        'category_ids': _mapCategoryToEbayId(category, subcategory),
        'filter': 'conditionIds:{1000|1500|2000|2500|3000}', // Various conditions
        'sort': 'newlyListed',
        'limit': '10',
      };
      
      final uri = Uri.https(_baseUrl, _searchEndpoint, queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_appId',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['itemSummaries'] as List<dynamic>;
        
        if (items.isNotEmpty) {
          // Calculate average price from returned items
          double totalPrice = 0;
          for (var item in items) {
            final price = double.parse(item['price']['value'].toString());
            totalPrice += price;
          }
          
          final averagePrice = totalPrice / items.length;
          
          // Cache the result
          _priceCache[cacheKey] = _CachedPrice(
            price: averagePrice,
            timestamp: DateTime.now(),
          );
          
          return averagePrice;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching market price from eBay: $e');
      return null;
    }
  }
  
  // Mock implementation for development/demo purposes
  Future<double> _getMockMarketPrice(String itemName, String category, String? subcategory) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Base price ranges for different categories
    final Map<String, List<double>> priceRanges = {
      'Trading Cards': [5.0, 500.0],
      'Comics': [10.0, 300.0],
      'Toys': [15.0, 200.0],
      'Stamps': [2.0, 100.0],
      'Coins': [5.0, 200.0],
      'Funko Pops': [10.0, 150.0],
      'Action Figures': [20.0, 300.0],
      'Vintage Items': [30.0, 500.0],
    };
    
    // Get price range for category or use default
    final range = priceRanges[category] ?? [10.0, 100.0];
    
    // Generate random price within range
    final Random random = Random();
    double basePrice = range[0] + random.nextDouble() * (range[1] - range[0]);
    
    // Round to 2 decimal places
    return double.parse(basePrice.toStringAsFixed(2));
  }
  
  // Map our categories to eBay category IDs
  String _mapCategoryToEbayId(String category, String? subcategory) {
    // In a real implementation, this would map to actual eBay category IDs
    // For now, we'll just return mock IDs
    switch (category) {
      case 'Trading Cards':
        return '183454';
      case 'Comics':
        return '63';
      case 'Toys':
        return '220';
      case 'Stamps':
        return '260';
      case 'Coins':
        return '11116';
      case 'Funko Pops':
        return '149372';
      case 'Action Figures':
        return '246';
      case 'Vintage Items':
        return '1';
      default:
        return '1';
    }
  }
}

// Helper class for caching prices
class _CachedPrice {
  final double price;
  final DateTime timestamp;
  
  _CachedPrice({required this.price, required this.timestamp});
} 