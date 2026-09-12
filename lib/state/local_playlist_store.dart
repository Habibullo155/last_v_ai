import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/local_playlist.dart';
import '../services/local_playlist_service.dart';

// синглтон - нужен и в sleep_music_screen.dart (управление плейлистами),
// и потенциально в других местах, где может понадобиться лайк/список
// своих треков - тот же приём, что у ThemeStore/NotificationPrefsStore
class LocalPlaylistStore extends ChangeNotifier {
  LocalPlaylistStore._internal();
  static final LocalPlaylistStore instance = LocalPlaylistStore._internal();

  final LocalPlaylistService _service = LocalPlaylistService();
  final _uuid = const Uuid();

  List<LocalPlaylist> playlists = [];
  List<LocalTrack> tracks = [];
  Set<String> likedRefs = {};

  Future<void> load() async {
    playlists = await _service.loadPlaylists();
    tracks = await _service.loadTracks();
    likedRefs = await _service.loadLikes();
    notifyListeners();
  }

  LocalTrack? trackById(String id) {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<LocalPlaylist> createPlaylist(String name) async {
    final playlist = LocalPlaylist(id: _uuid.v4(), name: name);
    playlists = [...playlists, playlist];
    notifyListeners();
    await _service.savePlaylists(playlists);
    return playlist;
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;
    if (playlist == null) return;
    playlist.name = newName;
    notifyListeners();
    await _service.savePlaylists(playlists);
  }

  Future<void> deletePlaylist(String playlistId) async {
    playlists = playlists.where((p) => p.id != playlistId).toList();
    notifyListeners();
    await _service.savePlaylists(playlists);
  }

  /// Добавляет ссылку на трек (готовый звук каталога ИЛИ свой файл) в
  /// плейлист - не дублирует, если такая ссылка там уже есть.
  Future<void> addToPlaylist(String playlistId, TrackRef ref) async {
    final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;
    if (playlist == null || playlist.trackRefs.contains(ref)) return;
    playlist.trackRefs.add(ref);
    notifyListeners();
    await _service.savePlaylists(playlists);
  }

  /// Убирает трек ИМЕННО из этого плейлиста - не трогает ни общий
  /// каталог (если это был "sound:"), ни сам загруженный файл (если
  /// "local:" - файл остаётся в личной библиотеке, просто выходит из
  /// состава этого конкретного плейлиста, его можно добавить обратно
  /// или в другой плейлист).
  Future<void> removeFromPlaylist(String playlistId, TrackRef ref) async {
    final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;
    if (playlist == null) return;
    playlist.trackRefs.remove(ref);
    notifyListeners();
    await _service.savePlaylists(playlists);
  }

  /// Регистрирует свой загруженный файл в личной библиотеке (ещё не в
  /// каком-либо плейлисте - добавление в плейлист отдельным вызовом
  /// addToPlaylist, тем же способом, что и для готовых звуков каталога).
  Future<LocalTrack> addLocalTrack({required String title, required String? filePath}) async {
    final track = LocalTrack(id: _uuid.v4(), title: title, filePath: filePath, addedAt: DateTime.now());
    tracks = [...tracks, track];
    notifyListeners();
    await _service.saveTracks(tracks);
    return track;
  }

  /// Удаляет свой файл ИЗ ЛИЧНОЙ БИБЛИОТЕКИ целиком (не только из
  /// одного плейлиста) - заодно вычищает ссылки на него из ВСЕХ
  /// плейлистов, где он состоял, иначе они указывали бы в никуда.
  Future<void> deleteLocalTrack(String localId) async {
    final ref = TrackRef.local(localId);
    tracks = tracks.where((t) => t.id != localId).toList();
    for (final playlist in playlists) {
      playlist.trackRefs.remove(ref);
    }
    likedRefs.remove(ref.raw);
    notifyListeners();
    await _service.saveTracks(tracks);
    await _service.savePlaylists(playlists);
    await _service.saveLikes(likedRefs);
  }

  bool isLiked(TrackRef ref) => likedRefs.contains(ref.raw);

  Future<void> toggleLike(TrackRef ref) async {
    if (likedRefs.contains(ref.raw)) {
      likedRefs.remove(ref.raw);
    } else {
      likedRefs.add(ref.raw);
    }
    notifyListeners();
    await _service.saveLikes(likedRefs);
  }
}
