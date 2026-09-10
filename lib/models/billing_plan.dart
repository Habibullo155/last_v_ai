class BillingPlan {
  final String tariff;
  final String label;
  final int durationDays;
  final int priceRubCents;
  final int priceUsdCents;
  final int? monthlyTokenLimit;
  final bool stripeAvailable;
  final bool yoomoneyAvailable;

  BillingPlan({
    required this.tariff,
    required this.label,
    required this.durationDays,
    required this.priceRubCents,
    required this.priceUsdCents,
    required this.monthlyTokenLimit,
    required this.stripeAvailable,
    required this.yoomoneyAvailable,
  });

  bool get isFree => priceRubCents == 0;
  bool get isPurchasable => stripeAvailable || yoomoneyAvailable;
  String get priceRubDisplay => '${(priceRubCents / 100).toStringAsFixed(0)} ₽';
  String get priceUsdDisplay => '\$${(priceUsdCents / 100).toStringAsFixed(2)}';

  factory BillingPlan.fromJson(Map<String, dynamic> json) {
    return BillingPlan(
      tariff: json['tariff'] as String,
      label: json['label'] as String? ?? json['tariff'] as String,
      durationDays: json['duration_days'] as int? ?? 30,
      priceRubCents: json['price_rub_cents'] as int? ?? 0,
      priceUsdCents: json['price_usd_cents'] as int? ?? 0,
      monthlyTokenLimit: json['monthly_token_limit'] as int?,
      stripeAvailable: json['stripe_available'] as bool? ?? false,
      yoomoneyAvailable: json['yoomoney_available'] as bool? ?? false,
    );
  }
}
