import 'billing_offer.dart';

export 'billing_offer.dart';

class Billing {
  static bool get available => false;
  static Future<void> init(String userId) async {}
  static Future<BillingOffer?> monthlyOffer() async => null;
  static Future<BuyResult> buy() async => BuyResult.failed;
  static Future<bool> restore() async => false;
  static Future<bool> isPremium() async => false;
}
