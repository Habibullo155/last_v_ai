/// Заглушка для веба - dart:io там не существует вообще (не просто
/// "не работает в рантайме", компилятор физически не может его найти
/// при сборке под веб). conditional import в sleep_music_screen.dart
/// подставляет этот файл вместо dart:io именно на вебе - функция
/// "выбрать папку целиком" там и так скрыта в UI (getDirectoryPath не
/// поддерживается на вебе, см. sleep_music_screen.dart), поэтому классы
/// здесь никогда реально не вызываются на вебе - нужны только чтобы
/// компилятор нашёл сами имена типов и не упал на этапе анализа кода.
library;

class Directory {
  Directory(String path);
  List<FileSystemEntityStub> listSync() => const [];
}

class File extends FileSystemEntityStub {
  File(this.path);
  @override
  final String path;
}

abstract class FileSystemEntityStub {
  String get path => '';
}

class Platform {
  static String get pathSeparator => '/';
}
