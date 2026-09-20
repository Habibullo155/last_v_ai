import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:ai_last_v/l10n/app_localizations.dart';
import '../models/chat_message.dart';
import '../models/chat_source.dart';
import '../services/ad_service.dart';
import '../utils/decoded_image_cache.dart';
import '../state/theme_store.dart';
import '../theme/app_text_color.dart';
import 'animated_ai_avatar.dart';
import 'glass_panel.dart';
import 'theme_variant_swatch.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onSpeak;
  final ValueChanged<String>? onEdit;
  final ValueChanged<bool>? onRate;
  final VoidCallback? onRegenerate;
  // true - "да, хочу пройти тест" (открывает выбор теста), false - "нет,
  // просто продолжим разговор" (отправляет обычное сообщение-продолжение)
  final ValueChanged<bool>? onTestPromptResponse;
  // вызывается один раз, когда человек либо выбрал вариант темы (тогда
  // ThemeStore уже обновлён к этому моменту), либо закрыл предложение
  // без выбора - в обоих случаях кнопки под сообщением нужно спрятать
  final VoidCallback? onThemePickerDismissed;
  // Дневной лимит бесплатных запросов исчерпан (см. message.dailyLimitReason) -
  // показываем кнопки "смотреть рекламу"/"привязать Telegram" прямо под
  // этим сообщением, а не заставляем человека самого идти в раздел
  // подписки. onWatchAd возвращает true, если реклама реально досмотрена
  // и бонус начислен (родительский экран сам вызывает AdService) -
  // false, если ролик закрыли раньше времени или он не загрузился.
  final Future<bool> Function()? onWatchAd;
  // открывает диалог с кодом привязки Telegram - фактическая привязка
  // подтверждается уже в самом боте, здесь только показываем код
  final VoidCallback? onLinkTelegram;
  // вызывается после успешного просмотра рекламы ИЛИ после закрытия
  // диалога привязки Telegram (не после подтверждённой привязки -
  // человек мог просто посмотреть код и закрыть, лимит от этого сам по
  // себе не поднимается, но и держать кнопки вечно смысла нет) - прячет
  // карточку под этим сообщением
  final VoidCallback? onDailyLimitResolved;
  // открывает экран подписки - для карточки "закончились pro-токены"
  // (message.modelDowngradedReason). Не закрывает саму карточку сама по
  // себе - она пропадёт естественным образом на следующий ответ, если
  // квота действительно обновится (новый тариф/новый месяц), в отличие
  // от карточек выше это не разовое действие с явным "решено"
  final VoidCallback? onUpgradeSubscription;
  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onReport,
    this.onSpeak,
    this.onEdit,
    this.onRate,
    this.onRegenerate,
    this.onTestPromptResponse,
    this.onThemePickerDismissed,
    this.onWatchAd,
    this.onLinkTelegram,
    this.onDailyLimitResolved,
    this.onUpgradeSubscription,
  });

  @override
  Widget build(BuildContext context) {
    // остаётся в истории для связности контекста ИИ (см. isHidden в
    // chat_message.dart), но никогда не рисуется пузырём - нулевая высота
    // просто не занимает места в ListView, соседние сообщения не сдвигаются
    if (message.isHidden) return const SizedBox.shrink();

    final isUser = message.role == MessageRole.user;
    final time = DateFormat.Hm().format(message.createdAt);

    final bubble = GlassPanel(
      opacity: isUser ? 0.16 : 0.09,
      tint: isUser ? const Color(0xFF6C5CE7) : null,
      blurred:
          false, // рендерится по одному на сообщение, BackdropFilter тут дорогой
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isUser ? 20 : 4),
        bottomRight: Radius.circular(isUser ? 4 : 20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.images != null && message.images!.isNotEmpty) ...[
              _AttachedImages(images: message.images!),
              if (message.content.isNotEmpty) const SizedBox(height: 8),
            ],
            if (message.content.isNotEmpty)
              SelectableText(
                message.content,
                style: TextStyle(
                  color: message.isError
                      ? const Color(0xFFFFB4B4)
                      : context.onSurfaceFaded(0.94),
                  fontSize: 15.5,
                  height: 1.45,
                ),
              ),
            if (message.sources != null && message.sources!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _SourcesBlock(sources: message.sources!),
            ],
            if (message.offersTestPrompt &&
                !message.testPromptAnswered &&
                onTestPromptResponse != null) ...[
              const SizedBox(height: 10),
              _TestOfferButtons(onAnswer: onTestPromptResponse!),
            ],
            if (message.offersThemePicker &&
                !message.themePickerAnswered &&
                onThemePickerDismissed != null) ...[
              const SizedBox(height: 10),
              _InlineThemePicker(onDone: onThemePickerDismissed!),
            ],
            if (message.dailyLimitReason != null &&
                !message.dailyLimitResolved &&
                onWatchAd != null &&
                onLinkTelegram != null) ...[
              const SizedBox(height: 10),
              _DailyLimitCard(
                reason: message.dailyLimitReason!,
                onWatchAd: onWatchAd!,
                onLinkTelegram: onLinkTelegram!,
                onResolved: () => onDailyLimitResolved?.call(),
              ),
            ],
            if (message.modelDowngradedReason != null &&
                onUpgradeSubscription != null) ...[
              const SizedBox(height: 10),
              _ModelDowngradedNotice(onUpgrade: onUpgradeSubscription!),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: context.onSurfaceFaded(0.38),
                    fontSize: 11,
                  ),
                ),
                if (!message.isStreaming) ...[
                  const SizedBox(width: 8),
                  _CopyIconButton(text: message.content),
                  if (onRate != null) ...[
                    const SizedBox(width: 4),
                    _RateIconButton(
                      icon: Icons.thumb_up_outlined,
                      activeIcon: Icons.thumb_up_rounded,
                      active: message.liked == true,
                      onTap: () => onRate!(true),
                    ),
                    const SizedBox(width: 2),
                    _RateIconButton(
                      icon: Icons.thumb_down_outlined,
                      activeIcon: Icons.thumb_down_rounded,
                      active: message.liked == false,
                      onTap: () => onRate!(false),
                    ),
                  ],
                  if (onRegenerate != null) ...[
                    const SizedBox(width: 2),
                    _RateIconButton(
                      icon: Icons.refresh_rounded,
                      activeIcon: Icons.refresh_rounded,
                      active: false,
                      onTap: onRegenerate!,
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );

    final hasMenu = !message.isStreaming;
    final bubbleWithGestures = !hasMenu
        ? bubble
        : GestureDetector(
            onLongPress: () => _showMessageMenu(context),
            child: bubble,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _avatar(context, isUser: false),
          if (!isUser) const SizedBox(width: 8),
          Flexible(child: bubbleWithGestures),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _avatar(context, isUser: true),
        ],
      ),
    );
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2036),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          // фон листа всегда тёмный (0xFF1A2036 выше), текст константами
          // белый - от темы приложения не зависит
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white70,
                  ),
                  title: Text(
                    l10n.messageMenuEditRetry,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showEditDialog(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white70),
                title: Text(
                  l10n.messageMenuCopyText,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await Clipboard.setData(ClipboardData(text: message.content));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.messageCopiedSnack),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              if (onSpeak != null)
                ListTile(
                  leading: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white70,
                  ),
                  title: Text(
                    l10n.messageMenuReadAloud,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSpeak?.call();
                  },
                ),
              if (onReport != null)
                ListTile(
                  leading: const Icon(
                    Icons.flag_outlined,
                    color: Color(0xFFFFD166),
                  ),
                  title: Text(
                    l10n.messageMenuReport,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onReport?.call();
                  },
                ),
              if (onDelete != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFFB4B4),
                  ),
                  title: Text(
                    l10n.messageMenuDelete,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onDelete?.call();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: message.content);
    await showDialog(
      context: context,
      // тот же тёмный лист поверх приложения, что и меню выше
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassPanel(
            tint: const Color(0xFF1A2036),
            opacity: 0.95,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.messageEditDialogTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.messageEditDialogWarning,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 6,
                    minLines: 1,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          l10n.commonCancel,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                        ),
                        onPressed: () {
                          final text = controller.text.trim();
                          Navigator.of(context).pop();
                          if (text.isNotEmpty && text != message.content) {
                            onEdit?.call(text);
                          }
                        },
                        child: Text(l10n.messageRetryButton),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _avatar(BuildContext context, {required bool isUser}) {
    if (!isUser && message.isStreaming) {
      return AnimatedAiAvatar(isActive: true, size: 34);
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isUser
              ? [const Color(0xFF6C5CE7), const Color(0xFF00D9C0)]
              : [
                  const Color(0xFF6FB1DE),
                  const Color(0xFF4DD0C4),
                ], // приглушённые сине-зелёные для ассистента
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Icon(
        (isUser
                ? Icons.person_rounded
                : Image.asset('assets/images/ai_icon.png'))
            as IconData?,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}

class _CopyIconButton extends StatelessWidget {
  final String text;
  const _CopyIconButton({required this.text});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.messageCopiedSnack),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            Icons.copy_rounded,
            size: 13,
            color: context.onSurfaceFaded(0.38),
          ),
        ),
      ),
    );
  }
}

