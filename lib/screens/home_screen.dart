import 'package:flutter/material.dart';

import '../storage.dart';
import '../theme.dart';
import '../widgets/parent_gate.dart';
import 'library_screen.dart';
import 'parent_screen.dart';
import 'setup_screen.dart';
import 'words_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Storage get s => Storage.instance;

  Future<void> _go(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  Future<void> _openParents() async {
    if (await askParentGate(context)) await _go(const ParentScreen());
  }

  Future<void> _newStory() async {
    if (!s.isConfigured) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Presque prêt ! ✨'),
          content: const Text(
              "Un parent doit d'abord régler l'application dans l'espace parents."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Plus tard')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Espace parents')),
          ],
        ),
      );
      if (ok == true) await _openParents();
      return;
    }
    await _go(const SetupScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      Image.asset('assets/images/accueil.jpg', fit: BoxFit.contain),
                      const SizedBox(height: 20),
                      _StarsBadge(stars: s.stars),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HomeButton(
                              emoji: '📖',
                              label: 'Nouvelle histoire',
                              color: AppColors.coral,
                              onTap: _newStory,
                            ),
                            const SizedBox(height: 14),
                            _HomeButton(
                              emoji: '📚',
                              label: 'Ma bibliothèque',
                              color: AppColors.mint,
                              textColor: AppColors.navy,
                              onTap: () => _go(const LibraryScreen()),
                            ),
                            const SizedBox(height: 14),
                            _HomeButton(
                              emoji: '📝',
                              label: 'Mon carnet de mots',
                              color: AppColors.sun,
                              textColor: AppColors.navy,
                              onTap: () => _go(const WordsScreen()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _openParents,
                        icon: const Icon(Icons.lock_outline, color: Colors.white70),
                        label: const Text('Espace parents', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 4, 24, 20),
                        child: Text(
                          'Histoires et illustrations créées avec une intelligence artificielle.\nVersion 0.1.2',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarsBadge extends StatelessWidget {
  final int stars;
  const _StarsBadge({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        stars == 0 ? '⭐ Lis ta première histoire pour gagner des étoiles !' : '⭐ $stars étoiles de lecture',
        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _HomeButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(26),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
