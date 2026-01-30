/// Model for nearby alerts API response
class NearbyAlert {
  final String disease;
  final double distanceKm;
  final DateTime timestamp;

  NearbyAlert({
    required this.disease,
    required this.distanceKm,
    required this.timestamp,
  });

  factory NearbyAlert.fromJson(Map<String, dynamic> json) {
    return NearbyAlert(
      disease: json['disease'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease': disease,
      'distance_km': distanceKm,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class NearbyAlertsResponse {
  final List<NearbyAlert> alerts;

  NearbyAlertsResponse({required this.alerts});

  factory NearbyAlertsResponse.fromJson(Map<String, dynamic> json) {
    return NearbyAlertsResponse(
      alerts: (json['alerts'] as List)
          .map((alert) => NearbyAlert.fromJson(alert as Map<String, dynamic>))
          .toList(),
    );
  }
}
