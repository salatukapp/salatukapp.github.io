import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/adhkar/adhkar_repository.dart';
import '../../ui/theme/app_theme.dart';

class AdhkarListScreen extends StatefulWidget {
  final AdhkarCategory category;
  const AdhkarListScreen({super.key, required this.category});

  @override
  State<AdhkarListScreen> createState() => _AdhkarListScreenState();
}

class _AdhkarListScreenState extends State<AdhkarListScreen> {
  late final Map<String, int> _counters;

  @override
  void initState() {
    super.initState();
    _counters = {for (final e in widget.category.entries) e.id: 0};
  }

  void _bump(String id, int max) {
    HapticFeedback.lightImpact();
    setState(() {
      _counters[id] = (_counters[id]! + 1).clamp(0, max);
    });
  }

  void _reset(String id) {
    setState(() => _counters[id] = 0);
  }

  void _resetAll() {
    setState(() {
      for (final id in _counters.keys) {
        _counters[id] = 0;
      }
    });
  }

  int get _completed => _counters.entries
      .where((e) => e.value >= widget.category.entries.firstWhere((x) => x.id == e.key).count)
      .length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = widget.category.entries.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom app bar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.titleEn,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                        ),
                        Text(
                          '$_completed of $total complete',
                          style: TextStyle(color: cs.outline, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Reset all',
                    onPressed: _resetAll,
                  ),
                ],
              ),
            ),
            // Top progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _completed / total,
                  minHeight: 4,
                  backgroundColor: cs.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                itemCount: widget.category.entries.length,
                itemBuilder: (context, i) {
                  final entry = widget.category.entries[i];
                  final progress = _counters[entry.id]!;
                  return _DhikrCard(
                    index: i + 1,
                    total: total,
                    entry: entry,
                    progress: progress,
                    onTap: () => _bump(entry.id, entry.count),
                    onReset: () => _reset(entry.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DhikrCard extends StatefulWidget {
  final int index;
  final int total;
  final DhikrEntry entry;
  final int progress;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const _DhikrCard({
    required this.index,
    required this.total,
    required this.entry,
    required this.progress,
    required this.onTap,
    required this.onReset,
  });

  @override
  State<_DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends State<_DhikrCard> with SingleTickerProviderStateMixin {
  late final AnimationController _bumpCtrl;

  @override
  void initState() {
    super.initState();
    _bumpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void didUpdateWidget(_DhikrCard old) {
    super.didUpdateWidget(old);
    if (widget.progress > old.progress) {
      _bumpCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bumpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = widget.progress >= widget.entry.count;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          color: completed
              ? AppTheme.gold.withValues(alpha: isDark ? 0.10 : 0.08)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: completed
              ? Border.all(color: AppTheme.gold.withValues(alpha: 0.4), width: 1.2)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onReset,
            borderRadius: BorderRadius.circular(22),
            splashColor: AppTheme.gold.withValues(alpha: 0.15),
            highlightColor: AppTheme.gold.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.index}',
                          style: TextStyle(color: cs.outline, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.entry.titleEn,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                        ),
                      ),
                      if (widget.entry.grade.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.entry.grade,
                            style: TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      widget.entry.arabic,
                      style: AppTheme.arabicBody,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  if (widget.entry.transliteration.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.entry.transliteration,
                      style: TextStyle(fontStyle: FontStyle.italic, color: cs.outline, fontSize: 13, height: 1.5),
                    ),
                  ],
                  if (widget.entry.translation.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.entry.translation,
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.85), height: 1.5, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Counter row
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: widget.progress / widget.entry.count,
                            ),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => LinearProgressIndicator(
                              value: value,
                              backgroundColor: cs.surfaceContainerHigh,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  completed ? AppTheme.gold : cs.primary),
                              minHeight: 6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedBuilder(
                        animation: _bumpCtrl,
                        builder: (context, child) {
                          final scale = 1.0 + (_bumpCtrl.value < 0.5 ? _bumpCtrl.value * 0.4 : (1 - _bumpCtrl.value) * 0.4);
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: completed ? AppTheme.gold : cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.progress} / ${widget.entry.count}',
                            style: TextStyle(
                              color: completed ? AppTheme.charcoalDeep : cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.entry.source.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.book_outlined, size: 12, color: cs.outline),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.entry.source,
                            style: TextStyle(fontSize: 11, color: cs.outline, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
