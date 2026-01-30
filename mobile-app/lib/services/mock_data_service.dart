/// Offline Mock Data Service for Crop Disease Detection
///
/// Uses crop + symptoms for offline heuristic disease identification.
/// Images are mapped ONE-TO-ONE with crops.
///
/// NOTE:
/// - This is NOT diagnosis
/// - Remedies are general guidance
/// - No chemical dosages or guarantees

class Crop {
  final String id;
  final String nameKey;
  final String imagePath;

  Crop({required this.id, required this.nameKey, required this.imagePath});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Crop && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Symptom {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final String imagePath;

  Symptom({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.imagePath,
  });
}

class Disease {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final List<String> remedyKeys;

  Disease({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.remedyKeys,
  });
}

class OfflineMockDataService {
  // ============================================================
  // CROPS (image = assets/images/crops/<crop>.png)
  // ============================================================
  static const Map<String, Map<String, String>> crops = {
    'rice': {'nameKey': 'crop.rice', 'image': 'assets/images/crops/rice.png'},
    'wheat': {
      'nameKey': 'crop.wheat',
      'image': 'assets/images/crops/wheat.png',
    },
    'maize': {
      'nameKey': 'crop.maize',
      'image': 'assets/images/crops/maize.png',
    },
    'cotton': {
      'nameKey': 'crop.cotton',
      'image': 'assets/images/crops/cotton.png',
    },
    'tomato': {
      'nameKey': 'crop.tomato',
      'image': 'assets/images/crops/tomato.png',
    },
    'potato': {
      'nameKey': 'crop.potato',
      'image': 'assets/images/crops/potato.png',
    },
    'groundnut': {
      'nameKey': 'crop.groundnut',
      'image': 'assets/images/crops/groundnut.png',
    },
    'sugarcane': {
      'nameKey': 'crop.sugarcane',
      'image': 'assets/images/crops/sugarcane.png',
    },
    'chili': {
      'nameKey': 'crop.chili',
      'image': 'assets/images/crops/chilli.png',
    },
    'banana': {
      'nameKey': 'crop.banana',
      'image': 'assets/images/crops/banana.png',
    },
  };

  // ============================================================
  // SYMPTOMS (image = assets/images/symptoms/<symptom>.png)
  // ============================================================
  static const Map<String, Map<String, String>> symptoms = {
    'yellow_leaves': {
      'nameKey': 'symptom.yellow_leaves.name',
      'descriptionKey': 'symptom.yellow_leaves.desc',
      'image': 'assets/images/symptoms/early_blight.png',
    },
    'brown_spots': {
      'nameKey': 'symptom.brown_spots.name',
      'descriptionKey': 'symptom.brown_spots.desc',
      'image': 'assets/images/symptoms/early_blight.png',
    },
    'wilting': {
      'nameKey': 'symptom.wilting.name',
      'descriptionKey': 'symptom.wilting.desc',
      'image': 'assets/images/symptoms/late_blight.png',
    },
    'leaf_curl': {
      'nameKey': 'symptom.leaf_curl.name',
      'descriptionKey': 'symptom.leaf_curl.desc',
      'image': 'assets/images/symptoms/leaf_curl_disease.png',
    },
    'stem_lesions': {
      'nameKey': 'symptom.stem_lesions.name',
      'descriptionKey': 'symptom.stem_lesions.desc',
      'image': 'assets/images/symptoms/rice_blast.png',
    },
    'insect_presence': {
      'nameKey': 'symptom.insect_presence.name',
      'descriptionKey': 'symptom.insect_presence.desc',
      'image': 'assets/images/symptoms/cotton_bollworm.png',
    },
  };

