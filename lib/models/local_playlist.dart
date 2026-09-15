// ignore_for_file: unintended_html_in_doc_comment

/// Плейлисты и загруженные треки — ПОЛНОСТЬЮ локальные, на сервер
/// никогда не отправляются (в отличие от SoundAsset/SoundsService,
/// которые загружает админ на сервер для всех). Это личная надстройка
/// каждого человека поверх общего каталога: можно составить свой список
/// из готовых звуков каталога, добавить туда собственные файлы с
/// устройства, лайкнуть что угодно, убрать трек из СВОЕГО плейлиста, не
/// трогая ни общий каталог, ни чужие плейлисты.
library;

/// Ссылка на трек внутри плейлиста - одна строка, кодирующая ДВА разных
/// источника: "sound:<id>" - готовый звук из общего каталога (та же
/// сущность, что SoundAsset, просто по id), "local:<uuid>" - свой файл,
/// добавленный именно этим человеком (см. LocalTrack ниже). Единая схема
/// ссылок нужна, чтобы лайки/состав плейлиста работали одинаково для
/// обоих источников, не задваивая логику.
class TrackRef {
  final String raw;
  const TrackRef._(this.raw);

  factory TrackRef.sound(int soundId) => TrackRef._('sound:$soundId');
  factory TrackRef.local(String localId) => TrackRef._('local:$localId');
  factory TrackRef.parse(String raw) => TrackRef._(raw);

  bool get isSound => raw.startsWith('sound:');
  bool get isLocal => raw.startsWith('local:');

  int get soundId => int.parse(raw.substring('sound:'.length));
  String get localId => raw.substring('local:'.length);

  @override
  bool operator ==(Object other) => other is TrackRef && other.raw == raw;
  @override
  int get hashCode => raw.hashCode;
  @override
  String toString() => raw;
}

/// Свой файл, добавленный с устройства - не копия чужого звука, а
/// именно ЛИЧНЫЙ трек, видимый только на этом устройстве.
class LocalTrack {
  final String id;
  final String title;
  // null на вебе - там нет стабильного пути к выбранному файлу между
  // перезагрузками страницы (браузер не даёт такой доступ), трек
  // остаётся играбельным только до перезагрузки. На остальных
  // платформах путь переживает перезапуск приложения, если сам файл
  // никуда не делся с устройства.
  final String? filePath;
  final DateTime addedAt;

  LocalTrack({required this.id, required this.title, required this.filePath, required this.addedAt});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'file_path': filePath,
        'added_at': addedAt.toIso8601String(),
      };

  factory LocalTrack.fromJson(Map<String, dynamic> json) => LocalTrack(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        filePath: json['file_path'] as String?,
        addedAt: DateTime.tryParse(json['added_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class LocalPlaylist {
  final String id;
  String name;
  final List<TrackRef> trackRefs;

  LocalPlaylist({required this.id, required this.name, List<TrackRef>? trackRefs}) : trackRefs = trackRefs ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'track_refs': trackRefs.map((t) => t.raw).toList(),
      };

  factory LocalPlaylist.fromJson(Map<String, dynamic> json) => LocalPlaylist(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        trackRefs: ((json['track_refs'] as List<dynamic>?) ?? []).map((r) => TrackRef.parse(r as String)).toList(),
      );
}
