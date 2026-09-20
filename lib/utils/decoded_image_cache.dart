import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;

import 'lru_cache.dart';

/// Общий на всё приложение кэш декодированных base64-изображений -
/// раньше base64Decode(...) вызывался синхронно прямо внутри build()
/// в нескольких местах (аватар в ProfileScreen, обложка поста в
/// BlogPostScreen, вложения в message_bubble.dart) - на каждую
/// перестройку виджета, не только один раз. Для мегабайтных вложений
/// это заметно подвешивает интерфейс (декодирование - тяжёлая,
/// синхронная CPU-операция), а на скролле списков с несколькими такими
/// изображениями сразу - настоящий scroll jank.
///
/// Ограничен по размеру (LruCache) - без этого лента из многих
/// изображений постепенно съела бы всю доступную память, вместо того
/// чтобы вытеснять давно не использованные записи.
final decodedImageCache = LruCache<String, Uint8List>(maxEntries: 40);

/// Декодирует base64Image в отдельном изоляте (compute()), не блокируя
/// UI-поток, и кэширует результат - повторный вызов с тем же base64Image
/// вернёт уже готовый Uint8List без повторного decode вообще.
Future<Uint8List> decodeImageCached(String base64Image) async {
  final cached = decodedImageCache.get(base64Image);
  if (cached != null) return cached;
  final bytes = await compute(base64Decode, base64Image);
  decodedImageCache.put(base64Image, bytes);
  return bytes;
}
