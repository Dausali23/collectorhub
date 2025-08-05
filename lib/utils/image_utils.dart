import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class ImageUtils {
  // Check if a string is a base64 encoded image
  static bool isBase64Image(String url) {
    return url.startsWith('base64://');
  }
  
  // Extract base64 data from our custom format: base64://filename;base64data
  static String? extractBase64Data(String url) {
    if (!isBase64Image(url)) return null;
    
    // Extract everything after the semicolon
    final parts = url.split(';');
    if (parts.length < 2) {
      developer.log('Invalid base64 format: $url');
      return null;
    }
    
    return parts[1];
  }
  
  // Worker function to decode base64 in a separate isolate
  static Uint8List _decodeBase64Isolate(String base64Data) {
    return base64Decode(base64Data);
  }
  
  // Convert base64 string to Image widget
  static Widget base64ToImageWidget(String url, {
    double? width, 
    double? height, 
    BoxFit fit = BoxFit.cover
  }) {
    final base64Data = extractBase64Data(url);
    if (base64Data == null || base64Data.isEmpty) {
      developer.log('Empty base64 data from URL: $url');
      return const Icon(Icons.broken_image, size: 50);
    }
    
    // For debugging
    developer.log('Attempting to decode base64 data of length: ${base64Data.length}');
    
    // Use FutureBuilder with compute to process in background
    return FutureBuilder<Uint8List>(
      future: compute(_decodeBase64Isolate, base64Data),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          developer.log('Error decoding base64 image: ${snapshot.error}');
          return const Icon(Icons.broken_image, size: 50);
        } else if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              developer.log('Error rendering base64 image: $error');
              return const Icon(Icons.broken_image, size: 50);
            },
          );
        } else {
          return const Icon(Icons.broken_image, size: 50);
        }
      },
    );
  }
  
  // Get image widget from URL (handles both remote URLs and base64 images)
  static Widget getImageWidget(String url, {
    double? width, 
    double? height, 
    BoxFit fit = BoxFit.cover
  }) {
    if (isBase64Image(url)) {
      return base64ToImageWidget(url, width: width, height: height, fit: fit);
    } else {
      // Regular network image with caching
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width?.toInt(), // Enable memory efficient loading
        cacheHeight: height?.toInt(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 50);
        },
      );
    }
  }

  // Validate if an image URL is accessible
  static Future<bool> isImageUrlValid(String? url) async {
    if (url == null || url.isEmpty) {
      developer.log('Image URL is null or empty');
      return false;
    }

    try {
      // Check if URL starts with http or https
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        developer.log('Invalid URL format: $url');
        return false;
      }

      // Try to get the headers for the URL
      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('Timeout', 408),
      );
      
      // Log the results
      developer.log('Image URL check for $url - Status: ${response.statusCode}');

      // Consider 2xx status codes as success
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      developer.log('Error checking image URL: $e for URL: $url');
      return false;
    }
  }

  // Format the image URL correctly
  static String? formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Check if it's a Firebase Storage URL that needs special handling
    if (url.contains('firebasestorage.googleapis.com') && !url.contains('alt=media')) {
      // Add the alt=media parameter for Firebase Storage URLs
      return '$url?alt=media';
    }
    
    return url;
  }
} 