import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/location/location_service.dart';
import '../../core/qibla/qibla_service.dart';
import '../../core/storage/settings_store.dart';
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
      // Honor a manual-location override first; only fall back to GPS otherwise.
      final settings = await SettingsStore().load();
      if (settings.manualLatitude != null && settings.manualLongitude != null) {
        _lat = settings.manualLatitude;
        _lng = settings.manualLongitude;
      } else {
        final loc = await _location.getCurrent();
        _lat = loc.latitude;
        _lng = loc.longitude;
      }
      _qiblaBearing = QiblaService.bearingFromTrueNorth(
        latitude: _lat!,
        longitude: _lng!,
      );
      _stream = _qibla.compassStream(
        latitude: _lat!,
        longitude: _lng!,
        date: DateTime.now(),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About the Qibla compass',
            onPressed: _showInfo,
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('About this compass'),
        content: const SingleChildScrollView(
          child: Text(
            'The needle points toward the Kaaba (21.4225°N, 39.8262°E) using a great-circle calculation from your GPS location. '
            'The compass uses your device magnetometer with World Magnetic Model declination correction to convert from magnetic to true north.\n\n'
            'For best accuracy: hold the device flat, away from metal objects and electronics, and figure-eight to calibrate if the heading seems off. '
            'On iOS Simulator the compass does not work — use a real device.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off,
                size: 64, color: Theme.of(context).colorScheme.outline),
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
            const SizedBox(height: 16),
            Text(
              'Desktop browsers don\'t have a magnetometer — the Qibla compass is fully accurate only on phones. On desktop you\'ll still see the target bearing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }
    return StreamBuilder<QiblaReading>(
      stream: _stream,
      builder: (context, snap) {
        final reading = snap.data;
        return _CompassView(
          bearing: _qiblaBearing!,
          reading: reading,
          latitude: _lat!,
          longitude: _lng!,
        );
      },
    );
  }
}

class _CompassView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFacing = reading?.isFacingQibla ?? false;
    final isNear = reading?.isNearQibla ?? false;
    final tint = isFacing
        ? Colors.green
        : isNear
            ? Colors.amber
            : cs.primary;

    // Rotation: rotate compass face by negative heading so the heading marker points up.
    final heading = reading?.trueHeading ?? 0;
    final rotation = -heading * math.pi / 180;
    final qiblaRotation = (bearing - heading) * math.pi / 180;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Qibla bearing: ${bearing.toStringAsFixed(1)}° from true north',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (reading != null) ...[
            const SizedBox(height: 4),
            Text(
              'Heading ${reading!.trueHeading.toStringAsFixed(0)}°  •  '
              'Δ ${reading!.deltaToQibla.toStringAsFixed(0)}°',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          ],
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Compass dial
                    Transform.rotate(
                      angle: rotation,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _CompassDialPainter(cs),
                      ),
                    ),
                    // Qibla needle relative to current heading
                    Transform.rotate(
                      angle: qiblaRotation,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _QiblaArrowPainter(tint),
                      ),
                    ),
                    // Status text in center
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFacing ? Icons.check_circle : Icons.navigation,
                          size: 36,
                          color: tint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isFacing
                              ? 'Facing Qibla'
                              : isNear
                                  ? 'Almost there'
                                  : 'Turn ${reading?.deltaToQibla.abs().toStringAsFixed(0) ?? "--"}°'
                                      '${(reading?.deltaToQibla ?? 0) > 0 ? " →" : " ←"}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (reading != null)
            Text(
              'Declination ${reading!.declinationUsed.toStringAsFixed(1)}°  •  '
              'GPS ${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.outline),
            ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  final ColorScheme cs;
  _CompassDialPainter(this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final ringPaint = Paint()
      ..color = cs.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(c, r * 0.95, ringPaint);

    // Cardinal marks
    final labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final ang = -math.pi / 2 + i * math.pi / 2;
      final pos = Offset(c.dx + math.cos(ang) * r * 0.82, c.dy + math.sin(ang) * r * 0.82);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
              color: i == 0 ? cs.primary : cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Tick marks every 30°
    final tickPaint = Paint()..color = cs.outlineVariant;
    for (var deg = 0; deg < 360; deg += 30) {
      final ang = -math.pi / 2 + deg * math.pi / 180;
      final outer = Offset(c.dx + math.cos(ang) * r * 0.92, c.dy + math.sin(ang) * r * 0.92);
      final inner = Offset(c.dx + math.cos(ang) * r * 0.86, c.dy + math.sin(ang) * r * 0.86);
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
      ..moveTo(c.dx, c.dy - r * 0.78)
      ..lineTo(c.dx - r * 0.08, c.dy - r * 0.30)
      ..lineTo(c.dx + r * 0.08, c.dy - r * 0.30)
      ..close();

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);

    final tail = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final tailPath = Path()
      ..moveTo(c.dx, c.dy + r * 0.65)
      ..lineTo(c.dx - r * 0.05, c.dy + r * 0.30)
      ..lineTo(c.dx + r * 0.05, c.dy + r * 0.30)
      ..close();
    canvas.drawPath(tailPath, tail);
  }

  @override
  bool shouldRepaint(covariant _QiblaArrowPainter old) => old.color != color;
}
