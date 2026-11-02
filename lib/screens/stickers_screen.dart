import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api.dart';
import '../billing/billing.dart';
import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/parent_gate.dart';
import 'subscription_screen.dart';

/// Album d'autocollants : chaque page illustrée lue y ajoute une vignette.
/// Réservé à l'abonnement ; en version gratuite, l'album reste fermé.
class StickersScreen extends StatefulWidget {
  const StickersScreen({super.key});

  @override
  State<StickersScreen> createState() => _StickersScreenState();
}

class _StickersScreenState extends State<StickersScreen> {
  bool? unlocked;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    var ok = false;
    try {
      final q = await StoryApi().status();
      ok = q.premium || q.admin;
    } catch (_) {
      // Hors ligne : on se fie à l'abonnement connu du téléphone.
      try {
        ok = await Billing.isPremium();
      } catch (_) {}
    }
    if (mounted) setState(() => unlocked = ok);
  }

  Future<void> _openParents() async {
    if (!await askParentGate(context)) return;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
    if (mounted) {
      setState(() => unlocked = null);
      _check();
    }
  }

  void _show(Sticker st) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StickerBadge(image: st.image, size: 220, tilt: 0),
              const SizedBox(height: 16),
              Text(st.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
              const SizedBox(height: 4),
              Text('Page ${st.page}', style: const TextStyle(fontSize: 15, color: Colors.black54)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes autocollants')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: switch (unlocked) {
            null => const Center(child: CircularProgressIndicator()),
            false => _Locked(onParents: _openParents),
            true => _Album(stickers: Storage.instance.stickers, onTap: _show),
          },
        ),
      ),
    );
  }
}

class _Album extends StatelessWidget {
  final List<Sticker> stickers;
  final ValueChanged<Sticker> onTap;
  const _Album({required this.stickers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (stickers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌟', style: TextStyle(fontSize: 72)),
            SizedBox(height: 16),
            Text(
              'Ton album est prêt !\nChaque page illustrée que tu lis devient un autocollant.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, height: 1.4, color: AppColors.navy, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
      ),
      itemCount: stickers.length,
      itemBuilder: (_, i) {
        final st = stickers[i];
        // Légère inclinaison différente pour chaque autocollant, comme collé à la main.
        final tilt = (math.Random(st.key.hashCode).nextDouble() - 0.5) * 0.25;
        return GestureDetector(
          onTap: () => onTap(st),
          child: _StickerBadge(image: st.image, size: 130, tilt: tilt),
        );
      },
    );
  }
}

class _Locked extends StatelessWidget {
  final VoidCallback onParents;
  const _Locked({required this.onParents});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final e in const ['🦊', '🐉', '🚀', '🏰', '🐠', '🦄'])
              Container(
                width: 82,
                height: 82,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lilac, width: 3),
                ),
                child: Opacity(opacity: 0.35, child: Text(e, style: const TextStyle(fontSize: 38))),
              ),
          ],
        ),
        const SizedBox(height: 28),
        const Text('🔒', textAlign: TextAlign.center, style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        const Text(
          'L\'album d\'autocollants fait partie d\'Odyssée Mots Illimité.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        const SizedBox(height: 10),
        const Text(
          'Avec l\'abonnement, chaque page illustrée lue devient un autocollant à collectionner.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 24),
        Center(
          child: OutlinedButton.icon(
            onPressed: onParents,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Espace parents'),
          ),
        ),
      ],
    );
  }
}

/// Vignette ronde avec bordure blanche, comme un vrai autocollant.
class _StickerBadge extends StatelessWidget {
  final Uint8List image;
  final double size;
  final double tilt;
  const _StickerBadge({required this.image, required this.size, required this.tilt});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.05),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: ClipOval(child: Image.memory(image, fit: BoxFit.cover, gaplessPlayback: true)),
      ),
    );
  }
}
