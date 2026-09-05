import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/billing_plan.dart';
import '../models/usage_info.dart';
import '../services/ad_service.dart';
import '../services/billing_service.dart';
import '../services/telegram_service.dart';
import '../services/usage_service.dart';
import '../state/auth_store.dart';
import '../theme/app_text_color.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

class PurchaseScreen extends StatefulWidget {
  final AuthStore authStore;
  const PurchaseScreen({super.key, required this.authStore});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> with WidgetsBindingObserver {
  final _billingService = BillingService();
  final _usageService = UsageService();
  final _telegramService = TelegramService();
  final _adService = AdService();

  List<BillingPlan> _plans = [];
  UsageInfo? _usage;
  bool _isLoading = true;
  String? _error;
  String? _startingCheckoutFor;
  bool _isTelegramLinked = false;
  bool _isWatchingAd = false;
  int? _adBonusRemaining;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _adService.initialize().then((_) => _adService.preload(widget.authStore.baseUrl));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _billingService.dispose();
    _usageService.dispose();
    _telegramService.dispose();
    _adService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Пользователь мог только что вернуться из внешнего браузера, оплатив
    // подписку — обновляем статус. Нет надёжного способа поймать именно
    // "оплата прошла" без deep link'ов, поэтому просто перепроверяем при
    // каждом возврате в приложение — дёшево и достаточно.
    if (state == AppLifecycleState.resumed) {
      _loadUsage();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadPlans(), _loadUsage(), _loadTelegramStatus()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _billingService.listPlans(widget.authStore.baseUrl);
      if (mounted) setState(() => _plans = plans);
    } on BillingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _loadUsage() async {
    final token = widget.authStore.token;
    if (token == null) return;
    try {
      final usage = await _usageService.getMyUsage(baseUrl: widget.authStore.baseUrl, token: token);
      if (mounted) setState(() => _usage = usage);
    } on UsageException {
      // Не критично для этого экрана — просто не покажем текущий расход.
    }
  }

  Future<void> _loadTelegramStatus() async {
    final token = widget.authStore.token;
    if (token == null) return;
    final linked = await _telegramService.isLinked(baseUrl: widget.authStore.baseUrl, token: token);
    if (mounted) setState(() => _isTelegramLinked = linked);
  }

  Future<void> _startTelegramLink() async {
    final token = widget.authStore.token;
    if (token == null) return;
    try {
      final info = await _telegramService.startLink(baseUrl: widget.authStore.baseUrl, token: token);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => _TelegramCodeDialog(info: info),
      );
      _loadTelegramStatus();
    } on TelegramException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _watchAd() async {
    setState(() => _isWatchingAd = true);
    try {
      final ready = await _adService.preload(widget.authStore.baseUrl);
      if (!ready) {
        if (mounted) setState(() => _error = 'Реклама пока недоступна, попробуй чуть позже.');
        return;
      }
      final earned = await _adService.showAndWaitForReward();
      if (!earned) return; // человек закрыл ролик раньше времени - бонус не начисляем

      final token = widget.authStore.token;
      if (token == null) return;
      final remaining = await _telegramService.confirmAdWatched(baseUrl: widget.authStore.baseUrl, token: token);
      if (mounted) setState(() => _adBonusRemaining = remaining);
      // грузим следующий ролик заранее, чтобы не ждать при следующем нажатии
      _adService.preload(widget.authStore.baseUrl);
    } on TelegramException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isWatchingAd = false);
    }
  }

  Future<void> _buy(BillingPlan plan) async {
    final token = widget.authStore.token;
    if (token == null || !plan.isPurchasable) return;

    // если доступны оба способа оплаты - даём выбрать, не решаем за
    // человека молча в пользу одного из них
    String provider;
    if (plan.stripeAvailable && plan.yoomoneyAvailable) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _PaymentMethodSheet(),
      );
      if (choice == null) return;
      provider = choice;
    } else {
      provider = plan.stripeAvailable ? 'stripe' : 'yoomoney';
    }

    setState(() {
      _startingCheckoutFor = plan.tariff;
      _error = null;
    });
    try {
      final url = await _billingService.createCheckoutUrl(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        tariff: plan.tariff,
        provider: provider,
      );
      final uri = Uri.parse(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        setState(() => _error = 'Не удалось открыть страницу оплаты.');
      }
    } on BillingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _startingCheckoutFor = null);
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
                      icon: Icon(Icons.adaptive.arrow_back, color: context.onSurface),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Подписка',
                      style: TextStyle(color: context.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
                            )
                          : _buildContent(),
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

  Widget _buildContent() {
    final isOnFreeTier = _usage?.tariff == 'free';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_usage != null) _buildUsageCard(_usage!),
        if (isOnFreeTier) ...[
          const SizedBox(height: 16),
          _buildFreeTierBoostCard(),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
        ],
        const SizedBox(height: 20),
        Text(
          'ДОСТУПНЫЕ ТАРИФЫ',
          style: TextStyle(color: context.onSurfaceFaded(0.4), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (_plans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Тарифы пока не настроены.', style: TextStyle(color: context.onSurfaceFaded(0.4))),
          )
        else
          ..._plans.map(_buildPlanTile),
      ],
    );
  }

  Widget _buildFreeTierBoostCard() {
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Закончились бесплатные запросы на сегодня?',
            style: TextStyle(color: context.onSurface, fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Подпишись на наш Telegram-канал — получишь ещё запросов на сегодня, каждый день, пока подписан.',
            style: TextStyle(color: context.onSurfaceFaded(0.55), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isTelegramLinked ? null : _startTelegramLink,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: _isTelegramLinked
                            ? null
                            : const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)]),
                        color: _isTelegramLinked ? context.onSurfaceFaded(0.08) : null,
                      ),
                      child: Text(
                        _isTelegramLinked ? 'Telegram привязан' : 'Привязать Telegram',
                        style: TextStyle(
                          color: _isTelegramLinked ? context.onSurfaceFaded(0.5) : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // кнопка рекламы - только на платформах, где вообще есть
              // AdMob SDK (Android/iOS), см. ad_service.dart
              if (AdService.isSupportedPlatform) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isWatchingAd ? null : _watchAd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.onSurfaceFaded(0.2)),
                        ),
                        child: _isWatchingAd
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: context.onSurface),
                              )
                            : Text(
                                'Смотреть рекламу (+3)',
                                style: TextStyle(color: context.onSurface, fontWeight: FontWeight.w600, fontSize: 12.5),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_adBonusRemaining != null) ...[
            const SizedBox(height: 8),
            Text(
              'Бонусных запросов от рекламы осталось: $_adBonusRemaining',
              style: TextStyle(color: context.onSurfaceFaded(0.45), fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageCard(UsageInfo usage) {
    final fraction = usage.usageFraction;
    return GlassPanel(
      opacity: 0.09,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Текущий тариф', style: TextStyle(color: context.onSurfaceFaded(0.6), fontSize: 12.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)]),
                ),
                child: Text(usage.tariff, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            usage.tokensLimit == null
                ? '${usage.tokensUsedThisMonth} токенов использовано в этом месяце · без лимита'
                : '${usage.tokensUsedThisMonth} из ${usage.tokensLimit} токенов в этом месяце',
            style: TextStyle(color: context.onSurfaceFaded(0.5), fontSize: 12),
          ),
          if (fraction != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: context.onSurfaceFaded(0.08),
                valueColor: AlwaysStoppedAnimation(fraction > 0.85 ? const Color(0xFFFF6B6B) : const Color(0xFF6C5CE7)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanTile(BillingPlan plan) {
    final isBusy = _startingCheckoutFor == plan.tariff;
    final isCurrent = _usage?.tariff == plan.tariff;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        opacity: 0.08,
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.label, style: TextStyle(color: context.onSurface, fontWeight: FontWeight.w600, fontSize: 15)),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF00E6A0).withOpacity(0.18),
                          ),
                          child: const Text('текущий', style: TextStyle(color: Color(0xFF00E6A0), fontSize: 10.5)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.isFree
                        ? 'Бесплатно · ${plan.durationDays} дней'
                        : '${plan.priceRubDisplay} / ${plan.priceUsdDisplay} · ${plan.durationDays} дней',
                    style: TextStyle(color: context.onSurfaceFaded(0.5), fontSize: 12.5),
                  ),
                  if (!plan.isFree && !plan.isPurchasable) ...[
                    const SizedBox(height: 4),
                    Text('Скоро будет доступно', style: TextStyle(color: context.onSurfaceFaded(0.35), fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!plan.isFree)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: plan.isPurchasable && !isBusy ? () => _buy(plan) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: plan.isPurchasable
                            ? [const Color(0xFF6C5CE7), const Color(0xFF00B4D8)]
                            : [context.onSurfaceFaded(0.24), context.onSurfaceFaded(0.10)],
                      ),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Купить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              leading: const Icon(Icons.credit_card_rounded, color: Colors.white),
              title: const Text('Банковская карта (Stripe)', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop('stripe'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
              title: const Text('YooMoney', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop('yoomoney'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelegramCodeDialog extends StatelessWidget {
  final TelegramLinkInfo info;
  const _TelegramCodeDialog({required this.info});

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Привязка Telegram',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text(
                'Открой бота и отправь ему этот код в личные сообщения:',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  info.code,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 16),
              if (info.botUsername.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                    onPressed: () => launchUrl(Uri.parse('https://t.me/${info.botUsername}'), mode: LaunchMode.externalApplication),
                    child: const Text('Открыть бота'),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Закрыть', style: TextStyle(color: Colors.white54)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
