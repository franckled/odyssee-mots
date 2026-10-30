import 'package:flutter/material.dart';

import '../api.dart';
import '../storage.dart';
import '../theme.dart';
import 'subscription_screen.dart';

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
  QuotaStatus? quota;

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    if (!s.isConfigured) return;
    try {
      final q = await StoryApi().status();
      if (mounted) setState(() => quota = q);
    } catch (_) {}
  }

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
      _loadQuota();
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
              const _Title('Formule'),
              _Info(quota == null
                  ? 'Chargement…'
                  : quota!.admin
                      ? 'Mode administrateur : histoires illimitées.'
                      : quota!.premium
                          ? '🌟 Abonnement actif. Aujourd\'hui : ${quota!.used} / ${quota!.limit} histoires.'
                          : 'Formule gratuite : ${quota!.limit} histoires par jour. Aujourd\'hui : ${quota!.used} / ${quota!.limit}.'),
              const SizedBox(height: 10),
              if (quota != null && !quota!.admin && !quota!.premium)
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                    _loadQuota();
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Plus d\'histoires : l\'abonnement'),
                ),
              if (s.deviceId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Identifiant anonyme de cet appareil : ${s.deviceId.substring(0, 8)}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ),
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Réglages avancés', style: TextStyle(fontWeight: FontWeight.w700)),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                children: [
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
                      labelText: 'Code administrateur (facultatif)',
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
                ],
              ),
              const _Title('Comment fonctionne Odyssée Mots ?'),
              const _Info(
                'Les histoires et les illustrations sont créées par une intelligence artificielle, '
                'page après page, selon les choix de votre enfant.\n\n'
                'Chaque page est relue automatiquement par un second contrôle « protection de l\'enfance » '
                'avant d\'être affichée : pas de violence, pas de contenu romantique ou sexuel, pas de secret '
                'à garder vis-à-vis des adultes, pas de stéréotypes, fin toujours rassurante.\n\n'
                'Aucune donnée personnelle n\'est demandée. Les histoires restent sur cet appareil. '
                'Le serveur ne conserve qu\'un identifiant anonyme et un compteur d\'histoires du jour.\n\n'
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
              TextButton(
                onPressed: () => openLink(privacyUrl),
                child: const Text('Politique de confidentialité'),
              ),
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
