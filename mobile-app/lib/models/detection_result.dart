/// Model for disease detection API response
class DetectionResult {
  final String crop;
  final String disease;
  final double confidence;
  final List<String> remedies;
  final String language;

  DetectionResult({
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.remedies,
    required this.language,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      crop: json['crop'] as String,
      disease: json['disease'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      remedies: List<String>.from(json['remedies'] as List),
      language: json['language'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'remedies': remedies,
      'language': language,
    };
  }
}
