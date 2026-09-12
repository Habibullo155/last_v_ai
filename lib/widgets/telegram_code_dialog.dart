import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ai_last_v/l10n/app_localizations.dart';
import '../services/telegram_service.dart';
import 'glass_panel.dart';

/// Показывает код для привязки Telegram-аккаунта - раньше жил только в
/// purchase_screen.dart как приватный класс, вынесен сюда публичным,
/// чтобы тот же диалог мог показать и карточка "лимит закончился" прямо
/// в чате, не дублируя разметку.
class TelegramCodeDialog extends StatelessWidget {
  final TelegramLinkInfo info;
  const TelegramCodeDialog({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassPanel(
        opacity: 0.18,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.purchaseTelegramDialogTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.purchaseTelegramDialogBody,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  info.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (info.botUsername.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://t.me/${info.botUsername}'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(l10n.purchaseOpenBotButton),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.chatCloseTooltip,
                    style: const TextStyle(color: Colors.white54),
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
