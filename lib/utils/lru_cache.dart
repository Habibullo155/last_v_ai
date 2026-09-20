/// Кэш с ограничением размера и вытеснением по давности использования
/// (LRU - Least Recently Used). Раньше словари вроде _photoCache/
/// _coverCache/_webSessionBytes копили Uint8List загруженных
/// фото/музыки/вложений НАВСЕГДА, без какого-либо механизма вытеснения -
/// при просмотре длинной ленты постов/записей приложение гарантированно
/// упало бы от нехватки памяти (OOM), поскольку каждое новое фото просто
/// добавлялось в словарь, а старые никогда не удалялись.
///
/// LinkedHashMap под капотом сохраняет порядок вставки/доступа - при
/// каждом обращении к ключу через [get] он переставляется в конец
/// (значит только что использованный), а при превышении [maxEntries]
/// удаляется самый ДАВНО не использовавшийся элемент (первый в
/// LinkedHashMap) - не просто "случайный" или "первый добавленный".
class LruCache<K, V> {
  final int maxEntries;
  final _map = <K, V>{};

  LruCache({required this.maxEntries}) : assert(maxEntries > 0);

  V? get(K key) {
    final value = _map.remove(key);
    if (value == null) return null;
    _map[key] = value; // переставляем в конец - "недавно использован"
    return value;
  }

  bool containsKey(K key) => _map.containsKey(key);

  void put(K key, V value) {
    _map.remove(key); // на случай, если ключ уже был - переставить в конец
    _map[key] = value;
    while (_map.length > maxEntries) {
      _map.remove(_map.keys.first); // самый давно не используемый
    }
  }

  void remove(K key) => _map.remove(key);

  void clear() => _map.clear();

  int get length => _map.length;
}
