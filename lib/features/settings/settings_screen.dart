import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/prayer_times/sunni_method.dart';
import '../../core/storage/settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _store = SettingsStore();
  Settings _settings = const Settings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _store.load();
    setState(() {
      _settings = s;
      _loading = false;
    });
  }

  Future<void> _update(Settings next) async {
    setState(() => _settings = next);
    await _store.save(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Prayer calculation'),
          SwitchListTile(
            title: const Text('Auto-detect by region'),
            subtitle: const Text(
                'Suggest the right method based on your GPS location'),
            value: _settings.autoDetectMethod,
            onChanged: (v) => _update(_settings.copyWith(autoDetectMethod: v)),
          ),
          ListTile(
            title: const Text('Calculation method'),
            subtitle: Text(
              '${_settings.method.displayName}\n${_settings.method.summary}',
              style: const TextStyle(fontSize: 12),
            ),
            isThreeLine: true,
            onTap: () => _pickMethod(),
          ),
          ListTile(
            title: const Text('Asr juristic rule'),
            subtitle: Text(_settings.madhab == adhan.Madhab.hanafi
                ? 'Hanafi (shadow = 2× object length)'
                : 'Standard (Shafi\'i / Maliki / Hanbali — shadow = 1× object length)'),
            onTap: _pickMadhab,
          ),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Athan notifications'),
            subtitle: const Text('Local alarms at each prayer time'),
            value: _settings.notificationsEnabled,
            onChanged: (v) =>
                _update(_settings.copyWith(notificationsEnabled: v)),
          ),
          ListTile(
            title: const Text('Pre-prayer reminder'),
            subtitle: Text(_settings.preNotificationMinutes == 0
                ? 'Off'
                : '${_settings.preNotificationMinutes} min before'),
            onTap: _pickPreReminder,
          ),
          const _SectionHeader('Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(_settings.theme)),
            onTap: _pickTheme,
          ),
          const _SectionHeader('About'),
          ListTile(
            title: const Text('Privacy policy'),
            subtitle: const Text('Zero data collection. Everything stays on your device.'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(Uri.parse(
                'https://github.com/omarkaaki/salatuk/blob/main/PRIVACY_POLICY.md')),
          ),
          ListTile(
            title: const Text('Source code'),
            subtitle: const Text('MIT licensed, open source on GitHub'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () =>
                launchUrl(Uri.parse('https://github.com/omarkaaki/salatuk')),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Salatuk v0.1.0  •  Sunni prayer times, Qibla, and authenticated adhkar.\nFree forever. No tracking. No ads.',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemePreference t) {
    switch (t) {
      case ThemePreference.light:
        return 'Light';
      case ThemePreference.dark:
        return 'Dark';
      case ThemePreference.system:
        return 'System default';
    }
  }

  Future<void> _pickMethod() async {
    final picked = await showModalBottomSheet<SunniMethod>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: 600,
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Calculation method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              for (final m in SunniMethod.values)
                ListTile(
                  title: Text(m.displayName),
                  subtitle: Text(m.summary, style: const TextStyle(fontSize: 12)),
                  trailing: m == _settings.method
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Navigator.pop(context, m),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      await _update(_settings.copyWith(method: picked, autoDetectMethod: false));
    }
  }

  Future<void> _pickMadhab() async {
    final picked = await showModalBottomSheet<adhan.Madhab>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Asr juristic rule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              title: const Text('Standard'),
              subtitle: const Text(
                  'Shafi\'i / Maliki / Hanbali — shadow factor 1'),
              trailing: _settings.madhab == adhan.Madhab.shafi
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.pop(context, adhan.Madhab.shafi),
            ),
            ListTile(
              title: const Text('Hanafi'),
              subtitle: const Text('Shadow factor 2 (later Asr)'),
              trailing: _settings.madhab == adhan.Madhab.hanafi
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.pop(context, adhan.Madhab.hanafi),
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await _update(_settings.copyWith(madhab: picked));
    }
  }

  Future<void> _pickPreReminder() async {
    final options = [0, 5, 10, 15, 20, 30];
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Pre-prayer reminder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            for (final m in options)
              ListTile(
                title: Text(m == 0 ? 'Off' : '$m minutes before'),
                trailing: m == _settings.preNotificationMinutes
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await _update(_settings.copyWith(preNotificationMinutes: picked));
    }
  }

  Future<void> _pickTheme() async {
    final picked = await showModalBottomSheet<ThemePreference>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in ThemePreference.values)
              ListTile(
                title: Text(_themeLabel(t)),
                trailing: t == _settings.theme
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, t),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await _update(_settings.copyWith(theme: picked));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
