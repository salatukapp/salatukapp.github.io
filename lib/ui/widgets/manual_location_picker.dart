import 'package:flutter/material.dart';

import '../../core/storage/settings_store.dart';

/// Preset list of major cities. Hand-curated for Muslim-significant locations.
class PresetCity {
  final String label;
  final double latitude;
  final double longitude;
  const PresetCity(this.label, this.latitude, this.longitude);
}

const List<PresetCity> _presets = [
  PresetCity('Makkah, Saudi Arabia', 21.4225, 39.8262),
  PresetCity('Madinah, Saudi Arabia', 24.4686, 39.6142),
  PresetCity('Riyadh, Saudi Arabia', 24.7136, 46.6753),
  PresetCity('Beirut, Lebanon', 33.8938, 35.5018),
  PresetCity('Cairo, Egypt', 30.0444, 31.2357),
  PresetCity('Istanbul, Türkiye', 41.0082, 28.9784),
  PresetCity('Karachi, Pakistan', 24.8607, 67.0011),
  PresetCity('Lahore, Pakistan', 31.5204, 74.3587),
  PresetCity('Dhaka, Bangladesh', 23.8103, 90.4125),
  PresetCity('Jakarta, Indonesia', -6.2088, 106.8456),
  PresetCity('Kuala Lumpur, Malaysia', 3.1390, 101.6869),
  PresetCity('Singapore', 1.3521, 103.8198),
  PresetCity('Dubai, UAE', 25.2048, 55.2708),
  PresetCity('Doha, Qatar', 25.2854, 51.5310),
  PresetCity('Kuwait City, Kuwait', 29.3759, 47.9774),
  PresetCity('Amman, Jordan', 31.9539, 35.9106),
  PresetCity('Damascus, Syria', 33.5138, 36.2765),
  PresetCity('Baghdad, Iraq', 33.3152, 44.3661),
  PresetCity('Casablanca, Morocco', 33.5731, -7.5898),
  PresetCity('Algiers, Algeria', 36.7538, 3.0588),
  PresetCity('Tunis, Tunisia', 36.8065, 10.1815),
  PresetCity('London, UK', 51.5074, -0.1278),
  PresetCity('Paris, France', 48.8566, 2.3522),
  PresetCity('Berlin, Germany', 52.5200, 13.4050),
  PresetCity('New York City, USA', 40.7128, -74.0060),
  PresetCity('Chicago, USA', 41.8781, -87.6298),
  PresetCity('Toronto, Canada', 43.6532, -79.3832),
  PresetCity('Sydney, Australia', -33.8688, 151.2093),
];

/// Shows a picker letting the user choose a preset city. Saves the choice
/// as the manual location override and returns true if the user picked one.
Future<bool> showManualLocationPicker(BuildContext context) async {
  final picked = await showModalBottomSheet<PresetCity>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _LocationPickerSheet(),
  );
  if (picked == null) return false;

  final store = SettingsStore();
  final current = await store.load();
  await store.save(current.copyWith(
    manualLatitude: picked.latitude,
    manualLongitude: picked.longitude,
    manualCityLabel: picked.label,
  ));
  return true;
}

class _LocationPickerSheet extends StatefulWidget {
  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _presets
        : _presets
            .where(
                (c) => c.label.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Choose a city',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(c.label),
                    subtitle: Text(
                      '${c.latitude.toStringAsFixed(2)}°, ${c.longitude.toStringAsFixed(2)}°',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
