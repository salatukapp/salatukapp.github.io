import 'package:flutter/material.dart';

import 'core/notifications/prayer_notifier.dart';
import 'core/storage/settings_store.dart';
import 'features/home/home_screen.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the local-notification stack early so it's ready when we
  // schedule. On web this is effectively a no-op.
  try {
    await PrayerNotifier().init();
  } catch (_) {
    // Notifications are nice-to-have, not critical for app startup.
  }
  runApp(const SalatukApp());
}

class SalatukApp extends StatefulWidget {
  const SalatukApp({super.key});

  @override
  State<SalatukApp> createState() => _SalatukAppState();
}

class _SalatukAppState extends State<SalatukApp> {
  final _store = SettingsStore();
  Settings _settings = const Settings();

  @override
  void initState() {
    super.initState();
    _store.load().then((s) {
      if (mounted) setState(() => _settings = s);
    });
  }

  ThemeMode get _themeMode {
    switch (_settings.theme) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salatuk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: const HomeScreen(),
    );
  }
}
