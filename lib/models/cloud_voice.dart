import 'package:LOMALU/l10n/app_localizations.dart';

/// Стандартные голоса из библиотеки ElevenLabs - доступны на любом
/// аккаунте по умолчанию, без клонирования или дополнительной настройки.
/// voice_id подтверждены из официальной документации
/// elevenlabs.io/docs/voices (набор "Premade voices").
///
/// Честно: список статичный, не запрашивается динамически с самого
/// ElevenLabs. Если на аккаунте есть свои клонированные голоса - их
/// придётся добавить сюда вручную (voice_id виден в личном кабинете
/// ElevenLabs, раздел Voices). Динамический список через их API
/// /v1/voices был бы надёжнее, но требует отдельного бэкенд-эндпоинта.
class CloudVoice {
  final String name; // voice_id ElevenLabs
  final String
  properName; // Rachel/Bella/Josh/Adam - собственное имя, не переводится
  final bool isFemale;

  const CloudVoice({
    required this.name,
    required this.properName,
    required this.isFemale,
  });

  // готовая метка для показа пользователю ("Rachel (женский)") - метод,
  // а не константное поле, потому что l10n.of(context) требует
  // BuildContext, недоступный на уровне константы этого списка.
  // voice_store.dart, где этот список тоже используется, метку вообще
  // не трогает - работает только с name (voice_id), поэтому весь список
  // остаётся const, а не превращается в функцию целиком
  String label(AppLocalizations l10n) => isFemale
      ? l10n.cloudVoiceLabelFemale(properName)
      : l10n.cloudVoiceLabelMale(properName);
}

const List<CloudVoice> elevenLabsCloudVoices = [
  CloudVoice(
    name: '21m00Tcm4TlvDq8ikWAM',
    properName: 'Rachel',
    isFemale: true,
  ),
  CloudVoice(name: 'EXAVITQu4vr4xnSDxMaL', properName: 'Bella', isFemale: true),
  CloudVoice(name: 'TxGEqnHWrfWFTfGW9XjX', properName: 'Josh', isFemale: false),
  CloudVoice(name: 'pNInz6obpgDQGcFmaJgB', properName: 'Adam', isFemale: false),
];
