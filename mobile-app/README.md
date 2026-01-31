# ArogyaKrishi - Crop Disease Detection App

ArogyaKrishi is a mobile application designed to help farmers detect crop diseases using image recognition and receive actionable remedies. This is the Android MVP built with Flutter.

## Features

- 📷 **Image Capture & Gallery Selection** - Take photos or select from gallery
- 🔍 **Disease Detection** - Upload images for AI-powered crop disease detection (requires backend)
- 💊 **Remedy Recommendations** - Get actionable remedies for detected diseases
- 🗺️ **Nearby Alerts** - View disease alerts in your vicinity
- 📜 **Search History** - Browse and review previous disease searches ✨ NEW!
- 🌐 **Multi-language Support** - English, Telugu, and Hindi
- 📴 **Offline Mode** - Complete disease diagnosis without internet
- 🔔 **Local Reminders** - Set reminders for treatment schedules

## Search History (NEW!)

The app now tracks all your disease searches, allowing you to review past detections and their results.

### How to Use Search History

1. **Access History** - Tap the history icon (🕐) in the top app bar
2. **Browse Searches** - Scroll through your previous disease detections
3. **View Details** - Tap any search to see full details including:
   - Disease name and crop type
   - Confidence score
   - Date and time of search
   - Location (if available)
   - Language used
4. **Delete Searches** - Swipe left on any item to delete it
5. **Clear All** - Tap the "Clear All" button to remove all history

### Features

- **Automatic Tracking** - All disease detections are automatically saved
- **Device-Specific** - History is tracked per device using device ID
- **Pagination** - Loads 20 searches at a time for better performance
- **Pull to Refresh** - Swipe down to refresh your history
- **Color-Coded Confidence** - Visual indicators for detection confidence:
  - 🟢 Green: 80%+ (High confidence)
  - 🟠 Orange: 60-80% (Medium confidence)
  - 🔴 Red: Below 60% (Low confidence)

## Offline Mode

The app now includes a complete offline diagnosis system that works without an internet connection. This allows farmers to perform crop disease diagnosis anywhere, anytime.

### How to Use Offline Mode

1. **Open the app** - The app automatically detects your internet connection
2. **When offline** - You'll see an "Offline" badge in the app bar and an offline notification
3. **Click "Offline Diagnosis"** - This opens the offline diagnosis wizard
4. **Follow these steps:**
   - **Select your crop** - Choose from available crops (Rice, Wheat, Cotton, Tomato, Potato, etc.)
   - **Select symptoms** - Check all symptoms you observe on your crop
   - **Get diagnosis** - The app analyzes symptoms and suggests the likely disease
   - **View remedies** - Get step-by-step remedy recommendations

### Offline Mode Data Structure

The offline diagnosis system uses mock data that is easy to customize. All data is stored in `lib/services/mock_data_service.dart`.

#### Adding or Modifying Crops

Edit the `crops` map in `mock_data_service.dart`:

```dart
static const Map<String, String> crops = {
  'rice': 'Rice',
  'wheat': 'Wheat',
  'cotton': 'Cotton',
  'tomato': 'Tomato',
  'potato': 'Potato',
  'groundnut': 'Groundnut',
  'sugarcane': 'Sugarcane',
  'maize': 'Maize',
  // Add your crop here
  'new_crop_id': 'Display Name',
};
```

#### Adding or Modifying Symptoms

Edit the `symptoms` map in `mock_data_service.dart`:

```dart
static const Map<String, Map<String, String>> symptoms = {
  'yellow_leaves': {
    'name': 'Yellow Leaves',
    'description': 'Leaves are turning yellow',
  },
  // Add your symptom here
  'new_symptom_id': {
    'name': 'Symptom Display Name',
    'description': 'Brief description of the symptom',
  },
};
```

#### Adding or Modifying Diseases

Edit the `diseases` map in `mock_data_service.dart`:

