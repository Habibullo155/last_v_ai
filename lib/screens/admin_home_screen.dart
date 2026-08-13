import 'package:flutter/material.dart';

import '../state/auth_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';
import 'admin_documents_screen.dart';
import 'admin_support_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final AuthStore authStore;
  const AdminHomeScreen({super.key, required this.authStore});

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
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _AdminTile(
                          icon: Icons.people_alt_rounded,
                          title: 'Пользователи',
                          subtitle: 'Активность, тарифы, срок подписки, роли',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AdminUsersScreen(authStore: authStore)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AdminTile(
                          icon: Icons.menu_book_rounded,
                          title: 'Обучение на документах',
                          subtitle: 'RAG: загрузка PDF, автоматическая разбивка на разделы',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AdminDocumentsScreen(authStore: authStore)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AdminTile(
                          icon: Icons.support_agent_rounded,
                          title: 'Обращения пользователей',
                          subtitle: 'Все тикеты службы поддержки',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AdminSupportScreen(authStore: authStore)),
                          ),
                        ),
                      ],
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
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
                Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
