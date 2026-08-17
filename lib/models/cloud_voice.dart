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

/// Выбирает нужный список по имени провайдера, которое присылает
/// /api/settings/public — "google" или "yandex". На неизвестное значение
/// (или null) отвечает пустым списком, а не падает — вызывающий код уже
/// умеет показывать "голоса ещё не загрузились" для пустого списка.
List<CloudVoice> cloudVoicesFor(String? provider) {
  switch (provider) {
    case 'google':
      return googleCloudVoices;
    case 'yandex':
      return yandexCloudVoices;
    default:
      return const [];
  }
}
