import 'package:ai_last_v/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config.dart';

import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/main_shell_screen.dart';
import 'state/auth_store.dart';
import 'state/chat_store.dart';
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
  ChatStore? _chatStore;
  VoiceStore? _voiceStore;

  @override
  void initState() {
    super.initState();
    _authStore.addListener(_onAuthChanged);
    _authStore.restoreSession();
    _themeStore.addListener(_onThemeChanged);
    _themeStore.load();
    NotificationPrefsStore.instance.load();
    PerformanceModeStore.instance.load();
  }

  void _onThemeChanged() => setState(() {});

  void _onAuthChanged() {
    if (_authStore.status == AuthStatus.authenticated) {
      final user = _authStore.user;
      if (user != null && _chatStore == null) {
        _setUpChatStoreFor(user.id.toString());
      }
    } else if (_authStore.status == AuthStatus.unauthenticated) {
      // Разлогинились — не тащим чужую сессию чата дальше.
      _chatStore?.dispose();
      _chatStore = null;
      _voiceStore?.dispose();
      _voiceStore = null;
    }
    setState(() {});
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
    _chatStore?.dispose();
    _voiceStore?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Glass Chat',
      debugShowCheckedModeBanner: false,
      // locale: намеренно не задаём - без явного значения Flutter сам
      // подхватывает системный язык устройства из списка supportedLocales
      // ниже (если системный язык не в списке - берёт первый, русский)
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
