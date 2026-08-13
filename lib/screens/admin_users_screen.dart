import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/admin_user.dart';
import '../services/admin_users_service.dart';
import '../state/auth_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

class AdminUsersScreen extends StatefulWidget {
  final AuthStore authStore;
  const AdminUsersScreen({super.key, required this.authStore});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _service = AdminUsersService();
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _service.listUsers(baseUrl: widget.authStore.baseUrl, token: token);
      if (!mounted) return;
      setState(() => _users = users);
    } on AdminUsersException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AdminUser> get _filtered {
    if (_search.trim().isEmpty) return _users;
    final q = _search.trim().toLowerCase();
    return _users.where((u) => u.email.toLowerCase().contains(q)).toList();
  }

  int get _onlineCount => _users.where((u) => u.isOnlineNow).length;

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
                    const Expanded(
                      child: Text(
                        'Пользователи',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSummary(),
                          const SizedBox(height: 12),
                          _buildSearch(),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4))),
                          ],
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
                            )
                          else if (_filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text('Никого не найдено', style: TextStyle(color: Colors.white.withOpacity(0.4))),
                              ),
                            )
                          else
                            ..._filtered.map(_buildUserTile),
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

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: GlassPanel(
            opacity: 0.08,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_users.length}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                Text('всего', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassPanel(
            opacity: 0.08,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6, bottom: 2),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E6A0)),
                    ),
                    Text('$_onlineCount', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  ],
                ),
                Text('в сети сейчас', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (v) => setState(() => _search = v),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.4)),
        hintText: 'Поиск по email…',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildUserTile(AdminUser user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        opacity: 0.07,
        blurred: false, // список из многих пользователей — см. message_bubble.dart
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showEditSheet(user),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: user.isOnlineNow ? const Color(0xFF00E6A0) : Colors.white24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.email,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                              ),
                            ),
                            if (user.isAdmin) ...[
                              const SizedBox(width: 6),
                              _badge('admin', const Color(0xFF6C5CE7)),
                            ],
                            if (!user.isActive) ...[
                              const SizedBox(width: 6),
                              _badge('деактивирован', const Color(0xFFFF6B6B)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitleFor(user),
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _badge(user.tariff, const Color(0xFF00B4D8)),
                      const SizedBox(height: 4),
                      Text(
                        _expiryLabel(user),
                        style: TextStyle(
                          color: user.isTariffExpired ? const Color(0xFFFFB4B4) : Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitleFor(AdminUser user) {
    if (user.isOnlineNow) return 'В сети сейчас';
    if (user.lastActiveAt == null) return 'Ещё не заходил(а)';
    return 'Был(а) в сети ${DateFormat.yMMMd().add_Hm().format(user.lastActiveAt!)}';
  }

  String _expiryLabel(AdminUser user) {
    final days = user.daysUntilExpiry;
    if (days == null) return 'бессрочно';
    if (days < 0) return 'истёк ${-days} дн. назад';
    if (days == 0) return 'истекает сегодня';
    return 'осталось $days дн.';
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withOpacity(0.18)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _showEditSheet(AdminUser user) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditUserSheet(
        user: user,
        authStore: widget.authStore,
        service: _service,
        onChanged: (updated) {
          setState(() {
            final idx = _users.indexWhere((u) => u.id == updated.id);
            if (idx != -1) _users[idx] = updated;
          });
        },
      ),
    );
  }
}

class _EditUserSheet extends StatefulWidget {
  final AdminUser user;
  final AuthStore authStore;
  final AdminUsersService service;
  final ValueChanged<AdminUser> onChanged;

  const _EditUserSheet({
    required this.user,
    required this.authStore,
    required this.service,
    required this.onChanged,
  });

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  late final TextEditingController _tariffController;
  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tariffController = TextEditingController(text: widget.user.tariff);
  }

  @override
  void dispose() {
    _tariffController.dispose();
    super.dispose();
  }

  Future<void> _apply({
    String? tariff,
    String? role,
    bool? isActive,
    int? tariffDays,
    bool? clearTariffExpiry,
  }) async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final updated = await widget.service.updateUser(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        userId: widget.user.id,
        tariff: tariff,
        role: role,
        isActive: isActive,
        tariffDays: tariffDays,
        clearTariffExpiry: clearTariffExpiry,
      );
      widget.onChanged(updated);
      if (mounted) Navigator.of(context).pop();
    } on AdminUsersException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassPanel(
        opacity: 0.18,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              Text('ТАРИФ', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tariffController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        hintText: 'free / pro / unlimited',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isBusy ? null : () => _apply(tariff: _tariffController.text.trim()),
                    child: const Text('Сохранить'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text('СРОК ПОДПИСКИ', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final days in [7, 30, 90, 365])
                    OutlinedButton(
                      onPressed: _isBusy ? null : () => _apply(tariffDays: days),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.16)),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('+$days дн.'),
                    ),
                  OutlinedButton(
                    onPressed: _isBusy ? null : () => _apply(clearTariffExpiry: true),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.16)),
                      foregroundColor: Colors.white70,
                    ),
                    child: const Text('Сделать бессрочным'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text('РОЛЬ И ДОСТУП', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isBusy ? null : () => _apply(role: user.isAdmin ? 'user' : 'admin'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.16)),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(user.isAdmin ? 'Снять права админа' : 'Сделать админом'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isBusy ? null : () => _apply(isActive: !user.isActive),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: (user.isActive ? const Color(0xFFFF6B6B) : const Color(0xFF00E6A0)).withOpacity(0.4)),
                        foregroundColor: user.isActive ? const Color(0xFFFFB4B4) : const Color(0xFF00E6A0),
                      ),
                      child: Text(user.isActive ? 'Деактивировать' : 'Активировать'),
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
              ],
              if (_isBusy) ...[
                const SizedBox(height: 14),
                const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
