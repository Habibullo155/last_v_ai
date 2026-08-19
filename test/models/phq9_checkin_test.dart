import 'package:flutter_test/flutter_test.dart';
import 'package:ai_last_v/models/phq9_checkin.dart';

void main() {
  group('Phq9Checkin scoring', () {
    test('rawScore sums all nine answers', () {
      final checkin = Phq9Checkin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [3, 2, 1, 0, 3, 2, 1, 0, 0],
      );
      expect(checkin.rawScore, 12);
    });

    test('suggestsFurtherAssessment true at official threshold of 10', () {
      final checkin = Phq9Checkin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [2, 2, 2, 2, 1, 1, 0, 0, 0], // sum = 10
      );
      expect(checkin.rawScore, 10);
      expect(checkin.suggestsFurtherAssessment, isTrue);
    });

    test('suggestsFurtherAssessment false just below threshold', () {
      final checkin = Phq9Checkin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [2, 2, 2, 1, 1, 1, 0, 0, 0], // sum = 9
      );
      expect(checkin.rawScore, 9);
      expect(checkin.suggestsFurtherAssessment, isFalse);
    });

    test('severityLabel matches official PHQ-9 bands', () {
      String labelFor(int score) {
        final answers = List.filled(9, 0);
        var remaining = score;
        for (var i = 0; i < answers.length && remaining > 0; i++) {
          final take = remaining > 3 ? 3 : remaining;
          answers[i] = take;
          remaining -= take;
        }
        return Phq9Checkin(id: '1', date: DateTime(2026, 1, 1), answers: answers).severityLabel;
      }

      expect(labelFor(2), 'минимальная выраженность');
      expect(labelFor(7), 'лёгкая выраженность');
      expect(labelFor(12), 'умеренная выраженность');
      expect(labelFor(17), 'умеренно выраженная тяжесть');
      expect(labelFor(24), 'выраженная тяжесть симптомов');
    });

    test('hasRiskSignal true when item 9 (index 8) answered above zero', () {
      final checkin = Phq9Checkin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [0, 0, 0, 0, 0, 0, 0, 0, 1],
      );
      expect(checkin.hasRiskSignal, isTrue);
    });

    test('hasRiskSignal false when item 9 answered zero, even with high total elsewhere', () {
      final checkin = Phq9Checkin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [3, 3, 3, 3, 3, 3, 3, 3, 0],
      );
      expect(checkin.rawScore, 24);
      expect(checkin.hasRiskSignal, isFalse);
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = Phq9Checkin(
        id: 'abc-123',
        date: DateTime(2026, 3, 15, 10, 30),
        answers: [1, 0, 2, 3, 0, 1, 2, 0, 0],
      );
      final restored = Phq9Checkin.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.date, original.date);
      expect(restored.answers, original.answers);
      expect(restored.rawScore, original.rawScore);
      expect(restored.hasRiskSignal, original.hasRiskSignal);
    });
  });
}
