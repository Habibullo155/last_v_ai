import 'package:flutter_test/flutter_test.dart';
import 'package:ai_glass_chat/models/gad7_checkin.dart';

void main() {
  group('Gad7Checkin scoring', () {
    test('rawScore sums all seven answers', () {
      final checkin = Gad7Checkin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [3, 2, 1, 0, 3, 2, 1],
      );
      expect(checkin.rawScore, 12);
    });

    test('suggestsFurtherAssessment true at official threshold of 10', () {
      final checkin = Gad7Checkin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [2, 2, 2, 2, 1, 1, 0], // sum = 10
      );
      expect(checkin.rawScore, 10);
      expect(checkin.suggestsFurtherAssessment, isTrue);
    });

    test('suggestsFurtherAssessment false just below threshold', () {
      final checkin = Gad7Checkin(
        id: '1',
        date: DateTime(2026, 1, 1),
        answers: [2, 2, 1, 1, 1, 1, 0], // sum = 8
      );
      expect(checkin.rawScore, 8);
      expect(checkin.suggestsFurtherAssessment, isFalse);
    });

    test('severityLabel matches official GAD-7 bands', () {
      String labelFor(int score) {
        final answers = List.filled(7, 0);
        var remaining = score;
        for (var i = 0; i < answers.length && remaining > 0; i++) {
          final take = remaining > 3 ? 3 : remaining;
          answers[i] = take;
          remaining -= take;
        }
        return Gad7Checkin(id: '1', date: DateTime(2026, 1, 1), answers: answers).severityLabel;
      }

      expect(labelFor(2), 'минимальная выраженность');
      expect(labelFor(7), 'лёгкая выраженность');
      expect(labelFor(12), 'умеренная выраженность');
      expect(labelFor(18), 'выраженная тяжесть симптомов');
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = Gad7Checkin(
        id: 'abc-123',
        date: DateTime(2026, 3, 15, 10, 30),
        answers: [1, 0, 2, 3, 0, 1, 2],
      );
      final restored = Gad7Checkin.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.date, original.date);
      expect(restored.answers, original.answers);
      expect(restored.rawScore, original.rawScore);
    });
  });
}
