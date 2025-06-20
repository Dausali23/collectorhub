import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

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
    if (parts.length < 2) return null;
    
    return parts[1];
  }
  
  // Convert base64 string to Image widget
  static Widget base64ToImageWidget(String url, {
    double? width, 
    double? height, 
    BoxFit fit = BoxFit.cover
  }) {
    final base64Data = extractBase64Data(url);
    if (base64Data == null || base64Data.isEmpty) {
      return const Icon(Icons.broken_image, size: 50);
    }
    
    try {
      Uint8List bytes = base64Decode(base64Data);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 50);
    }
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
      // Regular network image
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
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
} 