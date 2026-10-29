import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Barrière parentale : une multiplication qu'un jeune enfant ne sait pas
/// encore faire. Exigée par Apple et Google pour les applis « Enfants »
/// avant tout réglage, lien externe ou achat.
Future<bool> askParentGate(BuildContext context) async {
  final rnd = Random();
  final a = 6 + rnd.nextInt(4); // 6 à 9
  final b = 6 + rnd.nextInt(4);
  final ctrl = TextEditingController();
  String? error;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Espace réservé aux parents 🔒'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Combien font $a × $b ?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Réponse',
                errorText: error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                if (int.tryParse(ctrl.text.trim()) == a * b) {
                  Navigator.pop(ctx, true);
                } else {
                  setState(() => error = 'Ce n\'est pas la bonne réponse');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (int.tryParse(ctrl.text.trim()) == a * b) {
                Navigator.pop(ctx, true);
              } else {
                setState(() => error = 'Ce n\'est pas la bonne réponse');
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    ),
  );
  return ok == true;
}
