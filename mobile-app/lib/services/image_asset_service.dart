import 'package:flutter/material.dart';

/// Service for managing image assets for crops and symptoms
///
/// Naming scheme:
/// - Crops: assets/images/crops/{crop_id}.png (e.g., rice.png, wheat.png)
/// - Symptoms: assets/images/symptoms/{symptom_id}.png (e.g., yellow_leaves.png)
///
/// Images are PNG format with transparent backgrounds recommended
/// Size: 200x200 dp for crops, 150x150 dp for symptoms
class ImageAssetService {
  /// Get crop image path based on crop ID
  /// Returns the asset path if image exists, otherwise returns null for fallback
  static String getCropImagePath(String cropId) {
    return 'assets/images/crops/$cropId.png';
  }

  /// Get symptom image path based on symptom ID
  /// Returns the asset path if image exists, otherwise returns null for fallback
  static String getSymptomImagePath(String symptomId) {
    return 'assets/images/symptoms/$symptomId.png';
  }

  /// Build a crop image widget with fallback to icon
  ///
  /// Parameters:
  /// - cropId: The crop ID (used to construct image path)
  /// - cropName: The crop name (used in fallback icon)
  /// - size: Size of the image (default 120)
  static Widget buildCropImage({
    required String cropId,
    required String cropName,
    double size = 120,
  }) {
    return _buildImageWithFallback(
      imagePath: getCropImagePath(cropId),
      fallbackIcon: Icons.eco,
      fallbackLabel: _getInitials(cropName),
      fallbackName: cropName,
      size: size,
      backgroundColor: Colors.green[100]!,
      iconColor: Colors.green[700]!,
    );
  }

  /// Build a symptom image widget with fallback to icon
  ///
  /// Parameters:
  /// - symptomId: The symptom ID (used to construct image path)
  /// - imagePath: Optional custom image path (takes precedence over symptomId)
  /// - symptomName: The symptom name (used in fallback)
  /// - size: Size of the image (default 100)
  static Widget buildSymptomImage({
    required String symptomId,
    String? imagePath,
    required String symptomName,
    double size = 100,
  }) {
    return _buildImageWithFallback(
      imagePath: imagePath ?? getSymptomImagePath(symptomId),
      fallbackIcon: Icons.health_and_safety,
      fallbackLabel: _getInitials(symptomName),
      fallbackName: symptomName,
      size: size,
      backgroundColor: Colors.amber[50]!,
      iconColor: Colors.amber[700]!,
    );
  }

  /// Get initials from name (up to 2 characters)
  static String _getInitials(String name) {
    final parts = name.split('_');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  /// Internal method to build image with fallback
  /// Attempts to load image from asset, falls back to icon if not found
  static Widget _buildImageWithFallback({
    required String imagePath,
    required IconData fallbackIcon,
    required String fallbackLabel,
    required String fallbackName,
    required double size,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _ImageFallbackWidget(
        imagePath: imagePath,
        fallbackIcon: fallbackIcon,
        fallbackLabel: fallbackLabel,
        fallbackName: fallbackName,
        size: size,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
      ),
    );
  }
}

/// Widget that handles image loading with fallback to icon
class _ImageFallbackWidget extends StatelessWidget {
  final String imagePath;
  final IconData fallbackIcon;
  final String fallbackLabel;
  final String fallbackName;
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const _ImageFallbackWidget({
    required this.imagePath,
    required this.fallbackIcon,
    required this.fallbackLabel,
    required this.fallbackName,
    required this.size,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
    );
  }

  Widget _buildFallbackIcon() {
    // Calculate responsive sizes based on container size
    final iconSize = size * 0.45;
    final textSize = size * 0.22;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(fallbackIcon, size: iconSize, color: iconColor),
              SizedBox(height: size * 0.06),
              Text(
                fallbackLabel,
                style: TextStyle(
                  color: iconColor,
                  fontSize: textSize.clamp(10, 22),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
