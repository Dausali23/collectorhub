import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsService {
  // Initialize Google Maps - especially needed for web platform
  static void initialize() {
    if (kIsWeb) {
      // Initialize Google Maps for web
      // Note: For this to work, you'll need to add your API key to index.html
    }
  }

  // Function to get default camera position (can be customized later)
  static CameraPosition get defaultCameraPosition {
    // Default to some central location that makes sense for your app
    return const CameraPosition(
      target: LatLng(0, 0), // Default location
      zoom: 2,
    );
  }
} 