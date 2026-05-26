import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Shown to desktop browser visitors. Salatuk is designed for phones —
/// the compass needs a magnetometer, prayer notifications need a phone
/// that's always with you, and the layout is portrait-first.
class DesktopRedirect extends StatefulWidget {
  final VoidCallback onContinueAnyway;
  const DesktopRedirect({super.key, required this.onContinueAnyway});

  @override
  State<DesktopRedirect> createState() => _DesktopRedirectState();
}

class _DesktopRedirectState extends State<DesktopRedirect> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(const ClipboardData(text: 'https://salatukapp.github.io/'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied — paste on your phone to open'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openApk() async {
    // Link to the latest release dynamically so it auto-updates with new versions.
    final uri = Uri.parse(
        'https://github.com/salatukapp/salatukapp.github.io/releases/latest');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openRepo() async {
    final uri = Uri.parse('https://github.com/salatukapp/salatukapp.github.io');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient(cs, isDark: isDark),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) => Opacity(
                    opacity: _ctrl.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - _ctrl.value) * 30),
                      child: _content(cs),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo mark
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Center(
            child: Text(
              'ﷺ',
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 38,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Salatuk',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'صَلَاتُكَ',
          style: TextStyle(
            fontFamily: 'Amiri',
            color: AppTheme.goldSoft,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Designed for your phone',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The Qibla compass needs a magnetometer, prayer notifications need a device that\'s with you all day, and the layout is portrait-first. Open this on your phone for the full experience.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),

        // Primary action: download APK
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openApk,
            icon: const Icon(Icons.android),
            label: const Text('Get the Android APK'),
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
            onPressed: _copyLink,
            icon: const Icon(Icons.link),
            label: const Text('Copy link to open on phone'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Continue anyway, as small text
        TextButton(
          onPressed: widget.onContinueAnyway,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.6),
          ),
          child: const Text(
            'Continue on desktop anyway →',
            style: TextStyle(fontSize: 13, decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 40),

        // Footer
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _FooterLink(label: 'Source', onTap: _openRepo),
            _Dot(),
            _FooterLink(label: 'MIT License', onTap: _openRepo),
            _Dot(),
            _FooterLink(
              label: 'No tracking',
              onTap: () => launchUrl(Uri.parse(
                  'https://github.com/salatukapp/salatukapp.github.io/blob/main/PRIVACY_POLICY.md')),
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('•',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12));
  }
}

/// Shows desktop redirect when on a wide browser, else passes through.
class ResponsiveGate extends StatefulWidget {
  final Widget child;
  const ResponsiveGate({super.key, required this.child});

  @override
  State<ResponsiveGate> createState() => _ResponsiveGateState();
}

class _ResponsiveGateState extends State<ResponsiveGate> {
  bool _bypassed = false;

  @override
  Widget build(BuildContext context) {
    final isWebBrowser = kIsWeb;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;

    if (isWebBrowser && isWide && !_bypassed) {
      return DesktopRedirect(onContinueAnyway: () => setState(() => _bypassed = true));
    }
    return widget.child;
  }
}
