/// Simple state management using setState
/// For MVP, we'll use Flutter's built-in setState mechanism
/// No external state management library needed for this simple app

/// App state will be managed at widget level using:
/// - StatefulWidget with setState for local state
/// - Passing callbacks for parent-child communication
/// - Simple boolean flags for loading/error states

/// Example state patterns:
/// 
/// Loading state:
/// bool isLoading = false;
/// 
/// Error state:
/// String? errorMessage;
/// 
/// Data state:
/// DetectionResult? result;