```dart
static const Map<String, Map<String, dynamic>> diseases = {
  'blast': {
    'name': 'Blast',
    'description': 'Fungal disease affecting rice',
    'remedies': [
      'Spray with Mancozeb (0.2%) or Carbendazim (0.1%)',
      'Remove infected leaves and burn them',
      'Ensure proper drainage in fields',
      'Avoid over-watering and heavy nitrogen application',
    ],
  },
  // Add your disease here
  'new_disease_id': {
    'name': 'Disease Display Name',
    'description': 'Description of the disease and its effects',
    'remedies': [
      'Remedy step 1',
      'Remedy step 2',
      'Remedy step 3',
      'Remedy step 4',
    ],
  },
};
```

#### Linking Crops to Diseases

Edit the `cropDiseases` map to define which diseases affect which crops:

```dart
static const Map<String, List<String>> cropDiseases = {
  'rice': ['blast', 'leaf_spot', 'yellowing_virus'],
  'wheat': ['leaf_spot', 'powdery_mildew'],
  // Add mapping for your crop
  'your_crop_id': ['disease_id_1', 'disease_id_2', 'disease_id_3'],
};
```

#### Linking Symptoms to Diseases

Edit the `diseaseSymptoms` map to define which symptoms indicate which diseases:

```dart
static const Map<String, List<String>> diseaseSymptoms = {
  'blast': ['brown_spots', 'wilting'],
  'leaf_spot': ['brown_spots', 'yellow_leaves'],
  // Add mapping for your disease
  'your_disease_id': ['symptom_id_1', 'symptom_id_2', 'symptom_id_3'],
};
```

### Example: Adding New Crop and Disease Data

Let's say you want to add a new crop "Chili" with a disease "Leaf Curl":

1. **Add the crop** to `crops` map:

   ```dart
   'chili': 'Chili',
   ```

2. **Add symptoms** to `symptoms` map (if new):

   ```dart
   'severe_wilting': {
     'name': 'Severe Wilting',
     'description': 'Severe drooping and wilting of leaves',
   },
   ```

3. **Add the disease** to `diseases` map:

   ```dart
   'chili_leaf_curl': {
     'name': 'Chili Leaf Curl',
     'description': 'Viral disease causing severe leaf curling',
     'remedies': [
       'Remove and destroy infected plants',
       'Control insect vectors with insecticide',
       'Use yellow sticky traps for monitoring',
       'Plant resistant varieties',
     ],
   },
   ```

4. **Map crop to disease** in `cropDiseases`:

   ```dart
   'chili': ['chili_leaf_curl', 'powdery_mildew'],
   ```

5. **Map disease to symptoms** in `diseaseSymptoms`:

   ```dart
   'chili_leaf_curl': ['leaf_curl', 'severe_wilting'],
   ```

6. **Save and run:**
   ```bash
   flutter pub get
   flutter run
   ```

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

3. **Configure Backend URL** (for online mode)

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
├── main.dart                           # App entry point
├── models/                             # Data models
│   ├── detection_result.dart
│   └── nearby_alert.dart
├── screens/                            # UI screens
│   ├── home_screen.dart
│   └── offline_detection_screen.dart   # NEW: Offline diagnosis UI
├── services/                           # Business logic
│   ├── api_service.dart
│   ├── image_service.dart
│   ├── mock_data_service.dart          # NEW: Offline data
│   └── offline_detector.dart           # NEW: Connectivity detection
└── utils/                              # Utilities & constants
    ├── constants.dart
    └── state_management.dart
```

## Permissions

The app requires the following Android permissions:

- `INTERNET` - API communication
- `CAMERA` - Capture plant images
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` - Gallery access
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` - Nearby alerts (optional)
- `CHANGE_NETWORK_STATE` (implicit) - Detect network connectivity

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

**Issue**: Offline mode not appearing

- **Solution**: Disable internet in device settings or disable WiFi/mobile data

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

## Backend Integration (When Ready)

This app can connect to the ArogyaKrishi Python FastAPI backend for online image detection. See `../app/` directory for backend setup.

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
