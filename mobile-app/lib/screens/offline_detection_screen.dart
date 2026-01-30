import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';
import '../services/image_asset_service.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';

/// Offline detection screen with crop -> symptom -> disease -> remedy flow
class OfflineDetectionScreen extends StatefulWidget {
  final String? initialLanguageCode;

  const OfflineDetectionScreen({super.key, this.initialLanguageCode});

  @override
  State<OfflineDetectionScreen> createState() => _OfflineDetectionScreenState();
}

class _OfflineDetectionScreenState extends State<OfflineDetectionScreen> {
  final LocalizationService _localizationService = LocalizationService();

  String _languageCode = AppConstants.fallbackLanguageCode;
  Map<String, String> _strings = {};
  List<LanguagePack> _languagePacks = [];

  // Navigation state
  Crop? _selectedCrop;
  List<Symptom> _selectedSymptoms = [];
  Disease? _detectedDisease;

  @override
  void initState() {
    super.initState();
    _languageCode =
        widget.initialLanguageCode ?? AppConstants.fallbackLanguageCode;
    _loadLocalizationPacks();
  }

  Future<void> _loadLocalizationPacks() async {
    await _localizationService.loadAll();
    final packs = _localizationService.languagePacks;
    if (!mounted) return;
    setState(() {
      _languagePacks = packs;
      if (!_localizationService.hasLanguage(_languageCode) &&
          packs.isNotEmpty) {
        _languageCode = packs.first.code;
      }
      _strings = _localizationService.getPack(_languageCode)?.strings ?? {};
    });
  }

  void _setLanguage(String code) {
    setState(() {
      _languageCode = code;
      _strings = _localizationService.getPack(_languageCode)?.strings ?? {};
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('offline_diagnosis')),
        centerTitle: true,
        elevation: 0,
        actions: [
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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_detectedDisease != null) {
      return _buildDiseaseResult();
    } else if (_selectedCrop != null && _selectedSymptoms.isNotEmpty) {
      return _buildSymptomSelection();
    } else if (_selectedCrop != null) {
      return _buildSymptomSelection();
    } else {
      return _buildCropSelection();
    }
  }

  /// Step 1: Select Crop
  Widget _buildCropSelection() {
    final crops = OfflineMockDataService.getCrops();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              _t('offline_select_crop_title'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _t('offline_select_crop_subtitle'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
          ],
        ),

        // Crop grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: crops.length,
          itemBuilder: (context, index) {
            final crop = crops[index];
            return _buildCropCard(crop);
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCropCard(Crop crop) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCrop = crop;
          _selectedSymptoms = [];
          _detectedDisease = null;
        });
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            // Background image or gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green[300]!, Colors.green[600]!],
                ),
              ),
            ),
            // Crop image or fallback
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ImageAssetService.buildCropImage(
                    cropId: crop.id,
                    cropName: _t(crop.nameKey),
                    size: 80,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _t(crop.nameKey),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 2: Select Symptoms
  Widget _buildSymptomSelection() {
    final availableDiseases = OfflineMockDataService.getDiseasesForCrop(
      _selectedCrop!.id,
    );

    // Get all possible symptoms from diseases for this crop
    final possibleSymptoms = <Symptom>{};
    for (var disease in availableDiseases) {
      final symptoms = OfflineMockDataService.getSymptomsForDisease(disease.id);
      possibleSymptoms.addAll(symptoms);
    }

    // Convert to sorted list for consistent ordering
    final symptomList = possibleSymptoms.toList()
      ..sort((a, b) => _t(a.nameKey).compareTo(_t(b.nameKey)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with back button
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedCrop = null;
                  _selectedSymptoms = [];
                });
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('offline_identify_symptoms_title'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _t(_selectedCrop!.nameKey),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _tWithVars('offline_symptom_prompt', {
            'crop': _t(_selectedCrop!.nameKey),
          }),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Symptoms grid - image-centric
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: symptomList.length,
          itemBuilder: (context, index) {
            final symptom = symptomList[index];
            final isSelected = _selectedSymptoms.contains(symptom);
            return _buildSymptomCard(symptom, isSelected);
          },
        ),

        const SizedBox(height: 24),

        // Analyze button
        if (_selectedSymptoms.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  _tWithVars('offline_selected_symptoms', {
                    'symptoms': _selectedSymptoms
                        .map((s) => _t(s.nameKey))
                        .join(', '),
                  }),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _analyzeSymptoms,
                icon: const Icon(Icons.search),
                label: Text(_t('offline_analyze_symptoms')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              _t('offline_select_symptoms_hint'),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSymptomCard(Symptom symptom, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSymptoms.remove(symptom);
          } else {
            _selectedSymptoms.add(symptom);
          }
        });
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.green[600]! : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        color: isSelected ? Colors.green[50] : Colors.white,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image background
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: ImageAssetService.buildSymptomImage(
                symptomId: symptom.id,
                imagePath: symptom.imagePath,
                symptomName: _t(symptom.nameKey),
                size: 200,
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkmark indicator
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  // Text at bottom
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t(symptom.nameKey),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t(symptom.descriptionKey),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 3: Show Disease Result
  Widget _buildDiseaseResult() {
    final disease = _detectedDisease!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back button
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _detectedDisease = null;
              });
            },
          ),
        ),

        // Disease card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.orange[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Colors.orange[700],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('offline_possible_disease'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t(disease.nameKey),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _t(disease.descriptionKey),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Remedies section
        Text(
          _t('offline_recommended_remedies'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        for (final entry in disease.remedyKeys.asMap().entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t(entry.value),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t('offline_disclaimer'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _detectedDisease = null;
                    _selectedSymptoms = [];
                    _selectedCrop = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: Text(_t('offline_start_over')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_t('offline_share_coming_soon'))),
                  );
                },
                icon: const Icon(Icons.share),
                label: Text(_t('offline_share')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Analyze symptoms and find matching disease
  void _analyzeSymptoms() {
    final availableDiseases = OfflineMockDataService.getDiseasesForCrop(
      _selectedCrop!.id,
    );

    // Score diseases based on symptom matches
    var diseaseScores = <String, int>{};

    for (var disease in availableDiseases) {
      final diseaseSymptoms = OfflineMockDataService.getSymptomsForDisease(
        disease.id,
      );
      int matchCount = 0;

      for (var symptom in _selectedSymptoms) {
        if (diseaseSymptoms.any((s) => s.id == symptom.id)) {
          matchCount++;
        }
      }

      diseaseScores[disease.id] = matchCount;
    }

    // Find disease with highest match
    String? bestMatchId;
    int maxMatches = 0;

    diseaseScores.forEach((diseaseId, matches) {
      if (matches > maxMatches) {
        maxMatches = matches;
        bestMatchId = diseaseId;
      }
    });

    if (bestMatchId != null && maxMatches > 0) {
      final disease = OfflineMockDataService.getDiseaseById(bestMatchId!);
      setState(() {
        _detectedDisease = disease;
      });
    } else {
      // No match found
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t('offline_no_match'))));
    }
  }
}
