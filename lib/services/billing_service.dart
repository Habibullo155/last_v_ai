import 'dart:convert';

import 'package:http/http.dart' as http;

import 'pinned_http_client.dart';

import '../models/billing_plan.dart';

class BillingException implements Exception {
  final String message;
  BillingException(this.message);
  @override
  String toString() => message;
}

class BillingService {
  final http.Client _client = createHttpClient();

  Future<List<BillingPlan>> listPlans(String baseUrl) async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/billing/plans'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw BillingException('Не удалось загрузить тарифы (код ${res.statusCode}).');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => BillingPlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// provider - "stripe" | "yoomoney", человек сам выбирает на экране
  /// покупки. Возвращает ссылку на страницу оплаты (hosted checkout
  /// Stripe либо quickpay-ссылка YooMoney) — открывается во внешнем
  /// браузере, наш код не видит и не обрабатывает данные карты вообще
  /// (см. backend/routers_billing.py).
  /// Возвращает (checkoutUrl, orderId) - orderId заполнен только для
  /// provider="alfabank" (нужен клиенту для последующей проверки через
  /// confirmAlfabankOrder), для stripe/yoomoney остаётся null.
  Future<(String checkoutUrl, String? orderId)> createCheckoutUrl({
    required String baseUrl,
    required String token,
    required String tariff,
    required String provider,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/billing/checkout'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'tariff': tariff, 'provider': provider}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw BillingException(_extractError(res.body) ?? 'Не удалось начать оплату (код ${res.statusCode}).');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final url = data['checkout_url'] as String?;
    if (url == null || url.isEmpty) {
      throw BillingException('Сервер не вернул ссылку на оплату.');
    }
    return (url, data['order_id'] as String?);
  }

  /// Вызывается после возврата на страницу "успех" - НЕ по одному лишь
  /// факту возврата, бэкенд сам перепроверяет статус заказа у Альфа-Банка
  /// своими учётными данными (см. routers_billing.py::confirm_alfabank_order).
  /// Возвращает true, если тариф реально оплачен и зачислен (или был
  /// зачислен раньше - идемпотентно, безопасно вызвать повторно).
  Future<bool> confirmAlfabankOrder({required String baseUrl, required String token, required String orderId}) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/billing/alfabank/confirm'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'order_id': orderId}),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode >= 400) {
      throw BillingException(_extractError(res.body) ?? 'Не удалось проверить статус оплаты (код ${res.statusCode}).');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['paid'] as bool? ?? false;
  }

  String? _extractError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final messages = detail
            .map((e) => e is Map ? e['msg']?.toString() : e.toString())
            .whereType<String>()
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}
