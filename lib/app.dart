import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'state/auth_store.dart';
import 'state/chat_store.dart';

class GlassChatApp extends StatefulWidget {
  const GlassChatApp({super.key});

  @override
  State<GlassChatApp> createState() => _GlassChatAppState();
}

class _GlassChatAppState extends State<GlassChatApp> {
  final AuthStore _authStore = AuthStore();
  ChatStore? _chatStore;

  @override
  void initState() {
    super.initState();
    _authStore.addListener(_onAuthChanged);
    _authStore.restoreSession();
  }

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
  }

  @override
  void dispose() {
    _authStore.removeListener(_onAuthChanged);
    _authStore.dispose();
    _chatStore?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Glass Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto', // В главном конструкторе это работает без ошибок
        scaffoldBackgroundColor: const Color(0xFF0B0F1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness:
              Brightness.dark, // Автоматически генерирует темную палитру
        ),
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
        if (chatStore == null) return const _LoadingScreen();
        return ChatScreen(store: chatStore, authStore: _authStore);
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
