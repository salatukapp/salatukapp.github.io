import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salatuk/data/adhkar/adhkar_repository.dart';

/// Reads the asset directly from disk so this is a real-bundle integration
/// test without requiring the asset loader.
Adhkar _loadFromDisk() {
  final raw = File('assets/adhkar/adhkar.json').readAsStringSync();
  return Adhkar.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

void main() {
  group('Adhkar asset', () {
    test('parses without error', () {
      final a = _loadFromDisk();
      expect(a.version, isNotEmpty);
      expect(a.categories, isNotEmpty);
    });

    test('has all four categories', () {
      final a = _loadFromDisk();
      expect(a.categories.containsKey('morning'), isTrue);
      expect(a.categories.containsKey('evening'), isTrue);
      expect(a.categories.containsKey('afterPrayer'), isTrue);
      expect(a.categories.containsKey('beforeSleep'), isTrue);
    });

    test('entry counts match research baseline', () {
      final a = _loadFromDisk();
      expect(a.categories['morning']!.entries.length, equals(22));
      expect(a.categories['evening']!.entries.length, equals(20));
      expect(a.categories['afterPrayer']!.entries.length, equals(9));
      expect(a.categories['beforeSleep']!.entries.length, equals(13));
    });

    test('every entry has Arabic text and a hadith source', () {
      final a = _loadFromDisk();
      for (final cat in a.categories.values) {
        for (final e in cat.entries) {
          expect(e.arabic, isNotEmpty,
              reason: '${cat.id}/${e.id}: Arabic text missing');
          expect(e.source, isNotEmpty,
              reason: '${cat.id}/${e.id}: source citation missing');
        }
      }
    });

    test('every entry is verified in Hisn al-Muslim', () {
      // Per RESEARCH.md §5.3: "When in doubt: if al-Qahtani didn't include
      // it in Hisn al-Muslim's morning/evening chapter, leave it out."
      final a = _loadFromDisk();
      for (final cat in a.categories.values) {
        for (final e in cat.entries) {
          expect(e.verifiedHisn, isTrue,
              reason:
                  '${cat.id}/${e.id} must be Hisn al-Muslim verified (it isn\'t — exclude it or check the JSON)');
        }
      }
    });

    test('no entry has a weak (Daif) grade', () {
      final a = _loadFromDisk();
      for (final cat in a.categories.values) {
        for (final e in cat.entries) {
          final g = e.grade.toLowerCase();
          expect(g.contains('daif') || g.contains('da\'if') || g.contains('weak'),
              isFalse,
              reason: '${cat.id}/${e.id} appears to be weakly authenticated');
        }
      }
    });

    test('counts are positive integers', () {
      final a = _loadFromDisk();
      for (final cat in a.categories.values) {
        for (final e in cat.entries) {
          expect(e.count, greaterThan(0),
              reason: '${cat.id}/${e.id} has non-positive count');
        }
      }
    });
  });
}
