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
  final String name;
  final String imagePath;

  Crop({
    required this.id,
    required this.name,
    required this.imagePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Crop && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Symptom {
  final String id;
  final String name;
  final String description;

  Symptom({
    required this.id,
    required this.name,
    required this.description,
  });
}

class Disease {
  final String id;
  final String name;
  final String description;
  final List<String> remedies;

  Disease({
    required this.id,
    required this.name,
    required this.description,
    required this.remedies,
  });
}

class OfflineMockDataService {
  // ============================================================
  // CROPS (image = assets/images/crops/<crop>.png)
  // ============================================================
  static const Map<String, Map<String, String>> crops = {
    'rice': {
      'name': 'Rice',
      'image': 'assets/images/crops/rice.png',
    },
    'wheat': {
      'name': 'Wheat',
      'image': 'assets/images/crops/wheat.png',
    },
    'maize': {
      'name': 'Maize',
      'image': 'assets/images/crops/maize.png',
    },
    'cotton': {
      'name': 'Cotton',
      'image': 'assets/images/crops/cotton.png',
    },
    'tomato': {
      'name': 'Tomato',
      'image': 'assets/images/crops/tomato.png',
    },
    'potato': {
      'name': 'Potato',
      'image': 'assets/images/crops/potato.png',
    },
    'groundnut': {
      'name': 'Groundnut',
      'image': 'assets/images/crops/groundnut.png',
    },
    'sugarcane': {
      'name': 'Sugarcane',
      'image': 'assets/images/crops/sugarcane.png',
    },
    'chili': {
      'name': 'Chili',
      'image': 'assets/images/crops/chilli.png',
    },
    'banana': {
      'name': 'Banana',
      'image': 'assets/images/crops/banana.png',
    },
  };

  // ============================================================
  // SYMPTOMS
  // ============================================================
  static const Map<String, Map<String, String>> symptoms = {
    'yellow_leaves': {
      'name': 'Yellowing of Leaves',
      'description': 'Leaves gradually turn yellow',
    },
    'brown_spots': {
      'name': 'Brown Spots',
      'description': 'Brown or black spots appear on leaves',
    },
    'wilting': {
      'name': 'Wilting',
      'description': 'Leaves droop and lose firmness',
    },
    'leaf_curl': {
      'name': 'Leaf Curling',
      'description': 'Leaves curl abnormally',
    },
    'stem_lesions': {
      'name': 'Stem Lesions',
      'description': 'Dark lesions appear on stem',
    },
    'insect_presence': {
      'name': 'Insect Infestation',
      'description': 'Insects or larvae visible on plant',
    },
  };

  // ============================================================
  // DISEASES
  // ============================================================
  static const Map<String, Map<String, dynamic>> diseases = {
    'rice_blast': {
      'name': 'Rice Blast',
      'description': 'Fungal disease causing leaf lesions',
      'remedies': [
        'Use resistant varieties',
        'Maintain proper drainage',
        'Avoid excess nitrogen',
      ],
    },
    'wheat_rust': {
      'name': 'Wheat Rust',
      'description': 'Rust-colored pustules on leaves',
      'remedies': [
        'Grow resistant varieties',
        'Remove infected plants',
      ],
    },
    'maize_leaf_blight': {
      'name': 'Maize Leaf Blight',
      'description': 'Elongated brown lesions on leaves',
      'remedies': [
        'Crop rotation',
        'Field sanitation',
      ],
    },
    'cotton_bollworm': {
      'name': 'Cotton Bollworm',
      'description': 'Insect pest damaging bolls',
      'remedies': [
        'Pheromone traps',
        'Encourage predators',
      ],
    },
    'tomato_early_blight': {
      'name': 'Early Blight',
      'description': 'Brown concentric rings on leaves',
      'remedies': [
        'Remove affected leaves',
        'Avoid overhead watering',
      ],
    },
    'potato_late_blight': {
      'name': 'Late Blight',
      'description': 'Rapid leaf decay in wet weather',
      'remedies': [
        'Improve drainage',
        'Remove infected plants',
      ],
    },
    'groundnut_leaf_spot': {
      'name': 'Leaf Spot',
      'description': 'Spots leading to defoliation',
      'remedies': [
        'Crop rotation',
        'Remove residues',
      ],
    },
    'sugarcane_red_rot': {
      'name': 'Red Rot',
      'description': 'Internal cane discoloration',
      'remedies': [
        'Use healthy setts',
        'Remove infected clumps',
      ],
    },
    'chili_leaf_curl': {
      'name': 'Leaf Curl Disease',
      'description': 'Viral disease causing curling',
      'remedies': [
        'Control insect vectors',
        'Remove infected plants',
      ],
    },
    'banana_panama': {
      'name': 'Panama Disease',
      'description': 'Soil-borne wilt disease',
      'remedies': [
        'Use disease-free saplings',
        'Improve soil drainage',
      ],
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
      .map((e) => Crop(
            id: e.key,
            name: e.value['name']!,
            imagePath: e.value['image']!,
          ))
      .toList();

  static List<Symptom> getSymptoms() => symptoms.entries
      .map((e) => Symptom(
            id: e.key,
            name: e.value['name']!,
            description: e.value['description']!,
          ))
      .toList();

  static List<Disease> getDiseasesForCrop(String cropId) {
    final ids = cropDiseases[cropId] ?? [];
    return ids.map((id) {
      final d = diseases[id]!;
      return Disease(
        id: id,
        name: d['name'],
        description: d['description'],
        remedies: List<String>.from(d['remedies']),
      );
    }).toList();
  }

  static List<Symptom> getSymptomsForDisease(String diseaseId) {
    final ids = diseaseSymptoms[diseaseId] ?? [];
    return ids.map((id) {
      final s = symptoms[id]!;
      return Symptom(
        id: id,
        name: s['name']!,
        description: s['description']!,
      );
    }).toList();
  }
}
