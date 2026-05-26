import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/location/location_service.dart';
import '../../core/qibla/qibla_service.dart';
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
      _stream = _qibla.compassStream(latitude: _lat!, longitude: _lng!, date: DateTime.now());
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.heroGradient(cs, isDark: isDark)),
        child: SafeArea(
          child: _buildBody(),
        ),
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

    if (kIsWeb) {
      return _StaticBearingView(bearing: _qiblaBearing!, latitude: _lat!, longitude: _lng!);
    }
    return StreamBuilder<QiblaReading>(
      stream: _stream,
      builder: (context, snap) => _CompassView(
        bearing: _qiblaBearing!,
        reading: snap.data,
        latitude: _lat!,
        longitude: _lng!,
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

class _CompassViewState extends State<_CompassView> with SingleTickerProviderStateMixin {
  double _smoothedHeading = 0;

  @override
  void didUpdateWidget(_CompassView old) {
    super.didUpdateWidget(old);
    final r = widget.reading;
    if (r != null) {
      // Smooth heading with exponential moving average for jitter-free needle.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          // Top text
          Text('QIBLA',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3)),
          const SizedBox(height: 4),
          Text(
            '${widget.bearing.toStringAsFixed(1)}°',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700, height: 1.1),
          ),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tint.withValues(alpha: 0.25),
                        blurRadius: 60,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedRotation(
                        turns: rotation / (2 * math.pi),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        child: CustomPaint(size: Size.infinite, painter: _CompassDialPainter()),
                      ),
                      AnimatedRotation(
                        turns: qiblaRotation / (2 * math.pi),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        child: CustomPaint(size: Size.infinite, painter: _QiblaArrowPainter(tint)),
                      ),
                      // Center marker
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
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
  const _StaticBearingView({required this.bearing, required this.latitude, required this.longitude});

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
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppTheme.goldSoft),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Browsers can\'t access a compass reliably. The Android app gives you a live needle.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.5),
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

class _CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Outer ring with subtle gradient
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

    // Inner ring
    final innerRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, r * 0.7, innerRing);

    // Cardinal marks
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

    // Minor tick marks every 10°
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

    // Needle body (gold gradient)
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

    // Center dot
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
