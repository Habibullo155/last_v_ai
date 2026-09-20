import 'package:ai_last_v/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config.dart';
import 'navigation.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/intro_video_screen.dart';
import 'screens/onboarding_survey_screen.dart';
import 'services/intro_video_service.dart';
import 'services/onboarding_survey_service.dart';
import 'state/auth_store.dart';
import 'state/chat_store.dart';
import 'state/locale_store.dart';
import 'state/notification_prefs_store.dart';
import 'state/performance_mode_store.dart';
import 'state/theme_store.dart';
import 'state/voice_store.dart';
import 'utils/responsive.dart';

// iOS/macOS - нативный переход слайдом справа налево и жест смахивания
// от левого края экрана назад, вместо стандартного Material-перехода
// (затухание/масштаб). Применяется автоматически ко ВСЕМ существующим
// Navigator.push(MaterialPageRoute(...)) по всему приложению - ни один
// экран менять не пришлось, MaterialPageRoute сам уважает эту настройку
// темы. Остальные платформы (Android, веб, десктоп) - поведение как было
const _platformAdaptiveTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  },
);

class GlassChatApp extends StatefulWidget {
  const GlassChatApp({super.key});

  @override
  State<GlassChatApp> createState() => _GlassChatAppState();
}

class _GlassChatAppState extends State<GlassChatApp> {
  final AuthStore _authStore = AuthStore();
  final ThemeStore _themeStore = ThemeStore.instance;
  final LocaleStore _localeStore = LocaleStore.instance;
  ChatStore? _chatStore;
  VoiceStore? _voiceStore;
  final _onboardingService = OnboardingSurveyService();
  final _introVideoService = IntroVideoService();
  // null - ещё проверяем; true - уже видел на этом устройстве, не
  // показываем; false - первый запуск, нужно показать
  bool? _hasSeenIntro;
  // null - ещё не проверено (или проверка идёт); true - нужно показать
  // опросник вместо основного экрана; false - не нужно (уже
  // пройден/пропущен раньше, или проверка не удалась - тогда просто не
  // мешаем человеку войти в приложение из-за сетевого сбоя)
  bool? _needsOnboardingSurvey;

  @override
  void initState() {
    super.initState();
    _authStore.addListener(_onAuthChanged);
    _authStore.restoreSession();
    _themeStore.addListener(_onThemeChanged);
    _themeStore.load();
    _localeStore.addListener(_onLocaleChanged);
    _localeStore.load();
    NotificationPrefsStore.instance.load();
    PerformanceModeStore.instance.load();
    _checkIntroVideoSeen();
  }

  Future<void> _checkIntroVideoSeen() async {
    final seen = await _introVideoService.hasSeenIntro();
    if (mounted) setState(() => _hasSeenIntro = seen);
  }

  void _onThemeChanged() => setState(() {});
  void _onLocaleChanged() => setState(() {});

  void _onAuthChanged() {
    if (_authStore.status == AuthStatus.authenticated) {
      final user = _authStore.user;
      if (user != null && _chatStore == null) {
        _setUpChatStoreFor(user.id.toString());
      }
      // токен мог обновиться (например, после silent-refresh или
      // повторного восстановления сессии) БЕЗ пересоздания всего
      // VoiceStore целиком - раньше он получал токен только один раз
      // при первом создании (см. _setUpChatStoreFor -
      // voice.init(..., authToken: ...)) и продолжал использовать
      // устаревшее значение до полного рестарта приложения, что
      // приводило к 401 у голосовых запросов после смены токена
      _voiceStore?.updateAuthToken(_authStore.token);
      if (_needsOnboardingSurvey == null) {
        _checkOnboardingSurveyStatus();
      }
    } else if (_authStore.status == AuthStatus.unauthenticated) {
      // Разлогинились — не тащим чужую сессию чата дальше.
      _chatStore?.dispose();
      _chatStore = null;
      _voiceStore?.dispose();
      _voiceStore = null;
      // при следующем входе (возможно, другим аккаунтом) проверяем заново
      _needsOnboardingSurvey = null;
    }
    setState(() {});
  }

