/// Ровно 4 голоса на выбор — 2 женских, 2 мужских. Silero TTS — открытая
/// модель, поднятая как свой локальный сервер (без ключа вообще). Имена
/// и пол голосов подтверждены напрямую из официального репозитория
/// github.com/snakers4/silero-models (v4_ru/v5_ru: aidar, baya, kseniya,
/// xenia, eugene, random).
class CloudVoice {
  final String name;
  final String label; // то, что видит пользователь
  final bool isFemale;

  const CloudVoice({required this.name, required this.label, required this.isFemale});
}

const List<CloudVoice> sileroCloudVoices = [
  CloudVoice(name: 'baya', label: 'Женский 1 (Бая)', isFemale: true),
  CloudVoice(name: 'kseniya', label: 'Женский 2 (Ксения)', isFemale: true),
  CloudVoice(name: 'aidar', label: 'Мужской 1 (Айдар)', isFemale: false),
  CloudVoice(name: 'eugene', label: 'Мужской 2 (Евгений)', isFemale: false),
];
