import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../state/auth_store.dart';
import '../utils/auth_navigation.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

class ProfileScreen extends StatefulWidget {
  final AuthStore authStore;
  const ProfileScreen({super.key, required this.authStore});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _isUploadingAvatar = false;

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A2036),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.photo_camera_rounded, color: Colors.white),
                title: const Text('Сделать фото',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: Colors.white),
                title: const Text('Выбрать из галереи',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              if (widget.authStore.user?.avatarBase64 != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFFF6B6B)),
                  title: const Text('Удалить фото',
                      style: TextStyle(color: Color(0xFFFF6B6B))),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      await _uploadAvatar(source);
    }
  }

  Future<void> _uploadAvatar(ImageSource source) async {
    // квадратный кроп + сжатие сразу при выборе - тот же приём, что и у
    // фото в чате (chat_input_bar.dart), маленький аватар не должен
    // раздувать профиль на сервере
    final file = await _picker.pickImage(
        source: source, maxWidth: 512, maxHeight: 512, imageQuality: 75);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _isUploadingAvatar = true);
    final error =
        await widget.authStore.updateProfile(avatarBase64: base64Encode(bytes));
    if (mounted) {
      setState(() => _isUploadingAvatar = false);
      if (error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _isUploadingAvatar = true);
    final error = await widget.authStore.updateProfile(clearAvatar: true);
    if (mounted) {
      setState(() => _isUploadingAvatar = false);
      if (error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
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
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Личный кабинет',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      // Слушаем authStore напрямую — после сохранения
                      // профиля в диалоге редактирования user меняется
                      // и экран должен сразу показать новые значения, а
                      // не только после повторного открытия.
                      child: AnimatedBuilder(
                        animation: widget.authStore,
                        builder: (context, _) {
                          final user = widget.authStore.user;
                          return user == null
                              ? const Text('Нет данных',
                                  style: TextStyle(color: Colors.white))
                              : _buildContent(context, user);
                        },
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

  Widget _buildContent(BuildContext context, AppUser user) {
    return GlassPanel(
      opacity: 0.10,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: _isUploadingAvatar ? null : _pickAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF00D9C0)]),
                      image: user.avatarBase64 != null
                          ? DecorationImage(
                              image:
                                  MemoryImage(base64Decode(user.avatarBase64!)),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: _isUploadingAvatar
                        ? const CircularProgressIndicator(color: Colors.white)
                        : user.avatarBase64 == null
                            ? Text(
                                (user.fullName?.isNotEmpty == true
                                        ? user.fullName![0]
                                        : user.email[0])
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700),
                              )
                            : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6C5CE7),
                        border: Border.all(
                            color: const Color(0xFF1A2036), width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (user.avatarBase64 != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isUploadingAvatar ? null : _removeAvatar,
                child: Text('Удалить фото',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _row(
              'ФИО',
              user.fullName?.isNotEmpty == true
                  ? user.fullName!
                  : 'не указано'),
          _divider(),
          _row('Возраст', user.age != null ? '${user.age}' : 'не указано'),
          _divider(),
          _row('Хобби',
              user.hobbies?.isNotEmpty == true ? user.hobbies! : 'не указано'),
          _divider(),
          _row('Email', user.email),
          _divider(),
          _row('Тариф', user.tariff, badge: true),
          _divider(),
          _row('Роль', user.isAdmin ? 'Администратор' : 'Пользователь'),
          _divider(),
          _row('Аккаунт создан', DateFormat.yMMMd().format(user.createdAt)),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showEditDialog(context, user),
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)]),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Редактировать профиль',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LogoutButton(
              onTap: () => confirmAndLogout(context, widget.authStore)),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, AppUser user) async {
    await showDialog(
      context: context,
      builder: (context) =>
          _EditProfileDialog(authStore: widget.authStore, user: user),
    );
  }

  Widget _divider() =>
      Divider(color: Colors.white.withOpacity(0.08), height: 28);

  Widget _row(String label, String value, {bool badge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.55), fontSize: 13.5)),
        if (badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)]),
            ),
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
            ),
          )
        else
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final AuthStore authStore;
  final AppUser user;
  const _EditProfileDialog({required this.authStore, required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _hobbiesController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName ?? '');
    _ageController =
        TextEditingController(text: widget.user.age?.toString() ?? '');
    _hobbiesController = TextEditingController(text: widget.user.hobbies ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ageText = _ageController.text.trim();
    int? age;
    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);
      if (age == null || age < 1 || age > 120) {
        setState(() => _error = 'Возраст должен быть числом от 1 до 120.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final name = _nameController.text.trim();
    final hobbies = _hobbiesController.text.trim();

    final error = await widget.authStore.updateProfile(
      fullName: name.isNotEmpty ? name : null,
      clearFullName: name.isEmpty,
      age: age,
      clearAge: ageText.isEmpty,
      hobbies: hobbies.isNotEmpty ? hobbies : null,
      clearHobbies: hobbies.isEmpty,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isSaving = false;
        _error = error;
      });
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassPanel(
        opacity: 0.18,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Редактировать профиль',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Все поля необязательны — оставь пустым, чтобы очистить.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildField(_nameController, 'ФИО', TextInputType.name),
              const SizedBox(height: 10),
              _buildField(_ageController, 'Возраст', TextInputType.number),
              const SizedBox(height: 10),
              _buildField(_hobbiesController, 'Хобби', TextInputType.text,
                  maxLines: 3),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(
                        color: Color(0xFFFFB4B4), fontSize: 12.5)),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('Отмена',
                        style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7)),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller, String label, TextInputType type,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final Future<void> Function() onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded,
                  size: 18, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 8),
              Text('Выйти',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
