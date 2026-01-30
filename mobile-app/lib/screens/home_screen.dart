import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../services/api_service.dart';
import '../services/offline_detector.dart';
import '../models/detection_result.dart';
import 'offline_detection_screen.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';

/// Home screen with image capture/selection and preview
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImageService _imageService = ImageService();
  final ApiService _apiService = ApiService();
  final LocalizationService _localizationService = LocalizationService();

  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = true;
  String _languageCode = AppConstants.fallbackLanguageCode;
  Map<String, String> _strings = {};
  List<LanguagePack> _languagePacks = [];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadLocalizationPacks();
  }

  Future<void> _loadLocalizationPacks() async {
    await _localizationService.loadAll();
    final packs = _localizationService.languagePacks;
    if (!mounted) return;
    setState(() {
      _languagePacks = packs;
      if (!_localizationService.hasLanguage(_languageCode) &&
          packs.isNotEmpty) {
        _languageCode = packs.first.code;
      }
      _strings = _localizationService.getPack(_languageCode)?.strings ?? {};
    });
  }

  void _setLanguage(String code) {
    setState(() {
      _languageCode = code;
      _strings = _localizationService.getPack(_languageCode)?.strings ?? {};
    });
  }

  String _t(String key) {
    return _strings[key] ?? _localizationService.translate(_languageCode, key);
  }

  /// Check initial connectivity and listen for changes
  void _checkConnectivity() async {
    final isOnline = await OfflineDetector.isOnline();
    setState(() {
      _isOnline = isOnline;
    });

    // Listen for connectivity changes
    OfflineDetector.onConnectivityChanged.listen((isOnline) {
      setState(() {
        _isOnline = isOnline;
      });
    });
  }

  /// Show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(_t('take_photo')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(_t('choose_from_gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final image = await _imageService.pickFromCamera();

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showPermissionDialog();
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final image = await _imageService.pickFromGallery();

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showPermissionDialog();
    }
  }

  /// Show permission denied dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_t('permission_required')),
          content: Text(_t('permission_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _imageService.openSystemSettings();
              },
              child: Text(_t('open_settings')),
            ),
          ],
        );
      },
    );
  }

  /// Clear selected image
  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _errorMessage = null;
    });
  }

  /// Navigate to offline detection mode
  void _goToOfflineMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OfflineDetectionScreen(initialLanguageCode: _languageCode),
      ),
    );
  }

  /// Call backend API to detect disease from image
  Future<void> _detectDisease() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = _t('no_image_selected');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.detectImage(
        imageFile: _selectedImage!,
        language: _languageCode,
      );

      setState(() {
        _isLoading = false;
      });

      // Show result dialog
      if (mounted) {
        _showDetectionResultDialog(result);
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = '${_t('error_detection_failed')}: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '${_t('unexpected_error')}: $e';
        _isLoading = false;
      });
    }
  }

  /// Show detection result in dialog
  void _showDetectionResultDialog(DetectionResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_t('detection_result')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResultRow(_t('crop'), result.crop),
                _buildResultRow(_t('disease'), result.disease),
                _buildResultRow(
                  _t('confidence'),
                  '${(result.confidence * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 12),
                Text(
                  '${_t('remedies')}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.remedies.map((remedy) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $remedy'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('close')),
            ),
          ],
        );
      },
    );
  }

  /// Helper to build result row
  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('app_title')),
        centerTitle: true,
        actions: [
          if (_languagePacks.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _setLanguage,
              tooltip: _t('select_language'),
              icon: const Icon(Icons.language),
              itemBuilder: (context) {
                return _languagePacks
                    .map(
                      (pack) => PopupMenuItem<String>(
                        value: pack.code,
                        child: Text(pack.name),
                      ),
                    )
                    .toList();
              },
            ),
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Center(
              child: Tooltip(
                message: _isOnline ? _t('online') : _t('offline_mode'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOnline ? Icons.cloud_done : Icons.cloud_off,
                        size: 16,
                        color: _isOnline ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline ? _t('online') : _t('offline'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isOnline ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Offline mode banner
                if (!_isOnline)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t('you_are_offline'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                              Text(
                                _t('using_offline_mode'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quick action buttons
                if (!_isOnline)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _t('quick_actions'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _goToOfflineMode,
                        icon: const Icon(Icons.eco),
                        label: Text(_t('offline_diagnosis')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // Image preview section or main content
                if (_selectedImage != null) ...[
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Image preview with constrained height
                        Container(
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: Center(
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Clear button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: _clearImage,
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (_isOnline) ...[
                  // Online mode content - no Expanded
                  Container(
                    constraints: const BoxConstraints(minHeight: 300),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _t('disease_detection'),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _t('take_photo_or_gallery'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Offline mode - no image
                  const SizedBox(height: 24),
                ],

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Action buttons
                if (_isOnline)
                  if (_selectedImage != null)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _detectDisease,
                      icon: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            )
                          : const Icon(Icons.analytics),
                      label: Text(
                        _isLoading ? _t('detecting') : _t('detect_disease'),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.add_a_photo),
                          label: Text(_t('select_image')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _goToOfflineMode,
                          icon: const Icon(Icons.eco),
                          label: Text(_t('or_use_offline_mode')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