  // ============================================================
  // DISEASES
  // ============================================================
  static const Map<String, Map<String, dynamic>> diseases = {
    'rice_blast': {
      'nameKey': 'disease.rice_blast.name',
      'descriptionKey': 'disease.rice_blast.desc',
      'remedyKeys': [
        'remedy.rice_blast.1',
        'remedy.rice_blast.2',
        'remedy.rice_blast.3',
      ],
    },
    'wheat_rust': {
      'nameKey': 'disease.wheat_rust.name',
      'descriptionKey': 'disease.wheat_rust.desc',
      'remedyKeys': ['remedy.wheat_rust.1', 'remedy.wheat_rust.2'],
    },
    'maize_leaf_blight': {
      'nameKey': 'disease.maize_leaf_blight.name',
      'descriptionKey': 'disease.maize_leaf_blight.desc',
      'remedyKeys': [
        'remedy.maize_leaf_blight.1',
        'remedy.maize_leaf_blight.2',
      ],
    },
    'cotton_bollworm': {
      'nameKey': 'disease.cotton_bollworm.name',
      'descriptionKey': 'disease.cotton_bollworm.desc',
      'remedyKeys': ['remedy.cotton_bollworm.1', 'remedy.cotton_bollworm.2'],
    },
    'tomato_early_blight': {
      'nameKey': 'disease.tomato_early_blight.name',
      'descriptionKey': 'disease.tomato_early_blight.desc',
      'remedyKeys': [
        'remedy.tomato_early_blight.1',
        'remedy.tomato_early_blight.2',
      ],
    },
    'potato_late_blight': {
      'nameKey': 'disease.potato_late_blight.name',
      'descriptionKey': 'disease.potato_late_blight.desc',
      'remedyKeys': [
        'remedy.potato_late_blight.1',
        'remedy.potato_late_blight.2',
      ],
    },
    'groundnut_leaf_spot': {
      'nameKey': 'disease.groundnut_leaf_spot.name',
      'descriptionKey': 'disease.groundnut_leaf_spot.desc',
      'remedyKeys': [
        'remedy.groundnut_leaf_spot.1',
        'remedy.groundnut_leaf_spot.2',
      ],
    },
    'sugarcane_red_rot': {
      'nameKey': 'disease.sugarcane_red_rot.name',
      'descriptionKey': 'disease.sugarcane_red_rot.desc',
      'remedyKeys': [
        'remedy.sugarcane_red_rot.1',
        'remedy.sugarcane_red_rot.2',
      ],
    },
    'chili_leaf_curl': {
      'nameKey': 'disease.chili_leaf_curl.name',
      'descriptionKey': 'disease.chili_leaf_curl.desc',
      'remedyKeys': ['remedy.chili_leaf_curl.1', 'remedy.chili_leaf_curl.2'],
    },
    'banana_panama': {
      'nameKey': 'disease.banana_panama.name',
      'descriptionKey': 'disease.banana_panama.desc',
      'remedyKeys': ['remedy.banana_panama.1', 'remedy.banana_panama.2'],
    },
  };

  // ============================================================
  // CROP → DISEASE
  // ============================================================
  static const Map<String, List<String>> cropDiseases = {
    'rice': ['rice_blast'],
    'wheat': ['wheat_rust'],
    'maize': ['maize_leaf_blight'],
    'cotton': ['cotton_bollworm'],
    'tomato': ['tomato_early_blight'],
    'potato': ['potato_late_blight'],
    'groundnut': ['groundnut_leaf_spot'],
    'sugarcane': ['sugarcane_red_rot'],
    'chili': ['chili_leaf_curl'],
    'banana': ['banana_panama'],
  };

  // ============================================================
  // DISEASE → SYMPTOMS
  // ============================================================
  static const Map<String, List<String>> diseaseSymptoms = {
    'rice_blast': ['brown_spots', 'wilting'],
    'wheat_rust': ['brown_spots'],
    'maize_leaf_blight': ['brown_spots'],
    'cotton_bollworm': ['insect_presence'],
    'tomato_early_blight': ['brown_spots', 'yellow_leaves'],
    'potato_late_blight': ['brown_spots', 'wilting'],
    'groundnut_leaf_spot': ['brown_spots'],
    'sugarcane_red_rot': ['stem_lesions', 'wilting'],
    'chili_leaf_curl': ['leaf_curl', 'yellow_leaves'],
    'banana_panama': ['wilting', 'yellow_leaves'],
  };

  // ============================================================
  // HELPERS
  // ============================================================

  static List<Crop> getCrops() => crops.entries
      .map(
        (e) => Crop(
          id: e.key,
          nameKey: e.value['nameKey']!,
          imagePath: e.value['image']!,
        ),
      )
      .toList();

  static List<Symptom> getSymptoms() => symptoms.entries
      .map(
        (e) => Symptom(
          id: e.key,
          nameKey: e.value['nameKey']!,
          descriptionKey: e.value['descriptionKey']!,
          imagePath: e.value['image']!,
        ),
      )
      .toList();

  static List<Disease> getDiseasesForCrop(String cropId) {
    final ids = cropDiseases[cropId] ?? [];
    return ids.map((id) {
      final d = diseases[id]!;
      return Disease(
        id: id,
        nameKey: d['nameKey'],
        descriptionKey: d['descriptionKey'],
        remedyKeys: List<String>.from(d['remedyKeys']),
      );
    }).toList();
  }

  static List<Symptom> getSymptomsForDisease(String diseaseId) {
    final ids = diseaseSymptoms[diseaseId] ?? [];
    return ids.map((id) {
      final s = symptoms[id]!;
      return Symptom(
        id: id,
        nameKey: s['nameKey']!,
        descriptionKey: s['descriptionKey']!,
        imagePath: s['image']!,
      );
    }).toList();
  }

  static Disease getDiseaseById(String diseaseId) {
    final d = diseases[diseaseId]!;
    return Disease(
      id: diseaseId,
      nameKey: d['nameKey'],
      descriptionKey: d['descriptionKey'],
      remedyKeys: List<String>.from(d['remedyKeys']),
    );
  }
}
