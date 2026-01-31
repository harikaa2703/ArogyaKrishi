import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/detection_result.dart';

/// Service for caching disease search history locally
class SearchCacheService {
  static const String _cacheKey = 'search_history_cache';
  static const String _imagesDirName = 'search_images';
  static const int _maxCacheSize = 100; // Maximum number of searches to keep

  /// Model for cached search
  static Map<String, dynamic> _createCacheItem({
    required String crop,
    required String disease,
    required double confidence,
    required List<String> remedies,
    required String language,
    String? imagePath,
    double? latitude,
    double? longitude,
  }) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch,
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'remedies': remedies,
      'language': language,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Get the directory for storing images
  static Future<Directory> _getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/$_imagesDirName');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Save a detection result with image to cache
  static Future<void> saveSearch({
    required DetectionResult result,
    File? imageFile,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing cache
      final cacheJson = prefs.getString(_cacheKey);
      List<dynamic> cache = [];
      if (cacheJson != null) {
        cache = json.decode(cacheJson) as List<dynamic>;
      }

      // Save image locally if provided
      String? savedImagePath;
      if (imageFile != null && await imageFile.exists()) {
        final imagesDir = await _getImagesDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = imageFile.path.split('.').last;
        final newImagePath = '${imagesDir.path}/$timestamp.$extension';

        // Copy image to app directory
        await imageFile.copy(newImagePath);
        savedImagePath = newImagePath;
      }

      // Create cache item
      final cacheItem = _createCacheItem(
        crop: result.crop,
        disease: result.disease,
        confidence: result.confidence,
        remedies: result.remedies,
        language: result.language,
        imagePath: savedImagePath,
        latitude: latitude,
        longitude: longitude,
      );

      // Add to beginning of cache (most recent first)
      cache.insert(0, cacheItem);

      // Limit cache size and clean up old images
      if (cache.length > _maxCacheSize) {
        // Remove old items and delete their images
        for (int i = _maxCacheSize; i < cache.length; i++) {
          final oldItem = cache[i] as Map<String, dynamic>;
          final oldImagePath = oldItem['imagePath'] as String?;
          if (oldImagePath != null) {
            final oldImage = File(oldImagePath);
            if (await oldImage.exists()) {
              await oldImage.delete();
            }
          }
        }
        cache = cache.sublist(0, _maxCacheSize);
      }

      // Save back to preferences
      await prefs.setString(_cacheKey, json.encode(cache));
    } catch (e) {
      print('Error saving search to cache: $e');
    }
  }

  /// Get all cached searches
  static Future<List<Map<String, dynamic>>> getAllSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      if (cacheJson == null) {
        return [];
      }

      final cache = json.decode(cacheJson) as List<dynamic>;
      return cache.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading cached searches: $e');
      return [];
    }
  }

  /// Get paginated searches
  static Future<List<Map<String, dynamic>>> getSearches({
    int limit = 20,
    int offset = 0,
  }) async {
    final allSearches = await getAllSearches();

    if (offset >= allSearches.length) {
      return [];
    }

    final end = (offset + limit) > allSearches.length
        ? allSearches.length
        : offset + limit;

    return allSearches.sublist(offset, end);
  }

  /// Get total count of cached searches
  static Future<int> getTotalCount() async {
    final allSearches = await getAllSearches();
    return allSearches.length;
  }

  /// Delete a specific search by ID
  static Future<bool> deleteSearch(int searchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      if (cacheJson == null) {
        return false;
      }

      List<dynamic> cache = json.decode(cacheJson) as List<dynamic>;

      // Find and remove the item
      final index = cache.indexWhere((item) => item['id'] == searchId);
      if (index == -1) {
        return false;
      }

      final removedItem = cache[index] as Map<String, dynamic>;

      // Delete associated image
      final imagePath = removedItem['imagePath'] as String?;
      if (imagePath != null) {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // Remove from cache
      cache.removeAt(index);

      // Save back
      await prefs.setString(_cacheKey, json.encode(cache));
      return true;
    } catch (e) {
      print('Error deleting search from cache: $e');
      return false;
    }
  }

  /// Clear all cached searches
  static Future<int> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      int count = 0;

      if (cacheJson != null) {
        final cache = json.decode(cacheJson) as List<dynamic>;
        count = cache.length;

        // Delete all images
        for (var item in cache) {
          final imagePath = item['imagePath'] as String?;
          if (imagePath != null) {
            final imageFile = File(imagePath);
            if (await imageFile.exists()) {
              await imageFile.delete();
            }
          }
        }
      }

      // Clear cache
      await prefs.remove(_cacheKey);

      // Clean up images directory
      try {
        final imagesDir = await _getImagesDirectory();
        if (await imagesDir.exists()) {
          await imagesDir.delete(recursive: true);
        }
      } catch (e) {
        print('Error cleaning images directory: $e');
      }

      return count;
    } catch (e) {
      print('Error clearing cache: $e');
      return 0;
    }
  }

  /// Get unique diseases from cache
  static Future<List<Map<String, dynamic>>> getUniqueDiseases({
    int limit = 20,
  }) async {
    final allSearches = await getAllSearches();

    final diseaseMap = <String, Map<String, dynamic>>{};

    for (var search in allSearches) {
      final disease = search['disease'] as String;
      final crop = search['crop'] as String;
      final createdAt = DateTime.parse(search['createdAt'] as String);

      final key = '$disease-$crop';

      if (!diseaseMap.containsKey(key)) {
        diseaseMap[key] = {
          'disease': disease,
          'crop': crop,
          'last_searched': createdAt,
          'search_count': 1,
        };
      } else {
        diseaseMap[key]!['search_count'] =
            (diseaseMap[key]!['search_count'] as int) + 1;
        final lastSearched = diseaseMap[key]!['last_searched'] as DateTime;
        if (createdAt.isAfter(lastSearched)) {
          diseaseMap[key]!['last_searched'] = createdAt;
        }
      }
    }

    final uniqueList = diseaseMap.values.toList();
    uniqueList.sort(
      (a, b) => (b['last_searched'] as DateTime).compareTo(
        a['last_searched'] as DateTime,
      ),
    );

    return uniqueList.take(limit).toList();
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final allSearches = await getAllSearches();
    final imagesDir = await _getImagesDirectory();

    int imageCount = 0;
    int totalImageSize = 0;

    if (await imagesDir.exists()) {
      final files = await imagesDir.list().toList();
      imageCount = files.length;

      for (var file in files) {
        if (file is File) {
          try {
            final stat = await file.stat();
            totalImageSize += stat.size;
          } catch (e) {
            // Skip if can't get file size
          }
        }
      }
    }

    return {
      'total_searches': allSearches.length,
      'total_images': imageCount,
      'total_size_bytes': totalImageSize,
      'total_size_mb': (totalImageSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }
}
