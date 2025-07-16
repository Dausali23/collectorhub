import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

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
  
  // Function to get current location
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    // Request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }
  
  // Open directions to a location from current location
  static Future<void> openDirections(double destLat, double destLng) async {
    try {
      // Get current position
      Position currentPosition = await getCurrentPosition();
      double originLat = currentPosition.latitude;
      double originLng = currentPosition.longitude;
      
      // Construct URL based on platform
      String url;
      
      if (kIsWeb) {
        // For web
        url = 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // For Android
        url = 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // For iOS
        url = 'https://maps.apple.com/?saddr=$originLat,$originLng&daddr=$destLat,$destLng&dirflg=d';
      } else {
        // Fallback for other platforms
        url = 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving';
      }
      
      // Launch the URL
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      throw Exception('Error opening directions: $e');
    }
  }
} 