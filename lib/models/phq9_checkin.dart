import 'package:LOMALU/l10n/app_localizations.dart';

/// Официальный перевод PHQ-9 (Copyright© 1999 Pfizer Inc., с 2010 года
/// распространяется без ограничений авторского права и без платы —
/// разрешение на воспроизведение, перевод и распространение не требуется).
/// Разработан докторами Spitzer, Williams, Kroenke и коллегами. Английский
/// текст - официальная публикация (оригинальный язык методики), русский -
/// официальный перевод, не собственный перевод английского обратно.
///
/// Период в оригинале — "за последние 2 недели": некоторые русские PDF
/// в обороте указывают "за последнюю неделю", но пороги оценки (5/10/15/20)
/// валидированы именно на двухнедельном периоде — используем его.
///
/// Функции, а не константные списки - l10n.of(context) требует
/// BuildContext, недоступный на уровне файла/константы.
List<String> phq9Questions(AppLocalizations l10n) => [
  l10n.phq9Q1,
  l10n.phq9Q2,
  l10n.phq9Q3,
  l10n.phq9Q4,
  l10n.phq9Q5,
  l10n.phq9Q6,
  l10n.phq9Q7,
  l10n.phq9Q8,
  l10n.phq9Q9,
];

/// Общая для PHQ-9 и GAD-7 шкала ответов (тот же официальный
/// четырёхбалльный вариант у обеих методик Pfizer).
List<String> pfizerFrequencyScaleLabels(AppLocalizations l10n) => [
  l10n.pfizerScaleNotAtAll,
  l10n.pfizerScaleSeveralDays,
  l10n.pfizerScaleMoreThanHalf,
  l10n.pfizerScaleNearlyEveryDay,
];

/// Индекс пункта 9 (0-based) — единственный пункт, требующий немедленной,
/// отдельной от общего результата реакции (мысли о смерти/самоповреждении).
const phq9RiskItemIndex = 8;

class Phq9Checkin {
  final String id;
  final DateTime date;
  final List<int> answers; // 9 значений, каждое 0-3

  Phq9Checkin({required this.id, required this.date, required this.answers});

  int get rawScore => answers.fold(0, (sum, a) => sum + a);

  /// true, если на пункт про мысли о смерти/самоповреждении дан любой
  /// ответ кроме "совсем не беспокоило" — требует немедленного показа
  /// кризисных контактов, отдельно от итогового результата.
  bool get hasRiskSignal =>
      answers.length > phq9RiskItemIndex && answers[phq9RiskItemIndex] > 0;

  /// Официальный порог методики PHQ-9 для рекомендации дополнительной
  /// оценки специалистом — 10 и выше.
  bool get suggestsFurtherAssessment => rawScore >= 10;

  /// Описание выраженности симптомов по официальным границам методики —
  /// не диагноз, а то, как сама методика описывает диапазон результата.
  String severityLabel(AppLocalizations l10n) {
    if (rawScore <= 4) return l10n.pfizerSeverityMinimal;
    if (rawScore <= 9) return l10n.pfizerSeverityMild;
    if (rawScore <= 14) return l10n.pfizerSeverityModerate;
    if (rawScore <= 19) return l10n.phq9SeverityModeratelySevere;
    return l10n.pfizerSeveritySevere;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'answers': answers,
  };

  factory Phq9Checkin.fromJson(Map<String, dynamic> json) {
    return Phq9Checkin(
      id: json['id'] as String,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
    );
  }
}
