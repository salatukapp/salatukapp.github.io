import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/location/location_service.dart';
import '../../core/location/region_detector.dart';
import '../../core/prayer_times/prayer_times_service.dart';
import '../../core/prayer_times/sunni_method.dart';
import '../../core/storage/settings_store.dart';
import '../../ui/widgets/manual_location_picker.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final _location = LocationService();
  final _service = PrayerTimesService();
  final _store = SettingsStore();

  bool _loading = true;
  String? _error;
  Settings _settings = const Settings();
  double? _lat;
  double? _lng;
  String _placeLabel = '';
  adhan.PrayerTimes? _times;
  DateTime? _tomorrowFajr;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _settings = await _store.load();

      if (_settings.manualLatitude != null && _settings.manualLongitude != null) {
        _lat = _settings.manualLatitude;
        _lng = _settings.manualLongitude;
        _placeLabel = _settings.manualCityLabel ?? 'Manual location';
      } else {
        final loc = await _location.getCurrent();
        _lat = loc.latitude;
        _lng = loc.longitude;
        _placeLabel =
            '${loc.latitude.toStringAsFixed(2)}°, ${loc.longitude.toStringAsFixed(2)}°';
      }

      SunniMethod method = _settings.method;
      if (_settings.autoDetectMethod) {
        method = RegionDetector.recommendedMethod(
          latitude: _lat!,
          longitude: _lng!,
        );
        if (method != _settings.method) {
          _settings = _settings.copyWith(method: method);
          await _store.save(_settings);
        }
      }

      final result = _service.computeForToday(
        latitude: _lat!,
        longitude: _lng!,
        method: method,
        madhab: _settings.madhab,
      );
      _times = result.today;
      _tomorrowFajr = result.tomorrowFajr;
      setState(() => _loading = false);
    } on LocationException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load prayer times: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Times'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _bootstrap,
          ),
        ],
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final picked = await showManualLocationPicker(context);
                if (picked && mounted) _bootstrap();
              },
              icon: const Icon(Icons.place_outlined),
              label: const Text('Pick a city'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _bootstrap,
              icon: const Icon(Icons.refresh),
              label: const Text('Try GPS again'),
            ),
          ],
        ),
      );
    }
    final times = _times!;
    final now = DateTime.now();
    final nextLocal = _nextPrayer(times, _tomorrowFajr, now);

    return RefreshIndicator(
      onRefresh: _bootstrap,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _Header(
            place: _placeLabel,
            gregorian: DateFormat('EEEE, d MMMM y').format(now),
            hijri: _hijriString(now),
            method: _settings.method,
          ),
          const SizedBox(height: 12),
          _NextPrayerCard(
            label: nextLocal.label,
            time: nextLocal.when,
            countdown: nextLocal.when.difference(now),
          ),
          const SizedBox(height: 4),
          _PrayerRow(name: 'Fajr', time: times.fajr.toLocal(), isCurrent: _isCurrent(adhan.Prayer.fajr, times, now)),
          _PrayerRow(name: 'Sunrise', time: times.sunrise.toLocal(), subtle: true),
          _PrayerRow(name: 'Dhuhr', time: times.dhuhr.toLocal(), isCurrent: _isCurrent(adhan.Prayer.dhuhr, times, now)),
          _PrayerRow(name: 'Asr', time: times.asr.toLocal(), isCurrent: _isCurrent(adhan.Prayer.asr, times, now)),
          _PrayerRow(name: 'Maghrib', time: times.maghrib.toLocal(), isCurrent: _isCurrent(adhan.Prayer.maghrib, times, now)),
          _PrayerRow(name: 'Isha', time: times.isha.toLocal(), isCurrent: _isCurrent(adhan.Prayer.isha, times, now)),
        ],
      ),
    );
  }

  bool _isCurrent(adhan.Prayer p, adhan.PrayerTimes t, DateTime now) {
    return t.currentPrayer(date: now) == p;
  }

  ({String label, DateTime when}) _nextPrayer(
      adhan.PrayerTimes t, DateTime? tomorrowFajr, DateTime now) {
    if (now.isBefore(t.fajr.toLocal())) {
      return (label: 'Fajr', when: t.fajr.toLocal());
    }
    if (now.isBefore(t.dhuhr.toLocal())) {
      return (label: 'Dhuhr', when: t.dhuhr.toLocal());
    }
    if (now.isBefore(t.asr.toLocal())) {
      return (label: 'Asr', when: t.asr.toLocal());
    }
    if (now.isBefore(t.maghrib.toLocal())) {
      return (label: 'Maghrib', when: t.maghrib.toLocal());
    }
    if (now.isBefore(t.isha.toLocal())) {
      return (label: 'Isha', when: t.isha.toLocal());
    }
    return (label: 'Fajr', when: (tomorrowFajr ?? t.fajrAfter).toLocal());
  }

  String _hijriString(DateTime d) {
    final h = HijriCalendar.fromDate(d);
    return '${h.hDay} ${h.longMonthName} ${h.hYear} AH';
  }
}

class _Header extends StatelessWidget {
  final String place;
  final String gregorian;
  final String hijri;
  final SunniMethod method;
  const _Header({
    required this.place,
    required this.gregorian,
    required this.hijri,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(hijri,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.primary)),
          const SizedBox(height: 2),
          Text(gregorian, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.place_outlined, size: 16, color: cs.outline),
            const SizedBox(width: 4),
            Text(place, style: Theme.of(context).textTheme.bodySmall),
          ]),
          const SizedBox(height: 4),
          Text('Method: ${method.displayName}',
              style:
                  Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.outline)),
        ],
      ),
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  final String label;
  final DateTime time;
  final Duration countdown;
  const _NextPrayerCard({
    required this.label,
    required this.time,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = countdown.inHours;
    final m = countdown.inMinutes.remainder(60);
    final s = countdown.inSeconds.remainder(60);
    final cd = h > 0 ? '${h}h ${m}m' : '${m}m ${s}s';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next prayer',
                  style: TextStyle(color: cs.onPrimaryContainer.withValues(alpha: 0.8))),
              const SizedBox(height: 4),
              Text(label,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
              Text(DateFormat.jm().format(time),
                  style: TextStyle(color: cs.onPrimaryContainer)),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('in', style: TextStyle(color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
          Text(cd,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
        ])
      ]),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final String name;
  final DateTime time;
  final bool subtle;
  final bool isCurrent;
  const _PrayerRow({
    required this.name,
    required this.time,
    this.subtle = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrent ? cs.secondaryContainer : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: subtle ? cs.outline : null,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
        ),
        Text(
          DateFormat.jm().format(time),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: subtle ? cs.outline : null,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ]),
    );
  }
}
