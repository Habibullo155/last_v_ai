import 'package:flutter/material.dart';

import '../models/onboarding_survey.dart';
import '../services/onboarding_survey_service.dart';
import '../state/auth_store.dart';
import '../theme/app_text_color.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

/// Опросник сразу после первой регистрации — можно пройти или пропустить
/// на любом шаге. Ответы НИКОГДА не показываются здесь же как "результат"
/// или диагноз (см. комментарий в models/onboarding_survey.dart) — просто
/// сохраняются на сервере и становятся фоновым контекстом для ИИ в первом
/// разговоре, без какого-либо вывода прямо в этом экране.
class OnboardingSurveyScreen extends StatefulWidget {
  final AuthStore authStore;
  // вызывается и при завершении, и при пропуске - app.dart реагирует
  // одинаково в обоих случаях, переходя на основной экран
  final VoidCallback onDone;
  const OnboardingSurveyScreen({super.key, required this.authStore, required this.onDone});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  final _service = OnboardingSurveyService();
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final token = widget.authStore.token;
    if (token != null) {
      try {
        await _service.skip(baseUrl: widget.authStore.baseUrl, token: token);
      } on OnboardingSurveyException catch (_) {
        // не критично - опросник просто останется "pending" и предложится
        // снова при следующем входе, ничего не ломается
      } catch (_) {
        // сетевой сбой - та же логика, молча продолжаем в приложение
      }
    }
    if (mounted) widget.onDone();
  }

  Future<void> _selectAnswer(String option) async {
    setState(() => _answers[_currentIndex] = option);
    final isLastQuestion = _currentIndex == onboardingQuestions.length - 1;
    if (!isLastQuestion) {
      setState(() => _currentIndex++);
      return;
    }
    // последний вопрос отвечен - завершаем и сохраняем всё разом
    setState(() => _isSubmitting = true);
    final token = widget.authStore.token;
    if (token == null) {
      if (mounted) widget.onDone();
      return;
    }
    final answersOut = <String, String>{
      for (final entry in _answers.entries) onboardingQuestions[entry.key].text: entry.value,
    };
    try {
      await _service.complete(baseUrl: widget.authStore.baseUrl, token: token, answers: answersOut);
      if (mounted) widget.onDone();
    } on OnboardingSurveyException catch (e) {
      if (mounted) setState(() { _isSubmitting = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _isSubmitting = false; _error = 'Не удалось сохранить ответы — проверь соединение с сервером.'; });
    }
  }

  void _goBack() {
    if (_currentIndex == 0) return;
    setState(() => _currentIndex--);
  }

  @override
  Widget build(BuildContext context) {
    final question = onboardingQuestions[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (_currentIndex > 0)
                      IconButton(
                        icon: Icon(Icons.arrow_back_rounded, color: context.onSurface),
                        onPressed: _isSubmitting ? null : _goBack,
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        '${_currentIndex + 1}/${onboardingQuestions.length}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.onSurfaceFaded(0.5), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _isSubmitting ? null : _skip,
                      child: Text('Пропустить', style: TextStyle(color: context.onSurfaceFaded(0.6))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // прогресс-полоска - визуально понятнее голого счётчика,
                // особенно на первом экране (легко оценить "надолго ли это")
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / onboardingQuestions.length,
                    minHeight: 4,
                    backgroundColor: context.onSurfaceFaded(0.1),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6C5CE7)),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  question.text,
                  style: TextStyle(color: context.onSurface, fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: AbsorbPointer(
                    absorbing: _isSubmitting,
                    child: ListView.separated(
                      itemCount: question.options.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final option = question.options[i];
                        final isSelected = _answers[_currentIndex] == option;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _selectAnswer(option),
                            child: GlassPanel(
                              opacity: isSelected ? 0.20 : 0.08,
                              borderRadius: BorderRadius.circular(16),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(option, style: TextStyle(color: context.onSurface, fontSize: 15.5)),
                                  ),
                                  if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF6C5CE7), size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
