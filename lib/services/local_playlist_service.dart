import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_playlist.dart';

/// Всё хранится только в SharedPreferences, на сервер никогда не уходит -
/// см. комментарий в local_playlist.dart про то, почему это принципиально
/// личная, не общая сущность.
class LocalPlaylistService {
  static const _playlistsKey = 'local_playlists_v1';
  static const _tracksKey = 'local_playlist_tracks_v1';
  static const _likesKey = 'local_playlist_likes_v1';

  Future<List<LocalPlaylist>> loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_playlistsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => LocalPlaylist.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlaylists(List<LocalPlaylist> playlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_playlistsKey, jsonEncode(playlists.map((p) => p.toJson()).toList()));
    } catch (_) {
      // не удалось сохранить - изменение останется только в памяти до
      // следующей успешной попытки, ничего критичного не сломается
    }
  }

  Future<List<LocalTrack>> loadTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tracksKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => LocalTrack.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTracks(List<LocalTrack> tracks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tracksKey, jsonEncode(tracks.map((t) => t.toJson()).toList()));
    } catch (_) {
      // см. комментарий в savePlaylists выше
    }
  }

  Future<Set<String>> loadLikes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_likesKey) ?? []).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveLikes(Set<String> likes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_likesKey, likes.toList());
    } catch (_) {
      // см. комментарий в savePlaylists выше
    }
  }
}
