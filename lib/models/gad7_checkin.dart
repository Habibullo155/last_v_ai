import 'package:LOMALU/l10n/app_localizations.dart';
import 'phq9_checkin.dart' show pfizerFrequencyScaleLabels;

/// Официальный перевод GAD-7 (Copyright© 1999 Pfizer Inc., с 2010 года
/// распространяется без ограничений авторского права и без платы).
/// Разработан докторами Spitzer, Williams, Kroenke, Löwe и коллегами.
/// Функция, а не константный список - l10n.of(context) требует
/// BuildContext, недоступный на уровне файла/константы.
List<String> gad7Questions(AppLocalizations l10n) => [
  l10n.gad7Q1,
  l10n.gad7Q2,
  l10n.gad7Q3,
  l10n.gad7Q4,
  l10n.gad7Q5,
  l10n.gad7Q6,
  l10n.gad7Q7,
];

/// Общая с PHQ-9 шкала ответов - см. models/phq9_checkin.dart.
List<String> gad7ResponseLabels(AppLocalizations l10n) =>
    pfizerFrequencyScaleLabels(l10n);

class Gad7Checkin {
  final String id;
  final DateTime date;
  final List<int> answers; // 7 значений, каждое 0-3

  Gad7Checkin({required this.id, required this.date, required this.answers});

  int get rawScore => answers.fold(0, (sum, a) => sum + a);

  /// Официальный порог методики GAD-7 для рекомендации дополнительной
  /// оценки специалистом — 10 и выше.
  bool get suggestsFurtherAssessment => rawScore >= 10;

  /// Описание выраженности симптомов по официальным границам методики —
  /// не диагноз, а то, как сама методика описывает диапазон результата.
  String severityLabel(AppLocalizations l10n) {
    if (rawScore <= 4) return l10n.pfizerSeverityMinimal;
    if (rawScore <= 9) return l10n.pfizerSeverityMild;
    if (rawScore <= 14) return l10n.pfizerSeverityModerate;
    return l10n.pfizerSeveritySevere;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'answers': answers,
  };

  factory Gad7Checkin.fromJson(Map<String, dynamic> json) {
    return Gad7Checkin(
      id: json['id'] as String,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
    );
  }
}
