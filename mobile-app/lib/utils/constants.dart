/// Constants for the ArogyaKrishi app
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://192.168.137.227:8001';

  // App Information
  static const String appName = 'ArogyaKrishi';
  static const String appVersion = '1.0.0';

  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'te', 'hi'];
  static const Map<String, String> languageNames = {
    'en': 'English',
    'te': 'Telugu',
    'hi': 'Hindi',
  };

  // Confidence Thresholds
  static const double lowConfidenceThreshold = 0.5;
  static const double highConfidenceThreshold = 0.8;

  // Image Settings
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 85; // JPEG quality 0-100

  // Disclaimer
  static const String disclaimer =
      'This is an advisory tool only. For critical decisions, '
      'please consult agricultural experts.';
}
