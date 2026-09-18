import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../navigation.dart';

/// Ежедневное напоминание в момент, когда пользователь обычно дома —
/// НЕ живая генерация текста ИИ в момент срабатывания: у нас нет
/// серверной push-инфраструктуры (FCM/APNs с бэкендом), а фоновое
/// выполнение на iOS/Android слишком ограничено, чтобы надёжно успеть
/// обратиться к Ollama прямо в момент показа уведомления. Вместо этого —
/// заранее заданный, но разнообразный набор фраз, меняющийся по дням, а
/// не один и тот же текст каждый раз.
class ReminderService {
  static const _enabledKey = 'daily_reminder_enabled_v1';
  static const _hourKey = 'daily_reminder_hour_v1';
  static const _minuteKey = 'daily_reminder_minute_v1';
  static const _notificationId = 7001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  List<String> get _prompts {
    final l10n = currentL10n();
    return [
      l10n?.reminderPrompt1 ??
          'Как прошёл день? Если хочется поговорить — я здесь.',
      l10n?.reminderPrompt2 ?? 'Небольшая пауза — как ты сейчас, в целом?',
      l10n?.reminderPrompt3 ??
          'Если накопилось что-то, о чём хочется рассказать — самое время.',
      l10n?.reminderPrompt4 ??
          'Как настроение сегодня? Загляни, если нужно выговориться.',
      l10n?.reminderPrompt5 ??
          'Просто напоминаю, что можно зайти и поделиться, как прошёл день.',
      l10n?.reminderPrompt6 ??
          'Если весь день был плотным — пара минут на выдох тебе не помешает.',
      l10n?.reminderPrompt7 ??
          'Иногда полезно просто проговорить мысли вслух. Я слушаю.',
      l10n?.reminderPrompt8 ??
          'Как твоё тело сегодня — не зажаты плечи, не сжаты кулаки?',
      l10n?.reminderPrompt9 ??
          'Если тревожно — попробуй короткое дыхательное упражнение, оно есть в разделе Забота.',
      l10n?.reminderPrompt10 ??
          'Перед сном иногда помогает музыка для сна — загляни, если сложно расслабиться.',
      l10n?.reminderPrompt11 ??
          'Мышцы часто напрягаются незаметно за день. Есть упражнение, которое помогает их отпустить.',
      l10n?.reminderPrompt12 ??
          'Было сегодня что-то, что хочется сохранить? Можно оставить фото с мыслью в разделе Мои моменты.',
      l10n?.reminderPrompt13 ??
          'Не обязательно ждать, пока станет тяжело — можно просто заглянуть и рассказать, как дела.',
      l10n?.reminderPrompt14 ?? 'Ты сегодня успел(а) выдохнуть хоть на минуту?',
      l10n?.reminderPrompt15 ??
          'Если день был непростым — не нужно объяснять сразу всё. Начни с чего угодно.',
      l10n?.reminderPrompt16 ??
          'Иногда важно просто отметить: этот день был. Как он прошёл для тебя?',
      l10n?.reminderPrompt17 ??
          'Здесь не нужно готовиться к разговору — можно просто написать первое, что приходит в голову.',
      l10n?.reminderPrompt18 ??
          'Если сегодня было что-то хорошее — поделись, приятно порадоваться вместе.',
      l10n?.reminderPrompt19 ??
          'Забота о себе — это не всегда большие шаги. Иногда достаточно пары минут на паузу.',
      l10n?.reminderPrompt20 ??
          'Как ты сейчас — физически и внутри? Необязательно отвечать развёрнуто.',
    ];
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );
    _initialized = true;
  }

  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Час/минута в 24-часовом формате — по умолчанию 19:00, разумное
  /// "обычно уже дома" время, если пользователь ещё не настраивал своё.
  Future<(int, int)> getTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt(_hourKey) ?? 19;
      final minute = prefs.getInt(_minuteKey) ?? 0;
      return (hour, minute);
    } catch (_) {
      return (19, 0);
    }
  }

  /// Запрашивает разрешение на уведомления (обязательно на Android 13+ и
  /// iOS) и, если получено, планирует ежедневное напоминание на указанное
  /// время. Возвращает false, если разрешение не дали — тогда включать
  /// переключатель в настройках не имеет смысла.
  Future<bool> enable({required int hour, required int minute}) async {
    await _ensureInitialized();

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool granted = true;
    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission() ?? false;
    }
    if (iosPlugin != null) {
      granted =
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (!granted) return false;

    await _scheduleDaily(hour: hour, minute: minute);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, true);
      await prefs.setInt(_hourKey, hour);
      await prefs.setInt(_minuteKey, minute);
    } catch (_) {
      // настройка сохранится некорректно, но само уведомление уже
      // запланировано — не критично для этого разового случая
    }
    return true;
  }

  Future<void> disable() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _notificationId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, false);
    } catch (_) {}
  }

  Future<void> _scheduleDaily({required int hour, required int minute}) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // разная фраза для разных дней года - не один и тот же текст каждый
    // раз, но и не выдуманная "генерация налету"
    final prompt = _prompts[now.day % _prompts.length];

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'LOMALU',
      body: prompt,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          currentL10n()?.reminderChannelName ?? 'Ежедневные напоминания',
          channelDescription:
              currentL10n()?.reminderChannelDescription ??
              'Напоминание проверить, как дела, в выбранное время',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation убран из API начиная с
      // 19.0.0 (см. pubspec.yaml — пакет теперь на ^22.3.0) — параметр
      // был нужен только для iOS < 10, которые эта версия пакета уже не
      // поддерживает, так что просто не передаём его вообще.
      matchDateTimeComponents:
          DateTimeComponents.time, // повтор каждый день в это время
    );
  }
}
