import 'package:flutter_test/flutter_test.dart';
import 'package:ai_glass_chat/models/wellbeing_checkin.dart';

void main() {
  group('WellbeingCheckin scoring (WHO-5)', () {
    test('rawScore sums all five answers', () {
      final checkin = WellbeingCheckin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [5, 4, 3, 2, 1],
      );
      expect(checkin.rawScore, 15);
    });

    test('percentScore is rawScore * 4 (official WHO-5 scaling to 0-100)', () {
      final checkin = WellbeingCheckin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [5, 5, 5, 5, 5], // максимум, raw=25
      );
      expect(checkin.rawScore, 25);
      expect(checkin.percentScore, 100);
    });

    test('percentScore is 0 when all answers are 0', () {
      final checkin = WellbeingCheckin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [0, 0, 0, 0, 0],
      );
      expect(checkin.percentScore, 0);
    });

    test('suggestsFurtherAssessment is true below the official 50% threshold', () {
      // raw=12 -> percent=48, ниже официального порога ВОЗ (50%)
      final checkin = WellbeingCheckin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [3, 3, 3, 2, 1],
      );
      expect(checkin.percentScore, 48);
      expect(checkin.suggestsFurtherAssessment, isTrue);
    });

    test('suggestsFurtherAssessment is false at or above 50%', () {
      // raw=13 -> percent=52
      final checkin = WellbeingCheckin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [3, 3, 3, 3, 1],
      );
      expect(checkin.percentScore, 52);
      expect(checkin.suggestsFurtherAssessment, isFalse);
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = WellbeingCheckin(
        id: 'abc-123',
        date: DateTime(2026, 3, 15, 10, 30),
        answers: [4, 3, 2, 1, 0],
      );
      final restored = WellbeingCheckin.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.date, original.date);
      expect(restored.answers, original.answers);
      expect(restored.rawScore, original.rawScore);
    });
  });
}
