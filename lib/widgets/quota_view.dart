import 'package:flutter/material.dart';

import '../screens/parent_screen.dart';
import '../theme.dart';
import 'parent_gate.dart';

/// Affiché quand les histoires du jour sont épuisées : doux pour l'enfant,
/// avec un accès (protégé) pour le parent.
class QuotaReachedView extends StatelessWidget {
  final String message;
  const QuotaReachedView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🌙', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 10),
          const Text('En attendant, tu peux relire tes histoires dans ta bibliothèque 📚',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 17)),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Retour à l\'accueil'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              if (!await askParentGate(context)) return;
              if (!context.mounted) return;
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentScreen()));
            },
            icon: const Icon(Icons.lock_outline),
            label: const Text('Parents : plus d\'histoires'),
          ),
        ]),
      ),
    );
  }
}

/// Fenêtre de bienvenue pour le parent, au premier lancement.
Future<bool> askParentConsent(BuildContext context) async {
  var accepted = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Bienvenue dans Odyssée Mots'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                '• Les histoires et les illustrations sont créées par une intelligence artificielle, '
                'avec plusieurs contrôles de protection de l\'enfance.\n\n'
                '• Aucune donnée personnelle n\'est demandée. Les histoires restent sur cet appareil.\n\n'
                '• Pour compter les histoires gratuites du jour, l\'application reçoit un identifiant '
                'anonyme et aléatoire, sans lien avec votre identité.\n\n'
                '• Vous pouvez tout effacer à tout moment depuis l\'espace parents.',
                style: TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: accepted,
                onChanged: (v) => setState(() => accepted = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Je suis le parent ou le responsable légal et j\'accepte.'),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Plus tard')),
          FilledButton(onPressed: accepted ? () => Navigator.pop(ctx, true) : null, child: const Text('Commencer')),
        ],
      ),
    ),
  );
  return ok == true;
}
