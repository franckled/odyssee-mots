import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'billing_offer.dart';

export 'billing_offer.dart';

/// Clés publiques RevenueCat (non secrètes), fournies à la compilation.
const _appleKey = String.fromEnvironment('RC_APPLE_KEY');
const _googleKey = String.fromEnvironment('RC_GOOGLE_KEY');

/// Nom du « droit » configuré dans RevenueCat.
const entitlementId = 'premium';

class Billing {
  static bool _ready = false;
  static Package? _monthly;

  static String get _key {
    if (defaultTargetPlatform == TargetPlatform.iOS) return _appleKey;
    if (defaultTargetPlatform == TargetPlatform.android) return _googleKey;
    return '';
  }

  static bool get available => _key.isNotEmpty;

  /// L'identifiant RevenueCat est l'identifiant anonyme de l'appareil :
  /// le serveur reconnaît ainsi l'abonné sans rien savoir de la famille.
  static Future<void> init(String userId) async {
    if (!available || userId.isEmpty) return;
    try {
      if (!_ready) {
        final config = PurchasesConfiguration(_key)..appUserID = userId;
        await Purchases.configure(config);
        _ready = true;
      } else {
        await Purchases.logIn(userId);
      }
    } catch (_) {
      _ready = false;
    }
  }

  static Future<BillingOffer?> monthlyOffer() async {
    if (!_ready) return null;
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      final pkg = current?.monthly ?? (current != null && current.availablePackages.isNotEmpty ? current.availablePackages.first : null);
      _monthly = pkg;
      if (pkg == null) return null;
      return BillingOffer(
        title: pkg.storeProduct.title,
        price: pkg.storeProduct.priceString,
        period: 'mois',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<BuyResult> buy() async {
    final pkg = _monthly;
    if (!_ready || pkg == null) return BuyResult.failed;
    try {
      // ignore: deprecated_member_use
      await Purchases.purchasePackage(pkg);
      return await isPremium() ? BuyResult.success : BuyResult.failed;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return code == PurchasesErrorCode.purchaseCancelledError ? BuyResult.cancelled : BuyResult.failed;
    } catch (_) {
      return BuyResult.failed;
    }
  }

  static Future<bool> restore() async {
    if (!_ready) return false;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(entitlementId);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isPremium() async {
    if (!_ready) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(entitlementId);
    } catch (_) {
      return false;
    }
  }
}
