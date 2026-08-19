import 'package:flutter_test/flutter_test.dart';
import 'package:ai_glass_chat/models/usage_info.dart';

void main() {
  group('UsageInfo.usageFraction', () {
    test('null when tariff has no limit (unlimited)', () {
      final usage = UsageInfo(
        tariff: 'unlimited',
        tokensUsedThisMonth: 5000,
        tokensLimit: null,
        periodStart: DateTime.now(),
      );
      expect(usage.usageFraction, isNull);
    });

    test('null when limit is exactly zero (avoids division by zero)', () {
      final usage = UsageInfo(
        tariff: 'free',
        tokensUsedThisMonth: 0,
        tokensLimit: 0,
        periodStart: DateTime.now(),
      );
      expect(usage.usageFraction, isNull);
    });

    test('computes correct fraction under the limit', () {
      final usage = UsageInfo(
        tariff: 'free',
        tokensUsedThisMonth: 250,
        tokensLimit: 1000,
        periodStart: DateTime.now(),
      );
      expect(usage.usageFraction, 0.25);
    });

    test('clamps to 1.0 when usage exceeds the limit', () {
      final usage = UsageInfo(
        tariff: 'free',
        tokensUsedThisMonth: 1500,
        tokensLimit: 1000,
        periodStart: DateTime.now(),
      );
      expect(usage.usageFraction, 1.0);
    });
  });

  group('UsageInfo.fromJson', () {
    test('parses tokens_limit: null as unlimited', () {
      final usage = UsageInfo.fromJson({
        'tariff': 'unlimited',
        'tokens_used_this_month': 100,
        'tokens_limit': null,
        'period_start': '2026-01-01T00:00:00Z',
      });
      expect(usage.tokensLimit, isNull);
    });
  });
}
