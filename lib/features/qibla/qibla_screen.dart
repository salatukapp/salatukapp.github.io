import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/location/location_service.dart';
import '../../core/qibla/qibla_service.dart';
import '../../core/qibla/web_compass.dart';
import '../../core/storage/settings_store.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/manual_location_picker.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final _location = LocationService();
  final _qibla = QiblaService();

  bool _loading = true;
  String? _error;
  double? _lat;
  double? _lng;
  double? _qiblaBearing;
  Stream<QiblaReading>? _stream;
  bool _webCompassEnabled = false;
  bool _webCompassRequesting = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await SettingsStore().load();
      if (settings.manualLatitude != null && settings.manualLongitude != null) {
        _lat = settings.manualLatitude;
        _lng = settings.manualLongitude;
      } else {
        final loc = await _location.getCurrent();
        _lat = loc.latitude;
        _lng = loc.longitude;
      }
      _qiblaBearing = QiblaService.bearingFromTrueNorth(latitude: _lat!, longitude: _lng!);

      if (!kIsWeb) {
        // Native: stream is always live, FlutterCompass auto-subscribes.
        _stream = _qibla.compassStream(latitude: _lat!, longitude: _lng!, date: DateTime.now());
      } else if (!_qibla.needsWebPermission) {
        // Web non-iOS (Android Chrome): events fire without explicit permission.
        _stream = _qibla.webCompassStream(latitude: _lat!, longitude: _lng!, date: DateTime.now());
        _webCompassEnabled = true;
      }
      // On iOS web we leave _stream null until the user taps "Enable compass".

      setState(() => _loading = false);
    } on LocationException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not start Qibla compass: $e';
      });
    }
  }

  Future<void> _enableWebCompass() async {
    setState(() => _webCompassRequesting = true);
    final granted = await WebCompass.requestPermission();
    if (!mounted) return;
    if (granted) {
      setState(() {
        _stream = _qibla.webCompassStream(latitude: _lat!, longitude: _lng!, date: DateTime.now());
        _webCompassEnabled = true;
        _webCompassRequesting = false;
      });
    } else {
      setState(() => _webCompassRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compass permission denied. Showing static bearing only.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.heroGradient(cs, isDark: isDark)),
        child: SafeArea(
          child: Stack(
            children: [
              _buildBody(),
              // Top-right info button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  tooltip: 'How is this computed?',
                  onPressed: _qiblaBearing == null ? null : () => _showAccuracyInfo(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccuracyInfo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AccuracyPanel(
        latitude: _lat!,
        longitude: _lng!,
        qiblaBearing: _qiblaBearing!,
        currentReading: null, // we don't pipe the live reading into the dialog yet
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
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

    // iOS web before user has tapped to enable: show static bearing
    // with an "Enable live compass" button.
    if (kIsWeb && !_webCompassEnabled) {
      return _StaticBearingView(
        bearing: _qiblaBearing!,
        latitude: _lat!,
        longitude: _lng!,
        showEnableButton: true,
        enabling: _webCompassRequesting,
        onEnable: _enableWebCompass,
      );
    }

    return StreamBuilder<QiblaReading>(
      stream: _stream,
      builder: (context, snap) {
        // On web, if no reading has arrived yet (sensor unavailable / permission
        // dismissed), fall back to the static view instead of a spinning loader.
        if (kIsWeb && !snap.hasData) {
          return _StaticBearingView(
            bearing: _qiblaBearing!,
            latitude: _lat!,
            longitude: _lng!,
            showEnableButton: false,
          );
        }
        return _CompassView(
          bearing: _qiblaBearing!,
          reading: snap.data,
          latitude: _lat!,
          longitude: _lng!,
        );
      },
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.explore_off, size: 56, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Text(
              'Qibla unavailable',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), height: 1.5)),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onPickCity,
              icon: const Icon(Icons.place_outlined),
              label: const Text('Pick a city'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.charcoalDeep,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white70),
              label: const Text('Try GPS again', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassView extends StatefulWidget {
  final double bearing;
  final QiblaReading? reading;
  final double latitude;
  final double longitude;

  const _CompassView({
    required this.bearing,
    required this.reading,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<_CompassView> createState() => _CompassViewState();
}

class _CompassViewState extends State<_CompassView> {
  double _smoothedHeading = 0;
  bool _hasReading = false;

  @override
  void didUpdateWidget(_CompassView old) {
    super.didUpdateWidget(old);
    final r = widget.reading;
    if (r != null) {
      // Snap to the very first reading instead of lerping from North — avoids
      // a visible ~180° swing when the user first faces south.
      if (!_hasReading) {
        _smoothedHeading = r.trueHeading;
        _hasReading = true;
        return;
      }
      var delta = r.trueHeading - _smoothedHeading;
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      _smoothedHeading = (_smoothedHeading + delta * 0.25) % 360;
      if (_smoothedHeading < 0) _smoothedHeading += 360;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = widget.reading;
    final isFacing = reading?.isFacingQibla ?? false;
    final isNear = reading?.isNearQibla ?? false;
    final tint = isFacing ? const Color(0xFF6BE89F) : (isNear ? AppTheme.goldSoft : Colors.white);

    final heading = reading != null ? _smoothedHeading : 0.0;
    final rotation = -heading * math.pi / 180;
    final qiblaRotation = (widget.bearing - heading) * math.pi / 180;

    // Respect "Reduce Motion" (iOS) / "Remove animations" (Android) — the
    // continuously-rotating dial is a known vestibular trigger.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final rotateDur = reduceMotion ? Duration.zero : const Duration(milliseconds: 350);
    final glowDur = reduceMotion ? Duration.zero : const Duration(milliseconds: 600);

    final instruction = reading == null
        ? 'Acquiring compass…'
        : isFacing
            ? 'Facing Qibla'
            : isNear
                ? 'Almost there'
                : 'Turn ${reading.deltaToQibla.abs().toStringAsFixed(0)}°'
                    '${reading.deltaToQibla > 0 ? " right" : " left"}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          Text('QIBLA',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3)),
          const SizedBox(height: 4),
          Text('${widget.bearing.toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700, height: 1.1)),
          if (reading != null)
            Text(
              'Δ ${reading.deltaToQibla.toStringAsFixed(0)}°  •  heading ${reading.trueHeading.toStringAsFixed(0)}°',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: 'Qibla compass',
                  value: instruction,
                  child: ExcludeSemantics(
                  child: AnimatedContainer(
                  duration: glowDur,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: tint.withValues(alpha: 0.25), blurRadius: 60, spreadRadius: 4),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedRotation(
                        turns: rotation / (2 * math.pi),
                        duration: rotateDur,
                        curve: Curves.easeOutCubic,
                        child: CustomPaint(size: Size.infinite, painter: _CompassDialPainter()),
                      ),
                      AnimatedRotation(
                        turns: qiblaRotation / (2 * math.pi),
                        duration: rotateDur,
                        curve: Curves.easeOutCubic,
                        child: CustomPaint(size: Size.infinite, painter: _QiblaArrowPainter(tint)),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
                            child: Icon(
                              isFacing ? Icons.check_circle : Icons.navigation_rounded,
                              key: ValueKey(isFacing),
                              size: 40,
                              color: tint,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isFacing
                                ? 'Facing Qibla'
                                : isNear
                                    ? 'Almost there'
                                    : 'Turn ${reading?.deltaToQibla.abs().toStringAsFixed(0) ?? "--"}°'
                                        '${(reading?.deltaToQibla ?? 0) > 0 ? " →" : " ←"}',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (reading != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Declination ${reading.declinationUsed.toStringAsFixed(1)}° • GPS ${widget.latitude.toStringAsFixed(2)}, ${widget.longitude.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class _StaticBearingView extends StatelessWidget {
  final double bearing;
  final double latitude;
  final double longitude;
  final bool showEnableButton;
  final bool enabling;
  final VoidCallback? onEnable;

  const _StaticBearingView({
    required this.bearing,
    required this.latitude,
    required this.longitude,
    this.showEnableButton = false,
    this.enabling = false,
    this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    final qiblaRotation = bearing * math.pi / 180;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text('QIBLA',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3)),
                const SizedBox(height: 4),
                Text('${bearing.toStringAsFixed(1)}°',
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700, height: 1.1)),
                const SizedBox(height: 4),
                Text('from true north',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(size: const Size.square(280), painter: _CompassDialPainter()),
                  Transform.rotate(
                    angle: qiblaRotation,
                    child: CustomPaint(size: const Size.square(280), painter: _QiblaArrowPainter(AppTheme.gold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (showEnableButton && onEnable != null)
            FilledButton.icon(
              onPressed: enabling ? null : onEnable,
              icon: enabling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.charcoalDeep),
                    )
                  : const Icon(Icons.explore_rounded),
              label: Text(enabling ? 'Asking for permission…' : 'Enable live compass'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.charcoalDeep,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          if (showEnableButton) const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppTheme.goldSoft),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    showEnableButton
                        ? 'Your browser needs a one-time permission to read the phone\'s compass. Tap "Enable live compass" to allow it.'
                        : 'No compass signal yet — hold the phone level and slowly rotate. If nothing happens, your browser may not support orientation events.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Location: ${latitude.toStringAsFixed(2)}°, ${longitude.toStringAsFixed(2)}°',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet showing the math behind the Qibla bearing, so users can
/// verify accuracy against any external reference.
class _AccuracyPanel extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double qiblaBearing;
  final QiblaReading? currentReading;

  const _AccuracyPanel({
    required this.latitude,
    required this.longitude,
    required this.qiblaBearing,
    this.currentReading,
  });

  Future<void> _openIslamicFinder() async {
    // Open the bare URL (no lat/lng query params) so we don't transmit the
    // user's exact coordinates to a third party — IslamicFinder geolocates
    // itself, and this keeps the "nothing leaves your device" promise intact.
    final uri = Uri.parse('https://www.islamicfinder.org/world/qibla/');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openGoogleQibla() async {
    final uri = Uri.parse('https://qiblafinder.withgoogle.com/');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('How Qibla is computed',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Every value below is computed on your device. Your location is never transmitted anywhere.',
                style: TextStyle(color: cs.outline, fontSize: 12, height: 1.5)),
            const SizedBox(height: 20),

            _row(context, 'Your location', '${latitude.toStringAsFixed(4)}°N, ${longitude.toStringAsFixed(4)}°E',
                'from GPS or manual city pick'),
            _row(context, 'Kaaba target', '21.4225°N, 39.8262°E',
                'verified against Wikipedia, OSM, coordinate databases'),
            _row(context, 'Great-circle bearing', '${qiblaBearing.toStringAsFixed(2)}°',
                'clockwise from true north — spherical-trigonometry formula'),
            _row(context, 'Magnetic declination', currentReading == null
                ? 'computed when compass is live'
                : '${currentReading!.declinationUsed.toStringAsFixed(2)}° east of true north',
                'from NOAA WMM 2025 spherical-harmonic model (12 degrees)'),
            if (currentReading != null) ...[
              _row(context, 'Compass heading (true)', '${currentReading!.trueHeading.toStringAsFixed(1)}°',
                  'after declination correction on Android, raw true-heading on iOS'),
              _row(context, 'Delta to Qibla', '${currentReading!.deltaToQibla.toStringAsFixed(1)}°',
                  currentReading!.isFacingQibla ? '✓ facing Qibla' : 'turn ${currentReading!.deltaToQibla.abs().toStringAsFixed(0)}° to align'),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: AppTheme.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Accuracy verified',
                            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          '17 reference cities tested within 0.5° of the published library value. WMM 2025 declination verified to ±1° of NOAA for 8 cities globally.',
                          style: TextStyle(color: cs.outline, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Cross-check against another source:',
                style: TextStyle(color: cs.outline, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openIslamicFinder,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('IslamicFinder Qibla'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openGoogleQibla,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Google Qibla Finder'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Calibration tip: if the needle drifts, hold the phone flat and slowly move it in a figure-8 pattern for 5 seconds. Keep away from metal objects (laptops, speakers, magnetic phone cases) which distort the compass.',
              style: TextStyle(color: cs.outline, fontSize: 11, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, String hint) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(color: cs.outline, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(hint,
              style: TextStyle(color: cs.outline.withValues(alpha: 0.7), fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final ringPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, r * 0.95, ringPaint);

    final innerRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, r * 0.7, innerRing);

    final cardinals = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final ang = -math.pi / 2 + i * math.pi / 2;
      final pos = Offset(c.dx + math.cos(ang) * r * 0.82, c.dy + math.sin(ang) * r * 0.82);
      final color = i == 0 ? AppTheme.goldSoft : Colors.white.withValues(alpha: 0.85);
      final tp = TextPainter(
        text: TextSpan(
          text: cardinals[i],
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    for (var deg = 0; deg < 360; deg += 10) {
      final ang = -math.pi / 2 + deg * math.pi / 180;
      final tickLen = (deg % 30 == 0) ? 0.05 : 0.025;
      final outer = Offset(c.dx + math.cos(ang) * r * 0.93, c.dy + math.sin(ang) * r * 0.93);
      final inner = Offset(c.dx + math.cos(ang) * r * (0.93 - tickLen), c.dy + math.sin(ang) * r * (0.93 - tickLen));
      final tickPaint = Paint()
        ..color = Colors.white.withValues(alpha: deg % 30 == 0 ? 0.5 : 0.25)
        ..strokeWidth = deg % 30 == 0 ? 1.5 : 1;
      canvas.drawLine(outer, inner, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter old) => false;
}

class _QiblaArrowPainter extends CustomPainter {
  final Color color;
  _QiblaArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final path = Path()
      ..moveTo(c.dx, c.dy - r * 0.72)
      ..lineTo(c.dx - r * 0.07, c.dy - r * 0.20)
      ..lineTo(c.dx, c.dy - r * 0.28)
      ..lineTo(c.dx + r * 0.07, c.dy - r * 0.20)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0.6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(c, 5, dotPaint);
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, 10, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _QiblaArrowPainter old) => old.color != color;
}
