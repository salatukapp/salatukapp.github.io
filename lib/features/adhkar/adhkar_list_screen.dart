import 'package:flutter/material.dart';

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
    setState(() {
      _counters[id] = (_counters[id]! + 1).clamp(0, max);
    });
  }

  void _reset(String id) {
    setState(() => _counters[id] = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.titleEn),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset all counters',
            onPressed: () => setState(() {
              for (final id in _counters.keys) {
                _counters[id] = 0;
              }
            }),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.category.entries.length,
        itemBuilder: (context, i) {
          final entry = widget.category.entries[i];
          final progress = _counters[entry.id]!;
          return _DhikrCard(
            index: i + 1,
            total: widget.category.entries.length,
            entry: entry,
            progress: progress,
            onTap: () => _bump(entry.id, entry.count),
            onReset: () => _reset(entry.id),
          );
        },
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = progress >= entry.count;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onReset,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('$index / $total',
                    style: TextStyle(color: cs.outline, fontSize: 12)),
                const Spacer(),
                if (entry.grade.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.grade,
                      style: TextStyle(
                          color: cs.onSecondaryContainer, fontSize: 11),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              if (entry.titleEn.isNotEmpty)
                Text(entry.titleEn,
                    style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(entry.arabic, style: AppTheme.arabicBody),
              ),
              if (entry.transliteration.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(entry.transliteration,
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: cs.outline)),
              ],
              if (entry.translation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(entry.translation),
              ],
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress / entry.count,
                      backgroundColor: cs.surfaceContainerHigh,
                      color: completed ? Colors.green : cs.primary,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$progress / ${entry.count}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: completed ? Colors.green : null,
                      ),
                ),
              ]),
              if (entry.source.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Source: ${entry.source}',
                  style: TextStyle(fontSize: 11, color: cs.outline),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
