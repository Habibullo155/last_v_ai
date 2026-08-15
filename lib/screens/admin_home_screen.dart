import 'package:flutter/material.dart';

import '../models/dashboard_stats.dart';
import '../services/app_settings_service.dart';
import '../services/stats_service.dart';
import '../state/auth_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';
import 'admin_documents_screen.dart';
import 'admin_pronunciation_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_support_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final AuthStore authStore;
  const AdminHomeScreen({super.key, required this.authStore});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _service = StatsService();
  final _appSettingsService = AppSettingsService();
  DashboardStats? _stats;
  bool _isLoading = true;
  bool _voiceEnabled = true;
  bool _isTogglingVoice = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    _appSettingsService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final stats = await _service.getDashboardStats(baseUrl: widget.authStore.baseUrl, token: token);
      if (!mounted) return;
      setState(() => _stats = stats);
    } on StatsException {
      // Тихо оставляем предыдущие цифры (или пусто) — это дашборд, а не
      // критичная функция; плитки навигации ниже работают в любом случае.
    }
    final voiceEnabled = await _appSettingsService.isVoiceEnabled(widget.authStore.baseUrl);
    if (mounted) {
      setState(() {
        _voiceEnabled = voiceEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleVoice(bool value) async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() => _isTogglingVoice = true);
    try {
      final updated = await _appSettingsService.setVoiceEnabled(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        enabled: value,
      );
      if (mounted) setState(() => _voiceEnabled = updated);
    } on AppSettingsException {
      // Не удалось — просто оставляем переключатель в прежнем положении.
    } finally {
      if (mounted) setState(() => _isTogglingVoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Админ-панель',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildStatsGrid(),
                          const SizedBox(height: 20),
                          _buildVoiceToggle(),
                          const SizedBox(height: 20),
                          _AdminTile(
                            icon: Icons.people_alt_rounded,
                            title: 'Пользователи',
                            subtitle: 'Активность, тарифы, срок подписки, роли',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => AdminUsersScreen(authStore: widget.authStore)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _AdminTile(
                            icon: Icons.flag_rounded,
                            title: 'Жалобы на ответы ИИ',
                            subtitle: 'Разбор конкретных проблемных ответов модели',
                            badgeCount: _stats?.reportsOpen,
                            onTap: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(builder: (_) => AdminReportsScreen(authStore: widget.authStore)),
                                )
                                .then((_) => _load()),
                          ),
                          const SizedBox(height: 12),
                          _AdminTile(
                            icon: Icons.menu_book_rounded,
                            title: 'Обучение на документах',
                            subtitle: 'RAG: загрузка PDF, автоматическая разбивка на разделы',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => AdminDocumentsScreen(authStore: widget.authStore)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _AdminTile(
                            icon: Icons.support_agent_rounded,
                            title: 'Обращения пользователей',
                            subtitle: 'Все тикеты службы поддержки',
                            badgeCount: _stats?.ticketsOpen,
                            onTap: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(builder: (_) => AdminSupportScreen(authStore: widget.authStore)),
                                )
                                .then((_) => _load()),
                          ),
                          const SizedBox(height: 12),
                          _AdminTile(
                            icon: Icons.spellcheck_rounded,
                            title: 'Словарь произношения',
                            subtitle: 'Как озвучка должна "читать" конкретные слова — для всех пользователей',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => AdminPronunciationScreen(authStore: widget.authStore)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceToggle() {
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(
            _voiceEnabled ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
            color: Colors.white70,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Голосовые функции для всех пользователей', style: TextStyle(color: Colors.white, fontSize: 13.5)),
          ),
          if (_isTogglingVoice)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C5CE7)),
            )
          else
            Switch(
              value: _voiceEnabled,
              activeColor: const Color(0xFF6C5CE7),
              onChanged: _toggleVoice,
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _stats;
    if (_isLoading && stats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
      );
    }
    if (stats == null) return const SizedBox.shrink();

    final items = [
      (stats.usersTotal.toString(), 'пользователей'),
      (stats.usersOnlineNow.toString(), 'онлайн сейчас'),
      (stats.ticketsOpen.toString(), 'открытых тикетов'),
      (stats.reportsOpen.toString(), 'открытых жалоб'),
      (stats.documentsTotal.toString(), 'документов RAG'),
      (_formatTokens(stats.tokensUsedThisMonth), 'токенов в этом месяце'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: items
          .map((item) => GlassPanel(
                opacity: 0.08,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.$1, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(item.$2, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11.5)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) return '${(tokens / 1000000).toStringAsFixed(1)}M';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(1)}k';
    return tokens.toString();
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? badgeCount;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00D9C0)]),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12.5)),
                    ],
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFFFD166).withOpacity(0.2),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(color: Color(0xFFFFD166), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
