/// Ровно 4 голоса на выбор — 2 женских, 2 мужских, без списков и
/// эвристик "угадай пол по имени" (как было с голосами на устройстве).
/// Набор голосов зависит от того, какой провайдер облачной озвучки
/// активен на сервере (см. /api/settings/public -> tts_provider).
class CloudVoice {
  final String name;
  final String label; // то, что видит пользователь
  final bool isFemale;

  const CloudVoice({required this.name, required this.label, required this.isFemale});
}

/// Google Cloud TTS (тариф Chirp3-HD) — имена голосов одинаковые для всех
/// языков, меняется только префикс локали. Список голосов у Google
/// иногда меняется — если эти конкретные имена перестанут существовать,
/// достаточно поправить только этот файл.
const List<CloudVoice> googleCloudVoices = [
  CloudVoice(name: 'ru-RU-Chirp3-HD-Aoede', label: 'Женский 1', isFemale: true),
  CloudVoice(name: 'ru-RU-Chirp3-HD-Kore', label: 'Женский 2', isFemale: true),
  CloudVoice(name: 'ru-RU-Chirp3-HD-Charon', label: 'Мужской 1', isFemale: false),
  CloudVoice(name: 'ru-RU-Chirp3-HD-Puck', label: 'Мужской 2', isFemale: false),
];

/// Yandex SpeechKit — специализируется на русском языке, голоса обучены
/// конкретно на русских дикторах. alena — голос по умолчанию у Yandex.
const List<CloudVoice> yandexCloudVoices = [
  CloudVoice(name: 'alena', label: 'Женский 1 (Алёна)', isFemale: true),
  CloudVoice(name: 'jane', label: 'Женский 2 (Джейн)', isFemale: true),
  CloudVoice(name: 'filipp', label: 'Мужской 1 (Филипп)', isFemale: false),
  CloudVoice(name: 'ermil', label: 'Мужской 2 (Ермил)', isFemale: false),
];

/// SaluteSpeech (Сбер) — у физлиц самый щедрый по-настоящему бесплатный
/// тариф среди проверенных вариантов (200 000 символов синтеза в месяц).
/// Честная оговорка: эти имена голосов подтверждены как реально
/// существующие (встречаются в нескольких независимых открытых
/// библиотеках), но их пол я не смог подтвердить с уверенностью при
/// подготовке кода — поэтому подписаны без утверждения "мужской"/
/// "женский" прямо в названии, просто послушай и выбери подходящий.
const List<CloudVoice> saluteCloudVoices = [
  CloudVoice(name: 'Nec_24000', label: 'Голос 1', isFemale: true),
  CloudVoice(name: 'May_24000', label: 'Голос 2', isFemale: true),
  CloudVoice(name: 'Ost_24000', label: 'Голос 3', isFemale: false),
  CloudVoice(name: 'Bys_24000', label: 'Голос 4', isFemale: false),
];

/// Выбирает нужный список по имени провайдера, которое присылает
/// /api/settings/public — "google", "yandex", "salute" или "silero". На
/// неизвестное значение (или null) отвечает пустым списком, а не падает
/// — вызывающий код уже умеет показывать "голоса ещё не загрузились"
/// для пустого списка.
List<CloudVoice> cloudVoicesFor(String? provider) {
  switch (provider) {
    case 'google':
      return googleCloudVoices;
    case 'yandex':
      return yandexCloudVoices;
    case 'salute':
      return saluteCloudVoices;
    case 'silero':
      return sileroCloudVoices;
    default:
      return const [];
  }
}

/// Silero TTS — открытая модель, поднятая как свой локальный сервер (без
/// ключа вообще). Имена и пол голосов подтверждены напрямую из
/// официального репозитория github.com/snakers4/silero-models (v4_ru/
/// v5_ru: aidar, baya, kseniya, xenia, eugene, random).
const List<CloudVoice> sileroCloudVoices = [
  CloudVoice(name: 'baya', label: 'Женский 1 (Бая)', isFemale: true),
  CloudVoice(name: 'kseniya', label: 'Женский 2 (Ксения)', isFemale: true),
  CloudVoice(name: 'aidar', label: 'Мужской 1 (Айдар)', isFemale: false),
  CloudVoice(name: 'eugene', label: 'Мужской 2 (Евгений)', isFemale: false),
];
