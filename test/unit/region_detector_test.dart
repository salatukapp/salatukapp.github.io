import 'package:flutter_test/flutter_test.dart';
import 'package:salatuk/core/location/region_detector.dart';
import 'package:salatuk/core/prayer_times/sunni_method.dart';

void main() {
  group('RegionDetector', () {
    test('Saudi Arabia → Umm al-Qura', () {
      expect(
        RegionDetector.recommendedMethod(latitude: 24.7136, longitude: 46.6753), // Riyadh
        equals(SunniMethod.ummAlQura),
      );
    });

    test('Turkey → Diyanet', () {
      expect(
        RegionDetector.recommendedMethod(latitude: 41.0082, longitude: 28.9784), // Istanbul
        equals(SunniMethod.turkiye),
      );
    });

    test('Egypt → Egyptian', () {
      expect(
        RegionDetector.recommendedMethod(latitude: 30.0444, longitude: 31.2357), // Cairo
        equals(SunniMethod.egyptian),
      );
    });

    test('Pakistan → Karachi', () {
      expect(
        RegionDetector.recommendedMethod(latitude: 24.8607, longitude: 67.0011), // Karachi
        equals(SunniMethod.karachi),
      );
    });

    test('Indonesia → Indonesian', () {
      expect(
        RegionDetector.recommendedMethod(latitude: -6.2088, longitude: 106.8456), // Jakarta
        equals(SunniMethod.indonesian),
      );
    });

    test('Singapore → Singapore', () {
      expect(
        RegionDetector.recommendedMethod(latitude: 1.3521, longitude: 103.8198), // Singapore
        equals(SunniMethod.singapore),
      );
    });

    test('USA → ISNA', () {
      expect(
        RegionDetector.recommendedMethod(latitude: 40.7128, longitude: -74.0060), // NYC
        equals(SunniMethod.northAmerica),
      );
    });

    test('UK → MoonsightingCommittee', () {
      expect(
        RegionDetector.recommendedMethod(latitude: 51.5074, longitude: -0.1278), // London
        equals(SunniMethod.moonsightingCommittee),
      );
    });

    test('Morocco → Morocco', () {
      expect(
        RegionDetector.recommendedMethod(latitude: 33.5731, longitude: -7.5898), // Casablanca
        equals(SunniMethod.morocco),
      );
    });

    test('high latitude (Reykjavik, 64°N) → MoonsightingCommittee', () {
      expect(
        RegionDetector.recommendedMethod(latitude: 64.1265, longitude: -21.8174),
        equals(SunniMethod.moonsightingCommittee),
      );
    });

    test('Pacific Ocean (no match) → MWL fallback', () {
      expect(
        RegionDetector.recommendedMethod(latitude: 0, longitude: -160),
        equals(SunniMethod.muslimWorldLeague),
      );
    });
  });
}
