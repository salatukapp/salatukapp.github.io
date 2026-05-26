import 'package:adhan_dart/adhan_dart.dart';

void main() {
  final cities = <String, List<double>>{
    'London': [51.5074, -0.1278],
    'NYC': [40.7128, -74.0060],
    'Toronto': [43.6532, -79.3832],
    'Jakarta': [-6.2088, 106.8456],
    'Sydney': [-33.8688, 151.2093],
    'Istanbul': [41.0082, 28.9784],
    'Karachi': [24.8607, 67.0011],
    'Cairo': [30.0444, 31.2357],
    'KL': [3.1390, 101.6869],
    'CapeTown': [-33.9249, 18.4241],
  };
  cities.forEach((name, c) {
    final b = Qibla.qibla(Coordinates(c[0], c[1]));
    print('$name: ${b.toStringAsFixed(2)}');
  });
}
