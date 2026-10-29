import 'package:flutter/material.dart';

import '../api.dart';
import '../storage.dart';
import '../theme.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  final s = Storage.instance;
  late final urlCtrl = TextEditingController(text: s.workerUrl);
  late final codeCtrl = TextEditingController(text: s.accessCode);
  String? status;
  bool testing = false;
  bool hideCode = true;

  @override
  void dispose() {
    urlCtrl.dispose();
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    s.workerUrl = urlCtrl.text;
    s.accessCode = codeCtrl.text;
    setState(() {
      testing = true;
      status = null;
    });
    try {
      await StoryApi().testConnection();
      status = '✅ Connexion réussie, tout est prêt !';
    } catch (e) {
      status = '❌ $e';
    }
    if (mounted) setState(() => testing = false);
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tout effacer ?'),
        content: const Text('Histoires, carnet de mots, étoiles et signalements seront supprimés de cet appareil.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Effacer')),
        ],
      ),
    );
    if (ok == true) {
      await s.clearAll();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = s.reports;
    return Scaffold(
      appBar: AppBar(title: const Text('Espace parents')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _Title('Réglages du conteur'),
              TextField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Adresse du serveur',
                  hintText: 'https://odyssee-mots.xxxx.workers.dev',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                obscureText: hideCode,
                decoration: InputDecoration(
                  labelText: 'Code d\'accès',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(hideCode ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => hideCode = !hideCode),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: testing ? null : _saveAndTest,
                child: Text(testing ? 'Test en cours…' : 'Enregistrer et tester'),
              ),
              if (status != null)
                Padding(padding: const EdgeInsets.only(top: 10), child: Text(status!, style: const TextStyle(fontSize: 16))),
              const _Title('Comment fonctionne Odyssée Mots ?'),
              const _Info(
                'Les histoires et les illustrations sont créées par une intelligence artificielle, '
                'page après page, selon les choix de votre enfant.\n\n'
                'Chaque page est relue automatiquement par un second contrôle « protection de l\'enfance » '
                'avant d\'être affichée : pas de violence, pas de contenu romantique ou sexuel, pas de secret '
                'à garder vis-à-vis des adultes, pas de stéréotypes, fin toujours rassurante.\n\n'
                'Aucune donnée personnelle n\'est demandée. Les histoires restent sur cet appareil ; '
                'le serveur ne conserve rien.\n\n'
                'Malgré ces protections, une IA peut se tromper. Si une page vous semble inadaptée, '
                'touchez le drapeau 🚩 en haut de la page pour la masquer.',
              ),
              const _Title('Pages signalées'),
              if (reports.isEmpty)
                const _Info('Aucun signalement.')
              else
                for (final r in reports)
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: _Info(r)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Effacer toutes les données de cet appareil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
      );
}

class _Info extends StatelessWidget {
  final String text;
  const _Info(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(fontSize: 15, height: 1.45)),
      );
}
