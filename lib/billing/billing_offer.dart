class BillingOffer {
  final String title;
  final String price;
  final String period;
  const BillingOffer({required this.title, required this.price, required this.period});
}

enum BuyResult { success, cancelled, failed }
