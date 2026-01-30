import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/detection_result.dart';
import '../models/nearby_alert.dart';

/// API Service for ArogyaKrishi backend
class ApiService {
  // Use your computer's local IP for physical device
  // Use 10.0.2.2 for Android emulator
  // Change this to match your network setup
  static const String baseUrl = 'http://192.168.137.227:8001';

  /// Upload image for disease detection
  ///
  /// Parameters:
  /// - [imageFile]: Image file to analyze
  /// - [lat]: Optional latitude for location
  /// - [lng]: Optional longitude for location
  ///
  /// Returns: DetectionResult with crop, disease, confidence, and remedies
  Future<DetectionResult> detectImage({
    required File imageFile,
    double? lat,
    double? lng,
  }) async {
    try {
      final url = '$baseUrl/api/detect-image';
      print('🌐 API Request: POST $url');
      print('📁 Image path: ${imageFile.path}');
      print('📍 Location: lat=$lat, lng=$lng');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Determine content type from file extension
      String contentType = 'image/jpeg';
      if (imageFile.path.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (imageFile.path.toLowerCase().endsWith('.jpg') ||
          imageFile.path.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }

      print('📷 Content-Type: $contentType');

      // Add image file with explicit content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: http.MediaType.parse(contentType),
        ),
      );

      // Add optional location data
      if (lat != null && lng != null) {
        request.fields['lat'] = lat.toString();
        request.fields['lng'] = lng.toString();
      }

      print('📤 Sending request...');
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print(
        '📥 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return DetectionResult.fromJson(jsonData);
      } else {
        throw ApiException(
          'Failed to detect disease: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      print('❌ API Error: $e');
      throw ApiException('Network error: $e', 0);
    }
  }

  /// Fetch nearby disease alerts
  ///
  /// Parameters:
  /// - [lat]: Latitude for location
  /// - [lng]: Longitude for location
  ///
  /// Returns: List of nearby alerts
  Future<NearbyAlertsResponse> getNearbyAlerts({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/nearby-alerts?lat=$lat&lng=$lng'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return NearbyAlertsResponse.fromJson(jsonData);
      } else {
        throw ApiException(
          'Failed to fetch alerts: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
