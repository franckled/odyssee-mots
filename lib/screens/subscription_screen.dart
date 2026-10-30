import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../billing/billing.dart';
import '../storage.dart';
import '../theme.dart';

const privacyUrl = 'https://franckled.github.io/odyssee-mots/confidentialite.html';
const termsUrl = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

Future<void> openLink(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Écran d'abonnement (uniquement dans l'espace parents, derrière la barrière).
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  BillingOffer? offer;
  bool loading = true;
  bool busy = false;
  bool premium = false;
  String? message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Billing.init(Storage.instance.deviceId);
    final o = await Billing.monthlyOffer();
    final p = await Billing.isPremium();
    if (!mounted) return;
    setState(() {
      offer = o;
      premium = p;
      loading = false;
    });
  }

  Future<void> _refreshServer() async {
    // Le serveur est prévenu par RevenueCat en quelques secondes.
    for (var i = 0; i < 5; i++) {
      try {
        final q = await StoryApi().status();
        if (q.premium) return;
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _buy() async {
    setState(() {
      busy = true;
      message = null;
    });
    final r = await Billing.buy();
    if (r == BuyResult.success) await _refreshServer();
    if (!mounted) return;
    setState(() {
      busy = false;
      premium = r == BuyResult.success || premium;
      message = switch (r) {
        BuyResult.success => '🌟 Merci ! L\'abonnement est actif.',
        BuyResult.cancelled => null,
        BuyResult.failed => 'L\'achat n\'a pas abouti. Réessayez plus tard.',
      };
    });
  }

  Future<void> _restore() async {
    setState(() {
      busy = true;
      message = null;
    });
    final ok = await Billing.restore();
    if (ok) await _refreshServer();
    if (!mounted) return;
    setState(() {
      busy = false;
      premium = ok || premium;
      message = ok ? '🌟 Abonnement retrouvé !' : 'Aucun abonnement trouvé pour ce compte Apple ou Google.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('🌟', textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              const Text('Odyssée Mots Illimité',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.navy)),
              const SizedBox(height: 18),
              const _Benefit('📖', 'Jusqu\'à 10 histoires illustrées par jour, au lieu de 2'),
              const _Benefit('🎨', 'Toutes les tranches d\'âge et tous les univers'),
              const _Benefit('🛡️', 'Les mêmes protections pour votre enfant, sans publicité'),
              const SizedBox(height: 20),
              if (!Billing.available)
                const _Box('L\'abonnement se prend depuis l\'application iPhone ou Android.')
              else if (loading)
                const Center(child: CircularProgressIndicator())
              else if (premium)
                const _Box('🌟 Votre abonnement est actif. Merci de soutenir la lecture !')
              else if (offer == null)
                const _Box('L\'offre n\'est pas disponible pour le moment. Réessayez plus tard.')
              else ...[
                Text('${offer!.price} par ${offer!.period}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.coral)),
                const SizedBox(height: 6),
                const Text(
                  'Abonnement mensuel renouvelé automatiquement. Résiliable à tout moment depuis les réglages '
                  'de votre compte Apple ou Google, au moins 24 h avant la fin de la période en cours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : _buy,
                  child: Text(busy ? 'Un instant…' : 'S\'abonner'),
                ),
              ],
              if (Billing.available) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: busy ? null : _restore, child: const Text('Restaurer mes achats')),
              ],
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(message!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  TextButton(onPressed: () => openLink(termsUrl), child: const Text('Conditions d\'utilisation')),
                  TextButton(onPressed: () => openLink(privacyUrl), child: const Text('Confidentialité')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String emoji;
  final String text;
  const _Benefit(this.emoji, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17))),
        ]),
      );
}

class _Box extends StatelessWidget {
  final String text;
  const _Box(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.sun.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
      );
}
