import 'package:ai_last_v/l10n/app_localizations.dart';
import 'package:flutter/material.dart';



/// Даёт доступ к текущему BuildContext из мест, где его нет напрямую -
/// в первую очередь из ChangeNotifier-хранилищ (AuthStore и т.п.),
/// которым иногда нужно локализовать сообщение об ошибке, но которые не
/// являются виджетами и не могут принять BuildContext как параметр
/// каждого метода без масштабной переделки сигнатур во всех вызывающих
/// экранах. Подключается в MaterialApp(navigatorKey: navigatorKey, ...)
/// в app.dart.
final navigatorKey = GlobalKey<NavigatorState>();

/// null только в исключительном случае, если ещё ни один экран не
/// отрисовался (практически не бывает к моменту, когда вообще возможно
/// действие, требующее локализованной ошибки - для этого уже нужен
/// отрисованный экран, с которого человек его вызвал).
AppLocalizations? currentL10n() {
  final context = navigatorKey.currentContext;
  if (context == null) return null;
  return AppLocalizations.of(context);
}
