# ArogyaKrishi - Crop Disease Detection App

ArogyaKrishi is a mobile application designed to help farmers detect crop diseases using image recognition and receive actionable remedies. This is the Android MVP built with Flutter.

## Features

- 📷 **Image Capture & Gallery Selection** - Take photos or select from gallery
- 🔍 **Disease Detection** - Upload images for AI-powered crop disease detection
- 💊 **Remedy Recommendations** - Get actionable remedies for detected diseases
- 🗺️ **Nearby Alerts** - View disease alerts in your vicinity
- 🌐 **Multi-language Support** - English, Telugu, and Hindi
- 📴 **Offline Mode** - Basic disease diagnosis without internet
- 🔔 **Local Reminders** - Set reminders for treatment schedules

## Prerequisites

- **Flutter**: 3.38.8 or higher (stable channel)
- **Dart**: 3.10.7 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Android SDK**: API level 21 (Android 5.0) or higher

## Setup Instructions

1. **Clone the repository**

   ```bash
   cd mobile-app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Backend URL**

   Update the API base URL in `lib/services/api_service.dart`:

   ```dart
   static const String baseUrl = 'http://YOUR_BACKEND_URL:8000';
   ```

4. **Connect Android device or start emulator**
   ```bash
   flutter devices
   ```

## Running the App

### Development Mode

```bash
flutter run
```

### Release Mode (APK)

```bash
flutter build apk --release
```

The APK will be available at: `build/app/outputs/flutter-apk/app-release.apk`

### Debug Build

```bash
flutter build apk --debug
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── detection_result.dart
│   └── nearby_alert.dart
├── screens/                  # UI screens
│   └── home_screen.dart
├── services/                 # Business logic
│   ├── api_service.dart
│   └── image_service.dart
└── utils/                    # Utilities & constants
    ├── constants.dart
    └── state_management.dart
```

## Permissions

The app requires the following Android permissions:

- `INTERNET` - API communication
- `CAMERA` - Capture plant images
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` - Gallery access
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` - Nearby alerts (optional)

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Building for Production

1. **Update version** in `pubspec.yaml`

   ```yaml
   version: 1.0.0+1
   ```

2. **Build release APK**

   ```bash
   flutter build apk --release
   ```

3. **Build App Bundle** (for Google Play)
   ```bash
   flutter build appbundle --release
   ```

## Troubleshooting

### Common Issues

**Issue**: Permission denied errors

- **Solution**: Grant camera/storage permissions in device settings

**Issue**: Network errors

- **Solution**: Ensure backend URL is correct and server is running

**Issue**: Build failures

- **Solution**: Run `flutter clean && flutter pub get`

### Useful Commands

```bash
# Clean build cache
flutter clean

# Check Flutter installation
flutter doctor

# Check for outdated packages
flutter pub outdated

# Analyze code for issues
flutter analyze
```

## Development Checklist

See `../agent-context/checklist-android.md` for the full development checklist and progress tracking.

## Backend Integration

This app connects to the ArogyaKrishi Python FastAPI backend. See `../app/` directory for backend setup.

### API Endpoints

- `POST /detect-image` - Upload image for disease detection
- `GET /nearby-alerts` - Fetch nearby disease alerts

See `../agent-context/api-contracts.md` for detailed API documentation.

## Contributing

This is an MVP project for a 24-hour hackathon. For contribution guidelines, please refer to the main project README.

## License

[Add license information]

## Support

For issues and questions, please contact the development team.
