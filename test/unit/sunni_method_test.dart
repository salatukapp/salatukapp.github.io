import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_test/flutter_test.dart';
import 'package:salatuk/core/prayer_times/sunni_method.dart';

void main() {
  group('SunniMethod', () {
    test('every value maps to valid CalculationParameters', () {
      for (final m in SunniMethod.values) {
        final p = m.toAdhanParameters();
        expect(p, isA<adhan.CalculationParameters>(), reason: 'for $m');
      }
    });

    test('excludes Shia methods (Tehran, Jafari)', () {
      final codes = SunniMethod.values.map((m) => m.code).toList();
      // Tehran/Jafari are NOT in our Sunni enum.
      expect(codes.contains('TEH'), isFalse);
      expect(codes.contains('JAF'), isFalse);
    });

    test('fromCode round-trips known codes', () {
      for (final m in SunniMethod.values) {
        expect(SunniMethod.fromCode(m.code), equals(m));
      }
    });

    test('fromCode returns Karachi for unknown codes', () {
      expect(SunniMethod.fromCode('XXX'), equals(SunniMethod.karachi));
    });

    test('Umm al-Qura uses 90 min Isha interval', () {
      final p = SunniMethod.ummAlQura.toAdhanParameters();
      expect(p.fajrAngle, 18.5);
      expect(p.ishaInterval, 90);
    });

    test('Karachi uses 18°/18°', () {
      final p = SunniMethod.karachi.toAdhanParameters();
      expect(p.fajrAngle, 18);
      expect(p.ishaAngle, 18);
    });
  });
}
