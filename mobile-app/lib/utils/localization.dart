import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'constants.dart';

class LanguagePack {
  final String code;
  final String name;
  final Map<String, String> strings;

  const LanguagePack({
    required this.code,
    required this.name,
    required this.strings,
  });
}

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._();

  factory LocalizationService() => _instance;

  LocalizationService._();

  final Map<String, LanguagePack> _packs = {};
  bool _loaded = false;

  Future<void> loadAll() async {
    if (_loaded) return;

    for (final filePath in AppConstants.languageFiles) {
      final jsonString = await rootBundle.loadString(filePath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      final code = jsonData['language_code'] as String?;
      final name = jsonData['language_name'] as String?;
      final stringsRaw = jsonData['strings'] as Map<String, dynamic>?;

      if (code == null || name == null || stringsRaw == null) {
        continue;
      }

      final strings = stringsRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      _packs[code] = LanguagePack(code: code, name: name, strings: strings);
    }

    _loaded = true;
  }

  List<LanguagePack> get languagePacks {
    final packs = _packs.values.toList();
    packs.sort((a, b) => a.name.compareTo(b.name));
    return packs;
  }

  bool hasLanguage(String code) => _packs.containsKey(code);

  LanguagePack? getPack(String code) => _packs[code];

  String translate(String code, String key) {
    final pack = _packs[code] ?? _packs[AppConstants.fallbackLanguageCode];
    return pack?.strings[key] ?? key;
  }
}
