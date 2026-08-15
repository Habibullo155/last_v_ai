import 'package:flutter/material.dart';

import '../state/auth_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

class AuthScreen extends StatefulWidget {
  final AuthStore store;
  const AuthScreen({super.key, required this.store});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    if (_isRegisterMode && password.length < 8) return;

    final ok = _isRegisterMode
        ? await widget.store.register(email, password)
        : await widget.store.login(email, password);

    if (ok && mounted) {
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AnimatedBuilder(
                  animation: widget.store,
                  builder: (context, _) => _buildForm(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final store = widget.store;

    return GlassPanel(
      opacity: 0.12,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF00D9C0)],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 20),
          Text(
            _isRegisterMode ? 'Создать аккаунт' : 'Вход в AI Chat',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _buildField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _passwordController,
            hint: 'Пароль',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            onChanged: _isRegisterMode ? (_) => setState(() {}) : null,
            onSubmitted: (_) => store.isBusy ? null : _submit(),
          ),
          if (_isRegisterMode) ...[
            const SizedBox(height: 8),
            _buildPasswordHint(),
          ],
          if (store.lastError != null) ...[
            const SizedBox(height: 14),
            Text(
              store.lastError!,
              style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          _SubmitButton(
            isBusy: store.isBusy,
            label: _isRegisterMode ? 'Зарегистрироваться' : 'Войти',
            onTap: _submit,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
              child: Text(
                _isRegisterMode
                    ? 'Уже есть аккаунт? Войти'
                    : 'Нет аккаунта? Зарегистрироваться',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// Живая подсказка про минимальную длину пароля (8 символов — то же
  /// правило, что и на сервере, schemas.py:UserRegister). Без этого
  /// единственная обратная связь была — ошибка сервера уже ПОСЛЕ отправки
  /// формы, что неудобно и непонятно на этапе ввода.
  Widget _buildPasswordHint() {
    final length = _passwordController.text.length;
    const minLength = 8;
    final isValid = length >= minLength;
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 14,
          color: isValid ? const Color(0xFF00E6A0) : Colors.white.withOpacity(0.35),
        ),
        const SizedBox(width: 6),
        Text(
          isValid ? 'Длина пароля подходит' : 'Минимум $minLength символов (введено: $length)',
          style: TextStyle(
            color: isValid ? const Color(0xFF00E6A0) : Colors.white.withOpacity(0.45),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isBusy;
  final String label;
  final VoidCallback onTap;
  const _SubmitButton({required this.isBusy, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isBusy ? null : onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isBusy
                  ? [Colors.white24, Colors.white10]
                  : [const Color(0xFF6C5CE7), const Color(0xFF00B4D8)],
            ),
          ),
          child: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                ),
        ),
      ),
    );
  }
}
