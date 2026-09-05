// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'AI Glass Chat';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonEdit => 'Изменить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonConfirm => 'Подтвердить';

  @override
  String get commonLoading => 'Загрузка...';

  @override
  String get commonError => 'Ошибка';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonLogout => 'Выйти';

  @override
  String get authSignInTitle => 'Вход в AI Chat';

  @override
  String get authCreateAccount => 'Создать аккаунт';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authPasswordHint => 'Пароль';

  @override
  String get authRepeatPasswordHint => 'Повтори пароль';

  @override
  String get authForgotPassword => 'Забыли пароль?';

  @override
  String get authRegisterButton => 'Зарегистрироваться';

  @override
  String get authLoginButton => 'Войти';

  @override
  String get authHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get authNoAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get authPasswordLengthOk => 'Длина пароля подходит';

  @override
  String authPasswordLengthHint(Object length, Object minLength) {
    return 'Минимум $minLength символов (введено: $length)';
  }

  @override
  String get authPasswordsMatch => 'Пароли совпадают';

  @override
  String get authPasswordsMismatch => 'Пароли не совпадают';

  @override
  String get forgotPasswordTitle => 'Восстановление пароля';

  @override
  String get forgotPasswordEmailPrompt => 'Укажи email, на который зарегистрирован аккаунт — пришлём код для сброса пароля.';

  @override
  String get forgotPasswordSendCode => 'Отправить код';

  @override
  String get forgotPasswordCheckEmail => 'Если такой email зарегистрирован — на него отправлен код для восстановления пароля. Проверь почту (и папку \"Спам\") и введи код ниже вместе с новым паролем.';

  @override
  String get forgotPasswordHaveCode => 'У меня есть код';

  @override
  String get forgotPasswordResend => 'Отправить ещё раз';

  @override
  String get forgotPasswordCodeTitle => 'Код из письма';

  @override
  String get forgotPasswordCodeHint => 'Код';

  @override
  String get forgotPasswordNewPasswordHint => 'Новый пароль';

  @override
  String get forgotPasswordSubmit => 'Сменить пароль';

  @override
  String get forgotPasswordDone => 'Пароль изменён. Теперь можно войти с новым паролем.';

  @override
  String get lockScreenTitle => 'Приложение заблокировано';

  @override
  String get lockScreenFailedHint => 'Не удалось подтвердить — попробуй ещё раз.';

  @override
  String get lockScreenPrompt => 'Подтверди личность, чтобы продолжить.';

  @override
  String get lockScreenUnlockButton => 'Разблокировать';

  @override
  String get lockScreenUsePassword => 'Войти паролем';

  @override
  String get verifyEmailTitle => 'Подтверждение почты';

  @override
  String get verifyEmailPromptGeneric => 'Введи код, который пришёл на почту при регистрации.';

  @override
  String verifyEmailPromptWithEmail(Object email) {
    return 'Введи код, который пришёл на $email.';
  }

  @override
  String get verifyEmailCodeHint => 'Код из письма';

  @override
  String get verifyEmailResendButton => 'Отправить код ещё раз';

  @override
  String get verifyEmailSubmitButton => 'Подтвердить';

  @override
  String get verifyEmailResentMessage => 'Код отправлен повторно — проверь почту.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionAppearance => 'ОФОРМЛЕНИЕ';

  @override
  String get settingsThemeLabel => 'Тема';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsBackgroundColorLabel => 'Цвет фона';

  @override
  String get settingsSectionPerformance => 'ПРОИЗВОДИТЕЛЬНОСТЬ';

  @override
  String get settingsPerformanceModeLabel => 'Экономный режим';

  @override
  String get settingsPerformanceModeDescription => 'Отключает анимированный фон и размытие \"стекла\" по всему приложению. Стоит включить, если телефон слабый, тормозит или перегревается — на большинстве устройств в этом нет необходимости.';

  @override
  String get settingsSectionNotifications => 'УВЕДОМЛЕНИЯ';

  @override
  String get settingsSoundOnMessage => 'Звук на новое сообщение';

  @override
  String get settingsVibrationOnMessage => 'Вибрация на новое сообщение';

  @override
  String get settingsSectionVoice => 'ГОЛОС';

  @override
  String get settingsVoiceButtonsInChat => 'Голосовые кнопки в чате';

  @override
  String get settingsVoiceAndSpeechRecognition => 'Выбор голоса и распознавание речи';

  @override
  String get settingsSectionSecurity => 'БЕЗОПАСНОСТЬ';

  @override
  String get settingsBiometricLogin => 'Вход по биометрии';

  @override
  String get settingsBiometricNotSupported => 'На этом устройстве не настроена биометрия (Face ID/отпечаток) — включи её в настройках самого устройства, если хочешь использовать здесь.';

  @override
  String get settingsSectionReminders => 'НАПОМИНАНИЯ';

  @override
  String get settingsReminderDescription => 'Раз в день, в выбранное время (например, когда ты обычно уже дома) — просто предложит заглянуть, если захочется поговорить.';

  @override
  String get settingsDailyReminder => 'Ежедневное напоминание';

  @override
  String get settingsReminderTimeLabel => 'Время';

  @override
  String get settingsReminderPermissionDenied => 'Нет разрешения на уведомления — включи их в настройках устройства для этого приложения.';

  @override
  String get settingsSectionAccount => 'АККАУНТ';

  @override
  String get settingsLogoutButton => 'Выйти из аккаунта';

  @override
  String get settingsSectionAbout => 'О ПРИЛОЖЕНИИ';

  @override
  String get settingsAppVersion => 'Версия 1.0.0';

  @override
  String get settingsModelInfo => 'Модель по умолчанию: gemma4:e2b через локальный Ollama.';

  @override
  String get settingsSectionDangerZone => 'ОПАСНАЯ ЗОНА';

  @override
  String get settingsDeleteAccountButton => 'Удалить аккаунт';

  @override
  String get settingsDeleteAccountDialogTitle => 'Удалить аккаунт?';

  @override
  String get settingsDeleteAccountWarning => 'Это необратимо: аккаунт, история обращений в поддержку и статистика использования будут удалены полностью. История переписки на этом устройстве останется — она никогда не хранилась на сервере, и её можно удалить отдельно.';

  @override
  String get settingsConfirmWithPassword => 'Подтверди паролем';

  @override
  String get settingsDeleteForeverButton => 'Удалить навсегда';

  @override
  String get chatNoSoundsUploaded => 'Пока нет загруженных звуков — админ ещё не добавил их.';

  @override
  String get chatStopButton => 'Остановить';

  @override
  String get chatRoleUser => 'Пользователь';

  @override
  String get chatRoleAi => 'ИИ';

  @override
  String get chatMigraineLabel => 'Мигрень или сильная усталость';

  @override
  String get chatWhatDoYouNeedNow => 'Что нужно сейчас?';

  @override
  String get chatTakeTestTitle => 'Пройти тест';

  @override
  String get chatTakeTestSubtitle => 'Опросник — результат сразу обсудим здесь';

  @override
  String get chatWhichQuestionnaire => 'Какой опросник?';

  @override
  String get chatPhq9Subtitle => 'Депрессивные симптомы, 9 вопросов';

  @override
  String get chatGad7Subtitle => 'Тревожные симптомы, 7 вопросов';

  @override
  String get chatAsrsSubtitle => 'Скрининг СДВГ, 6 вопросов';

  @override
  String get chatOtherTestsTitle => 'Другие тесты';

  @override
  String get chatOtherTestsSubtitle => 'Опросники, созданные командой';

  @override
  String get chatCallHelpTitle => 'Позвать человека на помощь?';

  @override
  String get chatCallHelpDescription => 'Подключится врач или специалист из команды. Это не замена экстренной службе — если ситуация требует срочной медицинской помощи, звони в местную службу экстренной помощи.';

  @override
  String get chatPrepareSummaryQuestion => 'Подготовить врачу краткую сводку о разговоре с ИИ (не переписку целиком), чтобы не объяснять всё заново?';

  @override
  String get chatYesPrepareSummary => 'Да, подготовить сводку';

  @override
  String get chatNoDontShow => 'Нет, не показывать';

  @override
  String get chatCallButton => 'Позвать';

  @override
  String get chatCloseTooltip => 'Закрыть';

  @override
  String get chatNewChatTitle => 'Новый чат';

  @override
  String get chatDisclaimer => 'ИИ может ошибаться. Проверяй важную информацию самостоятельно.';

  @override
  String get chatVerifyEmailBanner => 'Подтверди почту';

  @override
  String get chatMuteBackgroundSound => 'Выключить фоновый звук';

  @override
  String get chatUnmuteBackgroundSound => 'Включить фоновый звук';

  @override
  String get chatMenuTooltip => 'Меню';

  @override
  String get chatMenuProfile => 'Личный кабинет';

  @override
  String get chatMenuWellbeing => 'Самочувствие';

  @override
  String get chatMenuSleepMusic => 'Музыка для сна';

  @override
  String get chatMenuSubscription => 'Подписка';

  @override
  String get chatMenuMyReports => 'Мои жалобы';

  @override
  String get chatMenuLiveHelp => 'Живая помощь';

  @override
  String get chatMenuOperatorCabinet => 'Кабинет оператора';

  @override
  String get chatMenuSupport => 'Поддержка';

  @override
  String get chatMenuBlog => 'Блог';

  @override
  String get chatSuggestion1 => 'Объясни квантовую физику простыми словами';

  @override
  String get chatSuggestion2 => 'Напиши план тренировок на неделю';

  @override
  String get chatSuggestion3 => 'Помоги придумать название для проекта';

  @override
  String get chatSuggestion4 => 'Как улучшить свой код на Dart?';

  @override
  String get chatWhatCanIHelpWith => 'Чем помочь сегодня?';

  @override
  String get aiModeSupportTitle => 'Поддержать';

  @override
  String get aiModeSupportSubtitle => 'Просто побыть рядом в разговоре';

  @override
  String get aiModeSupportOpener => 'Мне сейчас нужна поддержка — просто побудь рядом в разговоре, подбодри меня.';

  @override
  String get aiModeListenTitle => 'Просто выслушать';

  @override
  String get aiModeListenSubtitle => 'Не обязательно сразу советовать';

  @override
  String get aiModeListenOpener => 'Мне просто нужно выговориться — послушай, не обязательно сразу давать советы.';

  @override
  String get aiModeBreakupTitle => 'Развод или разрыв отношений';

  @override
  String get aiModeBreakupSubtitle => 'Начать разговор об этом';

  @override
  String get aiModeBreakupOpener => 'У меня сейчас развод или расставание, и мне тяжело с этим справляться. Можешь поддержать меня в разговоре об этом?';

  @override
  String get aiModeGriefTitle => 'Тяжёлая утрата';

  @override
  String get aiModeGriefSubtitle => 'Начать разговор об этом';

  @override
  String get aiModeGriefOpener => 'У меня недавно случилась тяжёлая утрата близкого человека, и мне хочется с кем-то об этом поговорить.';

  @override
  String get aiModeJobLossTitle => 'Потеря работы или крупные перемены';

  @override
  String get aiModeJobLossSubtitle => 'Начать разговор об этом';

  @override
  String get aiModeJobLossOpener => 'У меня сейчас сложный период — потеряна работа или произошла резкая перемена в жизни, и это тяжело переживать. Можешь поддержать меня в разговоре об этом?';

  @override
  String get aiModeRationalizerTitle => 'Рационализатор';

  @override
  String get aiModeRationalizerSubtitle => 'Разобрать тревожную мысль по методике КПТ';

  @override
  String get aiModeRationalizerOpener => 'У меня есть тревожная мысль, которая не даёт покоя. Помоги мне разобрать её по методике КПТ — задавай мне наводящие вопросы по одному за раз (например, какие есть доказательства этой мысли, что самое худшее может случиться и насколько это вероятно), чтобы посмотреть на ситуацию яснее.';

  @override
  String get profileBirthDateHelpText => 'Дата рождения';

  @override
  String profileAgeYears(num age) {
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age лет',
      many: '$age лет',
      few: '$age года',
      one: '$age год',
    );
    return '$_temp0';
  }

  @override
  String get profileTakePhoto => 'Сделать фото';

  @override
  String get profileChooseFromGallery => 'Выбрать из галереи';

  @override
  String get profileDeletePhoto => 'Удалить фото';

  @override
  String get profileTitle => 'Личный кабинет';

  @override
  String get profileNoData => 'Нет данных';

  @override
  String get profileSectionPersonal => 'ЛИЧНОЕ';

  @override
  String get profileFullName => 'ФИО';

  @override
  String get profileNotSpecified => 'не указано';

  @override
  String get profileBirthDate => 'Дата рождения';

  @override
  String get profileHobbies => 'Хобби';

  @override
  String get profileEmergencyContact => 'Экстренный контакт';

  @override
  String get profileSectionAccount => 'АККАУНТ';

  @override
  String get profileRole => 'Роль';

  @override
  String get profileRoleAdmin => 'Администратор';

  @override
  String get profileRoleUser => 'Пользователь';

  @override
  String get profileAccountCreated => 'Аккаунт создан';

  @override
  String get profileEditButton => 'Редактировать профиль';

  @override
  String get profileChangePasswordButton => 'Изменить пароль';

  @override
  String get profileEditTitle => 'Личные данные';

  @override
  String get profileEditHint => 'Все поля необязательны — оставь пустым, чтобы очистить.';

  @override
  String get profileEmergencySectionLabel => 'НА ВСЯКИЙ СЛУЧАЙ';

  @override
  String get profileEmergencyContactHint => 'Например: Мама, +7 900 123-45-67';

  @override
  String get profileLogoutButton => 'Выйти';

  @override
  String get profilePasswordTooShort => 'Новый пароль должен быть не короче 8 символов.';

  @override
  String get profilePasswordsMismatch => 'Пароли не совпадают.';

  @override
  String get profileChangePasswordTitle => 'Изменить пароль';

  @override
  String get profileCurrentPasswordLabel => 'Текущий пароль';

  @override
  String get profileNewPasswordLabel => 'Новый пароль';

  @override
  String get profileRepeatNewPasswordLabel => 'Повтори новый пароль';

  @override
  String get profileChangeEmailTitle => 'Изменить почту';

  @override
  String profileCurrentEmailLabel(Object email) {
    return 'Сейчас: $email';
  }

  @override
  String get profileNewEmailLabel => 'Новый адрес';

  @override
  String profileCodeSentMessage(Object email) {
    return 'Код отправлен на $email. Введи его ниже, чтобы завершить смену.';
  }

  @override
  String get profileCodeFromEmailLabel => 'Код из письма';

  @override
  String get profileSendCodeButton => 'Отправить код';

  @override
  String get sidebarCalendarTitle => 'Календарь';

  @override
  String get sidebarCalendarSubtitle => 'Результаты опросников по дням';

  @override
  String get sidebarWellbeingSubtitle => 'Пройти тест, ситуативная помощь';

  @override
  String get sidebarCallHelpTitle => 'Позвать на помощь';

  @override
  String get sidebarCallHelpSubtitle => 'Подключится врач или специалист';

  @override
  String get sidebarHistoryLabel => 'ИСТОРИЯ';

  @override
  String get sidebarNoConversations => 'Пока нет диалогов';

  @override
  String get sidebarRenameChatTitle => 'Переименовать чат';

  @override
  String get sidebarDeleteChatTitle => 'Удалить чат?';

  @override
  String sidebarDeleteChatBody(Object title) {
    return 'Переписка «$title» будет удалена без возможности восстановить.';
  }

  @override
  String get sidebarEmptyConversation => 'Пусто';

  @override
  String get crisisResourcesDefaultTitle => 'Если хочется поговорить с кем-то';

  @override
  String get crisisResourcesBody => '• Экстренная психологическая помощь для взрослых и детей в России, круглосуточно и бесплатно: 8-800-100-49-94\n• Детский и подростковый телефон доверия: 8-800-2000-122 (короткий номер — 124)\n\nЕсли ты не в России — поищи местную кризисную линию по запросу «suicide crisis line» и название своей страны; в США и Канаде можно позвонить или написать на 988.';

  @override
  String get navChat => 'Чат';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navSleep => 'Сон';

  @override
  String get navWellbeing => 'Забота';

  @override
  String get sleepMusicTitle => 'Музыка для сна';

  @override
  String get sleepMusicNoneUploaded => 'Пока нет загруженной музыки — админ ещё не добавил её.';

  @override
  String get customTestListTitle => 'Тесты';

  @override
  String get customTestListEmpty => 'Пока нет доступных тестов.';

  @override
  String get blogTitle => 'Блог';

  @override
  String get blogListEmpty => 'Постов пока нет — загляни позже.';

  @override
  String get who5Q1 => 'Я чувствую себя бодрой(-ым) и в хорошем настроении';

  @override
  String get who5Q2 => 'Я чувствую себя спокойной(-ым) и раскованной(-ым)';

  @override
  String get who5Q3 => 'Я чувствую себя активной(-ым) и энергичной(-ым)';

  @override
  String get who5Q4 => 'Я просыпаюсь и чувствую себя свежей(-им) и отдохнувшей(-им)';

  @override
  String get who5Q5 => 'Каждый день со мной происходят вещи, представляющие для меня интерес';

  @override
  String get who5ScaleAllTime => 'Всё время';

  @override
  String get who5ScaleMostTime => 'Большую часть времени';

  @override
  String get who5ScaleMoreThanHalf => 'Более половины времени';

  @override
  String get who5ScaleLessThanHalf => 'Менее половины времени';

  @override
  String get who5ScaleSomeTime => 'Некоторое время';

  @override
  String get who5ScaleNever => 'Никогда';

  @override
  String get wellbeingSaveFailed => 'Не удалось сохранить результат локально. Можно пройти ещё раз.';

  @override
  String get wellbeingToolsSection => 'ИНСТРУМЕНТЫ';

  @override
  String get wellbeingBreathingTitle => 'Дыхание';

  @override
  String get wellbeingGroundingTitle => 'Заземление';

  @override
  String get wellbeingGratitudeTitle => 'Благодарность';

  @override
  String get wellbeingGratitudeSubtitle => 'Дневник';

  @override
  String get wellbeingBilateralTitle => 'Билатеральная стимуляция';

  @override
  String get wellbeingBilateralSubtitle => 'Слежение глазами';

  @override
  String get wellbeingMuscleRelaxationTitle => 'Мышечная релаксация';

  @override
  String get wellbeingMuscleRelaxationSubtitle => 'Напряжение/отдых';

  @override
  String get wellbeingSafeTitle => 'Сейф';

  @override
  String get wellbeingSafeSubtitle => 'Убрать мысль на потом';

  @override
  String get wellbeingLeavesTitle => 'Листья на ручье';

  @override
  String get wellbeingLeavesSubtitle => 'Отпустить мысль';

  @override
  String get wellbeingFreewritingTitle => 'Фрирайтинг';

  @override
  String get wellbeingFreewritingSubtitle => 'Выгрузка мыслей';

  @override
  String get wellbeingQuestionnairesSection => 'ОПРОСНИКИ';

  @override
  String get wellbeingQuestionnairesDisclaimer => 'Официальные, свободно распространяемые инструменты. Не диагностика — только скрининг для себя.';

  @override
  String get who5CardTitle => 'ВОЗ-5 — общее самочувствие';

  @override
  String get wellbeingReleaseTitle => 'Отпустить';

  @override
  String get wellbeingReleaseSubtitle => 'Написать тяжёлую мысль и сжечь/разбить её';

  @override
  String get wellbeingSleepMusicTitle => 'Музыка для сна';

  @override
  String get wellbeingSleepMusicSubtitle => 'Спокойные звуки перед сном';

  @override
  String get who5HistorySection => 'ИСТОРИЯ ВОЗ-5';

  @override
  String get who5Instructions => 'Отметь, что ближе всего к тому, как ты себя чувствовал(а) последние две недели.';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonNext => 'Далее';

  @override
  String get who5ShowResult => 'Показать результат';

  @override
  String get who5ResultLow => 'Показатель ниже среднего';

  @override
  String get who5ResultNormal => 'Показатель в пределах нормы';

  @override
  String get who5DescriptionLow => 'Это не диагноз. По методике ВОЗ балл ниже 50% — повод обратиться к специалисту для более точной оценки состояния, особенно если так продолжается больше двух недель.';

  @override
  String get who5DescriptionNormal => 'Официальная методика ВОЗ считает такой результат признаком нормального психологического благополучия за последние две недели.';

  @override
  String who5DiscussPrompt(Object result) {
    return 'Я прошёл(ла) опросник ВОЗ-5 (общее самочувствие): $result. Можешь прокомментировать результат и поддержать меня?';
  }

  @override
  String get who5DiscussButton => 'Обсудить с ИИ';

  @override
  String get who5BackToHistory => 'К истории';

  @override
  String get wellbeingAiDisclaimer => 'ИИ и автоматические подсчёты могут ошибаться. Этот опросник — инструмент для самонаблюдения, а не диагностика. Для точной оценки психологического состояния обратись к врачу или психотерапевту.';

  @override
  String get who5LicenseAttribution => 'Опросник: World Health Organization-Five Well-Being Index (WHO-5), © World Health Organization 2024, лицензия CC BY-NC-SA 3.0 IGO. Использование ВОЗ этого приложения не подразумевается.';
}