class _RateIconButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;
  const _RateIconButton({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            active ? activeIcon : icon,
            size: 13,
            color: active
                ? const Color(0xFF6C5CE7)
                : context.onSurfaceFaded(0.38),
          ),
        ),
      ),
    );
  }
}

// видно только когда сервер прислал источники, а он делает это только
// для админа - на Flutter ничего дополнительно проверять не нужно
class _SourcesBlock extends StatelessWidget {
  final List<ChatSource> sources;
  const _SourcesBlock({required this.sources});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.18),
        border: Border.all(color: context.onSurfaceFaded(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.source_outlined,
                size: 12,
                color: context.onSurfaceFaded(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.messageSourcesAdminOnly,
                style: TextStyle(
                  color: context.onSurfaceFaded(0.4),
                  fontSize: 9.5,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final s in sources)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.messageSourceLine(
                  s.filename,
                  s.page != null ? l10n.messageSourcePageSuffix(s.page!) : '',
                  (s.similarity * 100).round(),
                ),
                style: TextStyle(
                  color: context.onSurfaceFaded(0.55),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Превью прикреплённых фото в пузыре сообщения — тап открывает во весь
/// экран. base64 хранится и рендерится напрямую из памяти, отдельного
/// файла на диске для этого не заводим.
class _AttachedImages extends StatefulWidget {
  final List<String> images;
  const _AttachedImages({required this.images});

  @override
  State<_AttachedImages> createState() => _AttachedImagesState();
}

class _AttachedImagesState extends State<_AttachedImages> {
  // null, пока не декодировано - показываем плейсхолдер вместо этой
  // позиции, не блокируя отрисовку остальных уже готовых картинок
  late List<Uint8List?> _decoded;

  @override
  void initState() {
    super.initState();
    _decoded = List.filled(widget.images.length, null);
    _decodeAll();
  }

  @override
  void didUpdateWidget(_AttachedImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      _decoded = List.filled(widget.images.length, null);
      _decodeAll();
    }
  }

  Future<void> _decodeAll() async {
    for (var i = 0; i < widget.images.length; i++) {
      final bytes = await decodeImageCached(widget.images[i]);
      if (mounted) setState(() => _decoded[i] = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(widget.images.length, (i) {
        final bytes = _decoded[i];
        if (bytes == null) {
          return Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: 140,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
        );
      }),
    );
  }
}

/// Показывает ВСЕ доступные образцы темы прямо под сообщением ИИ, когда
/// оно содержало маркер [[OFFER_THEME_PICKER]] - вместо того чтобы
/// заставлять модель помнить, какие варианты уже предлагались (ненадёжно
/// для маленькой модели), человек просто видит весь набор и выбирает сам.
class _InlineThemePicker extends StatelessWidget {
  final VoidCallback onDone;
  const _InlineThemePicker({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeStore.instance,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.messageChooseWhatYouLike,
              style: TextStyle(
                color: context.onSurfaceFaded(0.55),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: BackgroundVariant.values
                      .map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ThemeVariantSwatch(
                            variant: v,
                            selected: ThemeStore.instance.variant == v,
                            onTap: () {
                              ThemeStore.instance.setVariant(v);
                              onDone();
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            TextButton(
              onPressed: onDone,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.messageNotNow,
                style: TextStyle(
                  color: context.onSurfaceFaded(0.4),
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Кнопки Да/Нет под сообщением ИИ, когда оно содержало маркер
/// [[OFFER_TEST]] (обработано и вырезано в chat_store.dart). Решение
/// всегда за человеком - ИИ только предлагает, ничего не выбирает сам.
class _TestOfferButtons extends StatelessWidget {
  final ValueChanged<bool> onAnswer;
  const _TestOfferButtons({required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnswerChip(
          label: l10n.messageYesLetsTest,
          backgroundColor: const Color(0xFF6C5CE7),
          textColor: Colors.white,
          onTap: () => onAnswer(true),
        ),
        const SizedBox(width: 8),
        _AnswerChip(
          label: l10n.messageNoLetsContinue,
          backgroundColor: context.onSurfaceFaded(0.1),
          textColor: context.onSurfaceFaded(0.8),
          onTap: () => onAnswer(false),
        ),
      ],
    );
  }
}

class _AnswerChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  const _AnswerChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: backgroundColor,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Карточка "закончились бесплатные запросы на сегодня" прямо в чате -
/// вместо того чтобы заставлять человека идти в раздел подписки самому,
/// кнопка нужного действия сразу под сообщением. reason определяет,
/// какая ИМЕННО кнопка нужна (см. daily_limits.py на бэкенде): если
/// человек ещё не подписан на Telegram - предлагаем подписку, если уже
/// подписан (и её бонус тоже исчерпан) - остаётся только реклама.
/// Показывать обе сразу не нужно и не соответствовало бы тому, что
/// реально доступно прямо сейчас.
class _DailyLimitCard extends StatefulWidget {
  final String reason; // "telegram_needed" | "ad_needed"
  final Future<bool> Function() onWatchAd;
  final VoidCallback onLinkTelegram;
  final VoidCallback onResolved;
  const _DailyLimitCard({
    required this.reason,
    required this.onWatchAd,
    required this.onLinkTelegram,
    required this.onResolved,
  });

  @override
  State<_DailyLimitCard> createState() => _DailyLimitCardState();
}

class _DailyLimitCardState extends State<_DailyLimitCard> {
  bool _isWatchingAd = false;

  Future<void> _handleWatchAd() async {
    setState(() => _isWatchingAd = true);
    try {
      final earned = await widget.onWatchAd();
      // earned=false - ролик закрыли раньше времени или не загрузился,
      // бонус не начислен, оставляем кнопку - можно попробовать ещё раз
      if (earned) widget.onResolved();
    } finally {
      if (mounted) setState(() => _isWatchingAd = false);
    }
  }

  void _handleLinkTelegram() {
    // сама привязка подтверждается уже в боте, не в этом диалоге -
    // прячем карточку сразу после открытия диалога с кодом, не после
    // подтверждённой привязки (иначе человеку пришлось бы держать этот
    // же диалог открытым, чтобы карточка не появилась заново - а лимит
    // всё равно обновится сам, когда придёт следующий запрос к модели)
    widget.onLinkTelegram();
    widget.onResolved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showTelegramButton = widget.reason == 'telegram_needed';
    final showAdButton =
        widget.reason == 'ad_needed' && AdService.isSupportedPlatform;

    if (!showTelegramButton && !showAdButton) {
      // ни один вариант недоступен прямо сейчас (например, веб без
      // поддержки рекламного SDK, а причина - именно "ad_needed") -
      // ничего не показываем, не оставляем бесполезную пустую карточку
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (showTelegramButton)
          _DailyLimitActionButton(
            label: l10n.purchaseTelegramLinkButton,
            icon: Icons.send_rounded,
            onTap: _handleLinkTelegram,
            isLoading: false,
          ),
        if (showAdButton)
          _DailyLimitActionButton(
            label: l10n.purchaseWatchAdButton,
            icon: Icons.play_circle_outline_rounded,
            onTap: _isWatchingAd ? null : _handleWatchAd,
            isLoading: _isWatchingAd,
          ),
      ],
    );
  }
}

class _DailyLimitActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;
  const _DailyLimitActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Уведомление "закончились pro-токены, ответили обычной моделью" -
/// показывается прямо под ЭТИМ конкретным ответом (не на каждом
/// последующем сообщении - message.modelDowngradedReason ставится
/// только на тот ответ, где случилось переключение). Спокойный тон, не
/// тревожный - это не сбой, а ожидаемое исчерпание месячной квоты.
class _ModelDowngradedNotice extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _ModelDowngradedNotice({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFFFD166).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFFFFD166).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: Color(0xFFFFD166),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.modelDowngradedNotice,
                  style: TextStyle(
                    color: context.onSurfaceFaded(0.75),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _DailyLimitActionButton(
              label: l10n.modelDowngradedUpgradeButton,
              icon: Icons.arrow_upward_rounded,
              onTap: onUpgrade,
              isLoading: false,
            ),
          ),
        ],
      ),
    );
  }
}
