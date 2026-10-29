import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import 'reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late List<Story> stories = Storage.instance.stories;

  Future<void> _open(Story st) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen.resume(st)));
    if (mounted) setState(() => stories = Storage.instance.stories);
  }

  Future<void> _delete(Story st) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ranger cette histoire à la poubelle ?'),
        content: Text('« ${st.title} » sera supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
        ],
      ),
    );
    if (ok != true) return;
    await Storage.instance.deleteStory(st.id);
    setState(() => stories = Storage.instance.stories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ma bibliothèque')),
      body: stories.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('📚\n\nTes histoires apparaîtront ici.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 22, color: AppColors.navy)),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemCount: stories.length,
              itemBuilder: (_, i) {
                final st = stories[i];
                final emoji = universes.firstWhere((u) => u.key == st.universe, orElse: () => universes.last).emoji;
                return Material(
                  color: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _open(st),
                    onLongPress: () => _delete(st),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: st.cover != null
                              ? Image.memory(st.cover!, fit: BoxFit.cover)
                              : Container(
                                  color: AppColors.sky.withValues(alpha: 0.4),
                                  alignment: Alignment.center,
                                  child: Text(emoji, style: const TextStyle(fontSize: 56)),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                          child: Text(st.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            st.finished ? '✅ Terminée' : '📖 Page ${st.pagesRead} / ${st.totalPages}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
