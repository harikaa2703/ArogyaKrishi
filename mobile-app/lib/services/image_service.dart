import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/constants.dart';

/// Service for handling image capture and selection
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from camera
  /// Returns compressed image file or null if cancelled/failed
  Future<File?> pickFromCamera() async {
    try {
      // Check camera permission
      final permission = await Permission.camera.status;
      if (permission.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied || result.isPermanentlyDenied) {
          throw PermissionDeniedException('Camera permission denied');
        }
      }

      // Pick image from camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: AppConstants.imageQuality,
      );

      if (image == null) return null;

      // Compress image
      return await _compressImage(File(image.path));
    } catch (e) {
      rethrow;
    }
  }

  /// Pick image from gallery
  /// Returns compressed image file or null if cancelled/failed
  Future<File?> pickFromGallery() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        // For Android 13+ (SDK 33+), use photos permission
        if (androidInfo.version.sdkInt >= 33) {
          final permission = await Permission.photos.status;
          if (permission.isDenied) {
            final result = await Permission.photos.request();
            if (result.isDenied || result.isPermanentlyDenied) {
              throw PermissionDeniedException(
                'Photo library permission denied',
              );
            }
          }
        }
        // For Android < 13
        else {
          final permission = await Permission.storage.status;
          if (permission.isDenied) {
            final result = await Permission.storage.request();
            if (result.isDenied || result.isPermanentlyDenied) {
              throw PermissionDeniedException('Storage permission denied');
            }
          }
        }
      }

      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: AppConstants.imageQuality,
      );

      if (image == null) return null;

      // Compress image
      return await _compressImage(File(image.path));
    } catch (e) {
      rethrow;
    }
  }

  /// Compress image to reduce file size
  Future<File> _compressImage(File imageFile) async {
    try {
      final fileSizeInBytes = await imageFile.length();

      // If file is already small enough, return as is
      if (fileSizeInBytes <= AppConstants.maxImageSize) {
        return imageFile;
      }

      // Compress image
      final targetPath = imageFile.path.replaceAll('.jpg', '_compressed.jpg');
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: AppConstants.imageQuality,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (result == null) {
        return imageFile; // Return original if compression fails
      }

      return File(result.path);
    } catch (e) {
      // If compression fails, return original image
      return imageFile;
    }
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Open app settings for manual permission grant
  Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}

/// Exception thrown when permission is denied
class PermissionDeniedException implements Exception {
  final String message;

  PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}
