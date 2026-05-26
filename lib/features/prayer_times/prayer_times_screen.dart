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
import '../../ui/theme/app_theme.dart';
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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
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
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const _LoadingState();
    if (_error != null) {
      return _ErrorState(
        message: _error!,
        onRetry: _bootstrap,
        onPickCity: () async {
          final picked = await showManualLocationPicker(context);
          if (picked && mounted) _bootstrap();
        },
      );
    }
    final times = _times!;
    final now = DateTime.now();
    final nextLocal = _nextPrayer(times, _tomorrowFajr, now);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _bootstrap,
      color: cs.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              place: _placeLabel,
              gregorian: DateFormat('EEEE, d MMMM y').format(now),
              hijri: _hijriString(now),
              method: _settings.method,
              nextLabel: nextLocal.label,
              nextTime: nextLocal.when,
              countdown: nextLocal.when.difference(now),
              gradient: AppTheme.heroGradient(cs, isDark: isDark),
              onPickCity: () async {
                final picked = await showManualLocationPicker(context);
                if (picked && mounted) _bootstrap();
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            sliver: SliverList.list(
              children: [
                _PrayerCard(name: 'Fajr', icon: Icons.dark_mode_outlined, time: times.fajr.toLocal(), isCurrent: _isCurrent(adhan.Prayer.fajr, times, now)),
                _PrayerCard(name: 'Sunrise', icon: Icons.wb_twilight_outlined, time: times.sunrise.toLocal(), subtle: true),
                _PrayerCard(name: 'Dhuhr', icon: Icons.wb_sunny_outlined, time: times.dhuhr.toLocal(), isCurrent: _isCurrent(adhan.Prayer.dhuhr, times, now)),
                _PrayerCard(name: 'Asr', icon: Icons.brightness_5_outlined, time: times.asr.toLocal(), isCurrent: _isCurrent(adhan.Prayer.asr, times, now)),
                _PrayerCard(name: 'Maghrib', icon: Icons.nights_stay_outlined, time: times.maghrib.toLocal(), isCurrent: _isCurrent(adhan.Prayer.maghrib, times, now)),
                _PrayerCard(name: 'Isha', icon: Icons.bedtime_outlined, time: times.isha.toLocal(), isCurrent: _isCurrent(adhan.Prayer.isha, times, now)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrent(adhan.Prayer p, adhan.PrayerTimes t, DateTime now) {
    return t.currentPrayer(date: now) == p;
  }

  ({String label, DateTime when}) _nextPrayer(adhan.PrayerTimes t, DateTime? tomorrowFajr, DateTime now) {
    if (now.isBefore(t.fajr.toLocal())) return (label: 'Fajr', when: t.fajr.toLocal());
    if (now.isBefore(t.dhuhr.toLocal())) return (label: 'Dhuhr', when: t.dhuhr.toLocal());
    if (now.isBefore(t.asr.toLocal())) return (label: 'Asr', when: t.asr.toLocal());
    if (now.isBefore(t.maghrib.toLocal())) return (label: 'Maghrib', when: t.maghrib.toLocal());
    if (now.isBefore(t.isha.toLocal())) return (label: 'Isha', when: t.isha.toLocal());
    return (label: 'Fajr (tomorrow)', when: (tomorrowFajr ?? t.fajrAfter).toLocal());
  }

  String _hijriString(DateTime d) {
    final h = HijriCalendar.fromDate(d);
    return '${h.hDay} ${h.longMonthName} ${h.hYear} AH';
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Computing prayer times…',
            style: TextStyle(color: cs.outline, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onPickCity;
  const _ErrorState({required this.message, required this.onRetry, required this.onPickCity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off_rounded, size: 56, color: cs.outline),
            ),
            const SizedBox(height: 24),
            Text(
              'No location yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: cs.outline, height: 1.5)),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onPickCity,
              icon: const Icon(Icons.place_outlined),
              label: const Text('Pick a city'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try GPS again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String place;
  final String gregorian;
  final String hijri;
  final SunniMethod method;
  final String nextLabel;
  final DateTime nextTime;
  final Duration countdown;
  final LinearGradient gradient;
  final VoidCallback onPickCity;

  const _HeroHeader({
    required this.place,
    required this.gregorian,
    required this.hijri,
    required this.method,
    required this.nextLabel,
    required this.nextTime,
    required this.countdown,
    required this.gradient,
    required this.onPickCity,
  });

  String _formatCountdown(Duration d) {
    if (d.isNegative) return '0s';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h h $m m';
    if (m > 0) return '$m m $s s';
    return '$s s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: location
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: GestureDetector(
                      onTap: onPickCity,
                      child: Text(
                        place,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onPickCity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit_location_alt_outlined, size: 13, color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(width: 4),
                          Text(
                            'Change',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Hijri date — Arabic-styled
              Text(
                hijri,
                style: TextStyle(
                  color: AppTheme.goldSoft,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                gregorian,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
              ),
              const SizedBox(height: 32),
              // Big next-prayer label
              Text(
                'NEXT PRAYER',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nextLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      DateFormat.jm().format(nextTime),
                      style: TextStyle(
                        color: AppTheme.goldSoft,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Countdown chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_top_rounded, size: 16, color: AppTheme.goldSoft),
                    const SizedBox(width: 8),
                    Text(
                      'in ${_formatCountdown(countdown)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${method.displayName} • ${method.code}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final DateTime time;
  final bool subtle;
  final bool isCurrent;
  const _PrayerCard({
    required this.name,
    required this.icon,
    required this.time,
    this.subtle = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        gradient: isCurrent
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.gold.withValues(alpha: isDark ? 0.20 : 0.18),
                  AppTheme.gold.withValues(alpha: isDark ? 0.08 : 0.06),
                ],
              )
            : null,
        color: isCurrent ? null : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: isCurrent
            ? Border.all(color: AppTheme.gold.withValues(alpha: 0.4), width: 1.2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppTheme.gold.withValues(alpha: 0.18)
                    : cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isCurrent
                    ? AppTheme.gold
                    : (subtle ? cs.outline : cs.onSurface.withValues(alpha: 0.75)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color: subtle ? cs.outline : cs.onSurface,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 2),
                    Text(
                      'NOW',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              DateFormat.jm().format(time),
              style: TextStyle(
                fontSize: 17,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: subtle ? cs.outline : cs.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
