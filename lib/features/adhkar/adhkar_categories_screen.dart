import 'package:flutter/material.dart';

import '../../data/adhkar/adhkar_repository.dart';
import '../../ui/theme/app_theme.dart';
import 'adhkar_list_screen.dart';

class AdhkarCategoriesScreen extends StatefulWidget {
  const AdhkarCategoriesScreen({super.key});

  @override
  State<AdhkarCategoriesScreen> createState() => _AdhkarCategoriesScreenState();
}

class _AdhkarCategoriesScreenState extends State<AdhkarCategoriesScreen> with SingleTickerProviderStateMixin {
  final _repo = AdhkarRepository();
  Adhkar? _adhkar;
  String? _error;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final a = await _repo.load();
      if (mounted) {
        setState(() => _adhkar = a);
        _ctrl.forward();
      }
    } catch (e) {
      setState(() => _error = 'Could not load adhkar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _build(),
      ),
    );
  }

  Widget _build() {
    final cs = Theme.of(context).colorScheme;
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_adhkar == null) return const Center(child: CircularProgressIndicator());

    const order = ['morning', 'evening', 'afterPrayer', 'beforeSleep'];
    final gradients = <String, List<Color>>{
      'morning': [const Color(0xFFE89B5C), const Color(0xFFC9A961)],
      'evening': [const Color(0xFF6B5C9C), const Color(0xFF3D4470)],
      'afterPrayer': [AppTheme.emerald, AppTheme.emeraldDeep],
      'beforeSleep': [const Color(0xFF1F2D5C), const Color(0xFF0E1538)],
    };
    final icons = {
      'morning': Icons.wb_twilight_rounded,
      'evening': Icons.nightlight_round,
      'afterPrayer': Icons.mosque_rounded,
      'beforeSleep': Icons.bedtime_rounded,
    };
    final subtitles = {
      'morning': 'After Fajr, until sunrise',
      'evening': 'After Asr, until sunset',
      'afterPrayer': 'Recited after each prayer',
      'beforeSleep': 'Before bed each night',
    };

    final cats = [
      for (final id in order)
        if (_adhkar!.categories.containsKey(id)) _adhkar!.categories[id]!
    ];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adhkar',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أذكار',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authenticated remembrances from Hisn al-Muslim and primary hadith.',
                  style: TextStyle(color: cs.outline, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: SliverList.builder(
            itemCount: cats.length,
            itemBuilder: (context, i) {
              final c = cats[i];
              final animation = CurvedAnimation(
                parent: _ctrl,
                curve: Interval(i * 0.12, 1.0, curve: Curves.easeOutCubic),
              );
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Opacity(
                    opacity: animation.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - animation.value) * 30),
                      child: child,
                    ),
                  );
                },
                child: _CategoryCard(
                  title: c.titleEn,
                  arabicTitle: c.titleAr,
                  subtitle: subtitles[c.id] ?? c.subtitle,
                  count: c.entries.length,
                  icon: icons[c.id] ?? Icons.book,
                  gradient: gradients[c.id]!,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AdhkarListScreen(category: c)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String arabicTitle;
  final String subtitle;
  final int count;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.arabicTitle,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              arabicTitle,
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count adhkar',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
