import 'package:flutter_test/flutter_test.dart';
import 'package:ai_last_v/models/admin_user.dart';

AdminUser _makeUser({
  DateTime? lastActiveAt,
  DateTime? tariffExpiresAt,
  String role = 'user',
}) {
  return AdminUser(
    id: 1,
    email: 'test@test.com',
    role: role,
    tariff: 'pro',
    isActive: true,
    createdAt: DateTime.now(),
    lastActiveAt: lastActiveAt,
    tariffExpiresAt: tariffExpiresAt,
  );
}

void main() {
  group('AdminUser.isOnlineNow', () {
    test('true when last active less than 15 minutes ago', () {
      final user = _makeUser(lastActiveAt: DateTime.now().subtract(const Duration(minutes: 5)));
      expect(user.isOnlineNow, isTrue);
    });

    test('false when last active more than 15 minutes ago', () {
      final user = _makeUser(lastActiveAt: DateTime.now().subtract(const Duration(minutes: 20)));
      expect(user.isOnlineNow, isFalse);
    });

    test('false when never active', () {
      final user = _makeUser(lastActiveAt: null);
      expect(user.isOnlineNow, isFalse);
    });
  });

  group('AdminUser subscription expiry', () {
    test('daysUntilExpiry is null for an unlimited (no-expiry) tariff', () {
      final user = _makeUser(tariffExpiresAt: null);
      expect(user.daysUntilExpiry, isNull);
      expect(user.isTariffExpired, isFalse);
    });

    test('isTariffExpired true for a date in the past, even less than 24h ago', () {
      // Регрессия: daysUntilExpiry через Duration.inDays округляет К НУЛЮ,
      // а не вниз — 30 минут назад раньше давало inDays=0, из-за чего
      // isTariffExpired ошибочно говорила "не истекло" почти сутки.
      final user = _makeUser(tariffExpiresAt: DateTime.now().subtract(const Duration(minutes: 30)));
      expect(user.isTariffExpired, isTrue);
    });

    test('isTariffExpired true for a date clearly in the past (several days)', () {
      final user = _makeUser(tariffExpiresAt: DateTime.now().subtract(const Duration(days: 5)));
      expect(user.isTariffExpired, isTrue);
      expect(user.daysUntilExpiry, lessThan(0));
    });

    test('isTariffExpired false for a date in the future', () {
      final user = _makeUser(tariffExpiresAt: DateTime.now().add(const Duration(days: 10)));
      expect(user.isTariffExpired, isFalse);
      expect(user.daysUntilExpiry, greaterThan(0));
    });
  });

  group('AdminUser.isAdmin', () {
    test('true for role "admin"', () {
      expect(_makeUser(role: 'admin').isAdmin, isTrue);
    });

    test('false for role "user"', () {
      expect(_makeUser(role: 'user').isAdmin, isFalse);
    });
  });

  group('AdminUser.fromJson', () {
    test('parses a full server response correctly', () {
      final user = AdminUser.fromJson({
        'id': 42,
        'email': 'a@test.com',
        'role': 'admin',
        'tariff': 'unlimited',
        'is_active': true,
        'created_at': '2026-01-01T00:00:00Z',
        'last_active_at': '2026-01-02T00:00:00Z',
        'tariff_expires_at': null,
      });
      expect(user.id, 42);
      expect(user.email, 'a@test.com');
      expect(user.isAdmin, isTrue);
      expect(user.tariffExpiresAt, isNull);
    });

    test('applies safe defaults for missing optional fields', () {
      final user = AdminUser.fromJson({
        'id': 1,
        'email': 'a@test.com',
        'is_active': true,
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(user.role, 'user');
      expect(user.tariff, 'free');
      expect(user.lastActiveAt, isNull);
    });
  });
}
