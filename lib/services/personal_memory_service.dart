import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'pinned_http_client.dart';

import '../models/personal_memory.dart';

class PersonalMemoryException implements Exception {
  final String message;
  PersonalMemoryException(this.message);
  @override
  String toString() => message;
}

class PersonalMemoryService {
  final http.Client _client = createHttpClient();

  String? _extractError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// photoBytes ИЛИ photoPath - при обоих заданных предпочитается
  /// photoPath (недоступен на вебе - см. sounds_service.dart для того
  /// же паттерна): MultipartFile.fromPath читает файл ПОТОКОВО прямо во
  /// время отправки, не загружая его целиком в память заранее. Раньше
  /// единственный вариант - bytes - требовал прочитать весь файл в
  /// память ДО начала отправки.
  Future<PersonalMemory> create({
    required String baseUrl,
    required String token,
    required String comment,
    Uint8List? photoBytes,
    String? photoPath,
    String? filename,
  }) async {
    final uri = Uri.parse('$baseUrl/api/personal-memories');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['comment'] = comment;
    if (filename != null) {
      if (!kIsWeb && photoPath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', photoPath, filename: filename));
      } else if (photoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', photoBytes, filename: filename));
      }
    }

    final streamed = await _client.send(request).timeout(const Duration(minutes: 2));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 400) {
      throw PersonalMemoryException(_extractError(res.body) ?? 'Не удалось сохранить запись.');
    }
    return PersonalMemory.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<PersonalMemory>> list({required String baseUrl, required String token}) async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/personal-memories'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw PersonalMemoryException('Не удалось загрузить записи (код ${res.statusCode}).');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => PersonalMemory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Uint8List> fetchPhotoBytes({required String baseUrl, required String token, required int memoryId}) async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/personal-memories/$memoryId/photo'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 30));
    if (res.statusCode >= 400) {
      throw PersonalMemoryException('Не удалось загрузить фото (код ${res.statusCode}).');
    }
    return res.bodyBytes;
  }

  Future<void> delete({required String baseUrl, required String token, required int memoryId}) async {
    final res = await _client
        .delete(Uri.parse('$baseUrl/api/personal-memories/$memoryId'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw PersonalMemoryException('Не удалось удалить запись (код ${res.statusCode}).');
    }
  }

  void dispose() => _client.close();
}
