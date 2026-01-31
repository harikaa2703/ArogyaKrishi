import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_service.dart';
import '../services/api_service.dart';
import '../services/offline_detector.dart';
import '../services/search_cache_service.dart';
import '../models/detection_result.dart';
import '../models/nearby_alert.dart';
import 'offline_detection_screen.dart';
import 'detection_result_screen.dart';
import 'chat_screen.dart';
import 'search_history_screen.dart';
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
  List<NearbyAlert> _nearbyAlerts = [];
  bool _isFetchingAlerts = false;
  bool _isLanguageDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initializeLanguage();
    _fetchNearbyAlerts();
    _registerDevice();
  }

  Future<void> _registerDevice({String? language}) async {
    try {
      final position = await _getCurrentPosition();
      if (position == null) return;

      final deviceToken = await _getDeviceToken();
      if (deviceToken == null || deviceToken.isEmpty) return;

      await _apiService.registerDevice(
        deviceToken: deviceToken,
        lat: position.latitude,
        lng: position.longitude,
        notificationsEnabled: true,
        language: language,
      );
    } catch (_) {
      // Silent fail for MVP registration
    }
  }

  Future<String?> _getDeviceToken() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.id;
      }
      if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchNearbyAlerts() async {
    setState(() {
      _isFetchingAlerts = true;
    });

    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        setState(() {
          _isFetchingAlerts = false;
          _nearbyAlerts = [];
        });
        return;
      }

      final response = await _apiService.getNearbyAlerts(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _isFetchingAlerts = false;
        _nearbyAlerts = response.alerts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetchingAlerts = false;
      });
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _initializeLanguage() async {
    await _localizationService.loadAll();
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(AppConstants.prefLanguageCode);
    final packs = _localizationService.languagePacks;
    if (!mounted) return;
    setState(() {
      _languagePacks = packs;
      if (savedCode != null && _localizationService.hasLanguage(savedCode)) {
        _languageCode = savedCode;
      } else if (!_localizationService.hasLanguage(_languageCode) &&
          packs.isNotEmpty) {
        _languageCode = packs.first.code;
      }
      _strings = _localizationService.getPack(_languageCode)?.strings ?? {};
    });

    if (savedCode != null && _localizationService.hasLanguage(savedCode)) {
      await _syncLanguageToServer(savedCode);
    }

    final hasChosen = prefs.getBool(AppConstants.prefLanguageChosen) ?? false;
    if (!hasChosen && packs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showLanguagePreferenceDialog();
        }
      });
    }
  }

  void _setLanguage(String code) {
    _applyLanguageSelection(code, markChosen: true);
  }

  Future<void> _applyLanguageSelection(
    String code, {
    bool markChosen = false,
  }) async {
    setState(() {
      _languageCode = code;
      _strings = _localizationService.getPack(_languageCode)?.strings ?? {};
    });

    await _persistLanguage(code, markChosen: markChosen);

    await _syncLanguageToServer(code);
  }

  Future<void> _persistLanguage(String code, {bool markChosen = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLanguageCode, code);
    if (markChosen) {
      await prefs.setBool(AppConstants.prefLanguageChosen, true);
    }
  }

  Future<void> _syncLanguageToServer(String code) async {
    await _registerDevice(language: code);
  }

  Future<void> _showLanguagePreferenceDialog() async {
    if (_isLanguageDialogOpen) return;
    _isLanguageDialogOpen = true;
    String selectedCode = _languageCode;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_t('select_language_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('select_language_body')),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      child: Column(
                        children: _languagePacks
                            .map(
                              (pack) => RadioListTile<String>(
                                value: pack.code,
                                groupValue: selectedCode,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setDialogState(() {
                                    selectedCode = value;
                                  });
                                },
                                title: Text(pack.name),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Close dialog first
                    Navigator.of(context).pop();

                    // Then apply language selection
                    try {
                      await _applyLanguageSelection(
                        selectedCode,
                        markChosen: true,
                      );
                    } catch (e) {
                      // Silent fail - language is saved locally even if server sync fails
                    }
                  },
                  child: Text(_t('continue')),
                ),
              ],
            );
          },
        );
      },
    );

    _isLanguageDialogOpen = false;
  }

  String _t(String key) {
    return _strings[key] ?? _localizationService.translate(_languageCode, key);
  }

  String _tWithVars(String key, Map<String, String> vars) {
    var value = _t(key);
    vars.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
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
      // Get device token for search history
      final deviceToken = await _getDeviceToken();

      // Get current position for location tracking
      final position = await _getCurrentPosition();

      final result = await _apiService.detectImage(
        imageFile: _selectedImage!,
        language: _languageCode,
        deviceToken: deviceToken,
        lat: position?.latitude,
        lng: position?.longitude,
      );

      // Cache the result locally with image
      await SearchCacheService.saveSearch(
        result: result,
        imageFile: _selectedImage,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      setState(() {
        _isLoading = false;
      });

      // Show result screen
      if (mounted) {
        _showDetectionResult(result);
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

  /// Show detection result in full page
  void _showDetectionResult(DetectionResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetectionResultScreen(result: result, languageCode: _languageCode),
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
          // Search History button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchHistoryScreen(),
                ),
              );
            },
            tooltip: 'Search History',
          ),
          // Chat button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
            tooltip: 'Chat Assistant',
          ),
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

                // Nearby alerts banner
                if (!_isFetchingAlerts && _nearbyAlerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t('nearby_alerts_title'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Text(
                                _tWithVars('nearby_alerts_body', {
                                  'count': _nearbyAlerts.length.toString(),
                                }),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
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
