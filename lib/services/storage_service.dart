import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

class StorageService {
  final _uuid = const Uuid();

  // Convert an image file to base64 string with optional folder parameter
  Future<String> uploadImage(File imageFile, [String folder = 'listings']) async {
    try {
      developer.log('Converting image to base64 for folder: $folder');
      
      // Read file as bytes
      final List<int> imageBytes = await imageFile.readAsBytes();
      
      // Calculate file size in MB
      final double fileSizeInMB = imageBytes.length / (1024 * 1024);
      developer.log('Image size: ${fileSizeInMB.toStringAsFixed(2)} MB');
      
      // Check if file is too large for Firestore (considering 1MB document limit)
      if (fileSizeInMB > 0.7) {
        // Reduce quality/size before conversion
        developer.log('Image too large, consider compressing it before upload');
        throw Exception('Image too large (${fileSizeInMB.toStringAsFixed(2)} MB). Please use an image smaller than 0.7 MB.');
      }
      
      // Convert to base64 string
      final String base64Image = base64Encode(imageBytes);
      developer.log('Image converted to base64 successfully. Length: ${base64Image.length}');
      
      // For base64 images, we'll use a URL format that indicates it's base64
      // This isn't a real URL but a marker for your app to understand it's a base64 image
      final String fileName = '${_uuid.v4()}_${path.basename(imageFile.path)}';
      final String base64Url = 'base64://$folder/$fileName;$base64Image';
      
      return base64Url;
    } catch (e) {
      developer.log('Error converting image to base64: $e');
      throw Exception('Failed to process image: $e');
    }
  }

  // Upload multiple images and return list of base64 data
  Future<List<String>> uploadImages(List<File> imageFiles, [String folder = 'listings']) async {
    try {
      // Check if there are actually images to upload
      if (imageFiles.isEmpty) {
        developer.log('No images provided for upload');
        throw Exception('Please select at least one image to upload');
      }
      
      final List<String> base64Images = [];
      
      developer.log('Converting ${imageFiles.length} images to base64');
      
      for (int i = 0; i < imageFiles.length; i++) {
        try {
          developer.log('Processing image ${i + 1} of ${imageFiles.length}');
          final String base64Data = await uploadImage(imageFiles[i], folder);
          base64Images.add(base64Data);
          developer.log('Successfully processed image ${i + 1}');
        } catch (e) {
          developer.log('Error processing image ${i + 1}: $e');
          // Continue with next image instead of failing the entire process
        }
      }
      
      if (base64Images.isEmpty) {
        throw Exception('Failed to process any images. Please use smaller images (under 0.7 MB each).');
      }
      
      return base64Images;
    } catch (e) {
      developer.log('Error processing multiple images: $e');
      throw Exception('Failed to process images: $e');
    }
  }

  // No need for a delete function since images would be deleted with Firestore documents
  // But keeping a stub for compatibility
  Future<void> deleteImage(String imageUrl) async {
    // Nothing to do for base64 images stored in Firestore
    // They will be deleted when the Firestore document is deleted
    return;
  }
} 