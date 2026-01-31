/// Model for disease search history item
class DiseaseSearch {
  final int id;
  final String crop;
  final String disease;
  final double confidence;
  final double? latitude;
  final double? longitude;
  final String language;
  final DateTime createdAt;

  DiseaseSearch({
    required this.id,
    required this.crop,
    required this.disease,
    required this.confidence,
    this.latitude,
    this.longitude,
    required this.language,
    required this.createdAt,
  });

  factory DiseaseSearch.fromJson(Map<String, dynamic> json) {
    return DiseaseSearch(
      id: json['id'] as int,
      crop: json['crop'] as String,
      disease: json['disease'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      language: json['language'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'latitude': latitude,
      'longitude': longitude,
      'language': language,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Model for search history response
class SearchHistoryResponse {
  final List<DiseaseSearch> searches;
  final int totalCount;

  SearchHistoryResponse({required this.searches, required this.totalCount});

  factory SearchHistoryResponse.fromJson(Map<String, dynamic> json) {
    return SearchHistoryResponse(
      searches: (json['searches'] as List)
          .map((item) => DiseaseSearch.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['total_count'] as int,
    );
  }
}

/// Model for unique disease summary
class UniqueDisease {
  final String disease;
  final String crop;
  final DateTime lastSearched;
  final int searchCount;

  UniqueDisease({
    required this.disease,
    required this.crop,
    required this.lastSearched,
    required this.searchCount,
  });

  factory UniqueDisease.fromJson(Map<String, dynamic> json) {
    return UniqueDisease(
      disease: json['disease'] as String,
      crop: json['crop'] as String,
      lastSearched: DateTime.parse(json['last_searched'] as String),
      searchCount: json['search_count'] as int,
    );
  }
}
