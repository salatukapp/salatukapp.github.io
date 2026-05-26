import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Adhkar {
  final String version;
  final String lastUpdated;
  final String source;
  final Map<String, AdhkarCategory> categories;

  const Adhkar({
    required this.version,
    required this.lastUpdated,
    required this.source,
    required this.categories,
  });

  factory Adhkar.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, AdhkarCategory.fromJson(v as Map<String, dynamic>)),
    );
    return Adhkar(
      version: json['version'] as String? ?? '0.0.0',
      lastUpdated: json['lastUpdated'] as String? ?? '',
      source: json['source'] as String? ?? '',
      categories: cats,
    );
  }
}

class AdhkarCategory {
  final String id;
  final String titleEn;
  final String titleAr;
  final String subtitle;
  final List<DhikrEntry> entries;

  const AdhkarCategory({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.subtitle,
    required this.entries,
  });

  factory AdhkarCategory.fromJson(Map<String, dynamic> json) {
    final list = (json['entries'] as List<dynamic>? ?? [])
        .map((e) => DhikrEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return AdhkarCategory(
      id: json['id'] as String,
      titleEn: json['titleEn'] as String,
      titleAr: json['titleAr'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      entries: list,
    );
  }
}

class DhikrEntry {
  final String id;
  final String titleEn;
  final String titleAr;
  final String arabic;
  final String transliteration;
  final String translation;
  final int count;
  final String countDescription;
  final String source;
  final String grade;
  final bool verifiedHisn;
  final bool verifiedNawawi;
  final bool verifiedPrimary;

  const DhikrEntry({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.count,
    required this.countDescription,
    required this.source,
    required this.grade,
    required this.verifiedHisn,
    required this.verifiedNawawi,
    required this.verifiedPrimary,
  });

  factory DhikrEntry.fromJson(Map<String, dynamic> json) {
    final v = json['verified'] as Map<String, dynamic>? ?? const {};
    return DhikrEntry(
      id: json['id'] as String,
      titleEn: json['titleEn'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 1,
      countDescription: json['countDescription'] as String? ?? '',
      source: json['source'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      verifiedHisn: v['hisn'] as bool? ?? false,
      verifiedNawawi: v['nawawi'] as bool? ?? false,
      verifiedPrimary: v['primary'] as bool? ?? false,
    );
  }
}

class AdhkarRepository {
  Adhkar? _cache;

  Future<Adhkar> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/adhkar/adhkar.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = Adhkar.fromJson(json);
    return _cache!;
  }
}
