/// Запускает [action] для каждого элемента [items], но не более
/// [concurrency] штук одновременно - раньше списки Сейфа/Блога грузили
/// превью для ВСЕХ элементов страницы сразу, через цикл for с .then()
/// без какого-либо ограничения: десятки/сотни одновременных HTTP-
/// запросов от одного клиента разом. Это и лишняя нагрузка на сервер, и
/// риск упереться в лимит одновременных соединений платформы/браузера
/// (там где он есть, скрывает часть запросов в невидимую очередь; там
/// где лимита нет - просто заливает сеть клиента разом).
///
/// N "воркеров" разбирают общую очередь по одному элементу - как
/// только воркер освобождается, он берёт следующий элемент, пока
/// очередь не опустеет. Одна упавшая задача не останавливает
/// остальные и не всплывает наверх - обработку ошибок каждая задача
/// делает сама (см. использование в personal_memories_screen.dart/
/// blog_list_screen.dart - там на месте try/catch внутри `action`).
Future<void> runWithConcurrencyLimit<T>(
  List<T> items,
  int concurrency,
  Future<void> Function(T item) action,
) async {
  if (items.isEmpty) return;
  final queue = List<T>.from(items);

  Future<void> worker() async {
    while (queue.isNotEmpty) {
      final item = queue.removeAt(0);
      await action(item);
    }
  }

  final workerCount = concurrency < items.length ? concurrency : items.length;
  await Future.wait(List.generate(workerCount, (_) => worker()));
}
