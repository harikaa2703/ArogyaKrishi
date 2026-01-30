import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/detection_result.dart';
import '../models/nearby_alert.dart';

/// API Service for ArogyaKrishi backend
class ApiService {
  // TODO: Update with actual backend URL
  static const String baseUrl = 'http://localhost:8000';

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
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/detect-image'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      // Add optional location data
      if (lat != null && lng != null) {
        request.fields['lat'] = lat.toString();
        request.fields['lng'] = lng.toString();
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return DetectionResult.fromJson(jsonData);
      } else {
        throw ApiException(
          'Failed to detect disease: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
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
        Uri.parse('$baseUrl/nearby-alerts?lat=$lat&lng=$lng'),
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
