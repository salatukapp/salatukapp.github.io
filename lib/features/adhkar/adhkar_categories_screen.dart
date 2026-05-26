import 'package:flutter/material.dart';

import '../../data/adhkar/adhkar_repository.dart';
import 'adhkar_list_screen.dart';

class AdhkarCategoriesScreen extends StatefulWidget {
  const AdhkarCategoriesScreen({super.key});

  @override
  State<AdhkarCategoriesScreen> createState() => _AdhkarCategoriesScreenState();
}

class _AdhkarCategoriesScreenState extends State<AdhkarCategoriesScreen> {
  final _repo = AdhkarRepository();
  Adhkar? _adhkar;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final a = await _repo.load();
      setState(() => _adhkar = a);
    } catch (e) {
      setState(() => _error = 'Could not load adhkar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adhkar')),
      body: _build(),
    );
  }

  Widget _build() {
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_adhkar == null) return const Center(child: CircularProgressIndicator());

    // Display in a predictable order even if JSON key order differs.
    const order = ['morning', 'evening', 'afterPrayer', 'beforeSleep'];
    final icons = {
      'morning': Icons.wb_twilight,
      'evening': Icons.nightlight_round,
      'afterPrayer': Icons.mosque,
      'beforeSleep': Icons.bedtime,
    };

    final cats = [
      for (final id in order)
        if (_adhkar!.categories.containsKey(id)) _adhkar!.categories[id]!
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cats.length,
      itemBuilder: (context, i) {
        final c = cats[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(icons[c.id] ?? Icons.book, size: 32),
            title: Text(c.titleEn,
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${c.entries.length} adhkar  •  ${c.subtitle}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AdhkarListScreen(category: c)),
            ),
          ),
        );
      },
    );
  }
}
