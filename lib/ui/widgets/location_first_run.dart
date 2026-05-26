import 'package:flutter/material.dart';

import '../../core/location/location_service.dart';
import '../../core/storage/settings_store.dart';
import '../theme/app_theme.dart';
import 'manual_location_picker.dart';



/// Shown on first run (and whenever no location is stored) to let the user
/// explicitly choose between GPS and a city list.
///
/// Why this exists: on iOS Safari, `navigator.geolocation.getCurrentPosition`
/// can hang silently if it isn't triggered by a user gesture. Wrapping the
/// call behind a button tap satisfies iOS's gesture requirement and gives
/// users on any platform a graceful way to opt out of GPS.
class LocationFirstRun extends StatefulWidget {
  final VoidCallback onReady;
  const LocationFirstRun({super.key, required this.onReady});

  @override
  State<LocationFirstRun> createState() => _LocationFirstRunState();
}

class _LocationFirstRunState extends State<LocationFirstRun> {
  final _location = LocationService();
  bool _requesting = false;
  String? _error;

  Future<void> _useGps() async {
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      // This is now a user-gesture-triggered call (iOS Safari friendly).
      // 8s is long enough for cellular fixes but short enough that the user
      // can decide to switch to manual mode if it's taking forever.
      await _location.getCurrent(timeout: const Duration(seconds: 8));
      if (!mounted) return;
      widget.onReady();
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickCity() async {
    final picked = await showManualLocationPicker(context);
    if (picked && mounted) widget.onReady();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.heroGradient(cs, isDark: isDark)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.place_outlined, color: Colors.white, size: 44),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Where are you?',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Salatuk needs your location to calculate accurate prayer times and the Qibla bearing. Everything stays on your device — we never send your location anywhere.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, height: 1.6),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _requesting ? null : _useGps,
                    icon: _requesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.charcoalDeep),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: Text(_requesting ? 'Asking for permission…' : 'Use my GPS location'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.charcoalDeep,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _requesting ? null : _pickCity,
                    icon: const Icon(Icons.place_outlined),
                    label: const Text('Choose a city from the list'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'On iPhone, the browser will ask for permission once. You can change your location later in Settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a child screen, showing the first-run location chooser if no
/// location has been recorded yet (manual or otherwise).
class LocationGate extends StatefulWidget {
  final Widget child;
  const LocationGate({super.key, required this.child});

  @override
  State<LocationGate> createState() => _LocationGateState();
}

class _LocationGateState extends State<LocationGate> {
  final _store = SettingsStore();
  bool _ready = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final s = await _store.load();
    if (!mounted) return;
    setState(() {
      _ready = s.manualLatitude != null && s.manualLongitude != null;
      _loading = false;
    });
  }

  void _onReady() {
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_ready) {
      return LocationFirstRun(onReady: _onReady);
    }
    return widget.child;
  }
}
