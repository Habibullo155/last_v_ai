import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/main_shell_screen.dart';
import 'state/auth_store.dart';
import 'state/chat_store.dart';
import 'state/theme_store.dart';
import 'state/voice_store.dart';
import 'utils/responsive.dart';

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
    final store = ChatStore(
      getAuthToken: () => _authStore.token,
      onSessionExpired: _authStore.logout,
    );
    store.init(userId);
    _chatStore = store;

    final voice = VoiceStore();
    voice.init(store.baseUrl, authToken: _authStore.token);
    _voiceStore = voice;
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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
          // Optional: Override background directly in the scheme
          surface: const Color(0xFF0B0F1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0F1E),
        fontFamily: 'Roboto',
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
      case AuthStatus.authenticated:
        final chatStore = _chatStore;
        final voiceStore = _voiceStore;
        if (chatStore == null || voiceStore == null)
          return const _LoadingScreen();
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
