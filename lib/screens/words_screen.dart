import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../theme.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  late List<NewWord> words = Storage.instance.words;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon carnet de mots')),
      body: words.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '📝\n\nPendant tes lectures, touche « Mot à découvrir » pour ranger les mots nouveaux ici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: AppColors.navy),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: words.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final w = words[i];
                return Dismissible(
                  key: ValueKey(w.word),
                  onDismissed: (_) {
                    Storage.instance.removeWord(w.word);
                    setState(() => words = Storage.instance.words);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: i.isEven ? AppColors.sun.withValues(alpha: 0.3) : AppColors.mint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.word,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.coral)),
                        const SizedBox(height: 4),
                        Text(w.definition, style: storyTextStyle(18)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