  Future<void> _checkOnboardingSurveyStatus() async {
    final token = _authStore.token;
    if (token == null) return;
    // до 3 попыток с растущей паузой - раньше единственная неудача
    // (например, включённый на секунду авиарежим или просто плохая сеть
    // ровно в момент первого входа) НАВСЕГДА помечала опросник
    // "не нужен" - ни при каком последующем восстановлении сети
    // человек уже не увидел бы его снова, даже если бы хотел пройти
    for (final delaySeconds in [0, 2, 5]) {
      if (delaySeconds > 0) await Future.delayed(Duration(seconds: delaySeconds));
      if (!mounted) return;
      try {
        final status = await _onboardingService.getStatus(baseUrl: AppConfig.backendUrl, token: token);
        if (mounted) setState(() => _needsOnboardingSurvey = status == 'pending');
        return;
      } catch (_) {
        // пробуем ещё раз (если попытки остались) - см. цикл выше
      }
    }
    // все попытки исчерпаны - не блокируем вход в приложение из-за
    // этого, просто не покажем опросник в этот раз
    if (mounted) setState(() => _needsOnboardingSurvey = false);
  }

  void _setUpChatStoreFor(String userId) {
    final voice = VoiceStore();
    voice.init(AppConfig.backendUrl, authToken: _authStore.token);
    _voiceStore = voice;

    final store = ChatStore(
      getAuthToken: () => _authStore.token,
      onSessionExpired: _authStore.logout,
      onAssistantTextChunk: ({required messageId, required fullContent, required isDone}) {
        voice.onIncomingText(messageId: messageId, fullContent: fullContent, isDone: isDone);
      },
    );
    store.init(userId);
    _chatStore = store;
  }

  @override
  void dispose() {
    _authStore.removeListener(_onAuthChanged);
    _authStore.dispose();
    _themeStore.removeListener(_onThemeChanged);
    _localeStore.removeListener(_onLocaleChanged);
    _chatStore?.dispose();
    _voiceStore?.dispose();
    _onboardingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AI Glass Chat',
      debugShowCheckedModeBanner: false,
      // null (режим "system" в LocaleStore) - Flutter сам подхватывает
      // системный язык устройства, как было раньше всегда. Явный
      // Locale('ru')/Locale('en') - человек сам выбрал язык в настройках
      // (см. settings_screen.dart), игнорируя системный
      locale: _localeStore.resolvedLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
      ],
      themeMode: switch (_themeStore.mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF3F0FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.light,
        ),
        pageTransitionsTheme: _platformAdaptiveTransitions,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        pageTransitionsTheme: _platformAdaptiveTransitions,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    // интро-видео - самое первое, что видит человек, ещё до проверки
    // авторизации (один раз на устройстве, не зависит от аккаунта)
    if (_hasSeenIntro == null) return const _LoadingScreen();
    if (_hasSeenIntro == false) {
      return IntroVideoScreen(
        onDone: () {
          setState(() => _hasSeenIntro = true);
          _introVideoService.markIntroSeen();
        },
      );
    }
    switch (_authStore.status) {
      case AuthStatus.unknown:
      case AuthStatus.checking:
        return const _LoadingScreen();
      case AuthStatus.unauthenticated:
        return AuthScreen(store: _authStore);
      case AuthStatus.locked:
        return LockScreen(authStore: _authStore);
      case AuthStatus.authenticated:
        final chatStore = _chatStore;
        final voiceStore = _voiceStore;
        if (chatStore == null || voiceStore == null) return const _LoadingScreen();
        // опросник - ПОСЛЕ того, как chatStore/voiceStore готовы (не
        // блокирует их инициализацию), но ДО основного экрана - null
        // означает "ещё проверяем", тогда просто ждём (не мигаем
        // опросником на долю секунды, если он в итоге не нужен)
        if (_needsOnboardingSurvey == null) return const _LoadingScreen();
        if (_needsOnboardingSurvey == true) {
          return OnboardingSurveyScreen(
            authStore: _authStore,
            onDone: () => setState(() => _needsOnboardingSurvey = false),
          );
        }
        if (Responsive.isMobile(context)) {
          return MainShellScreen(
            store: chatStore,
            authStore: _authStore,
            themeStore: _themeStore,
            voiceStore: voiceStore,
          );
        }
        return ChatScreen(
          store: chatStore,
          authStore: _authStore,
          themeStore: _themeStore,
          voiceStore: voiceStore,
        );
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0B0F1E),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
      ),
    );
  }
}
