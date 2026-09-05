import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Glass Chat'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get commonLogout;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to AI Chat'**
  String get authSignInTitle;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordHint;

  /// No description provided for @authRepeatPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get authRepeatPasswordHint;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authRegisterButton;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authLoginButton;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account? Sign up'**
  String get authNoAccount;

  /// No description provided for @authPasswordLengthOk.
  ///
  /// In en, this message translates to:
  /// **'Password length is fine'**
  String get authPasswordLengthOk;

  /// No description provided for @authPasswordLengthHint.
  ///
  /// In en, this message translates to:
  /// **'At least {minLength} characters ({length} entered)'**
  String authPasswordLengthHint(Object length, Object minLength);

  /// No description provided for @authPasswordsMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords match'**
  String get authPasswordsMatch;

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get authPasswordsMismatch;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordEmailPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the email your account is registered with — we\'ll send a reset code.'**
  String get forgotPasswordEmailPrompt;

  /// No description provided for @forgotPasswordSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get forgotPasswordSendCode;

  /// No description provided for @forgotPasswordCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'If that email is registered, a reset code has been sent to it. Check your inbox (and spam folder) and enter the code below along with your new password.'**
  String get forgotPasswordCheckEmail;

  /// No description provided for @forgotPasswordHaveCode.
  ///
  /// In en, this message translates to:
  /// **'I have a code'**
  String get forgotPasswordHaveCode;

  /// No description provided for @forgotPasswordResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get forgotPasswordResend;

  /// No description provided for @forgotPasswordCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Code from the email'**
  String get forgotPasswordCodeTitle;

  /// No description provided for @forgotPasswordCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get forgotPasswordCodeHint;

  /// No description provided for @forgotPasswordNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get forgotPasswordNewPasswordHint;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordDone.
  ///
  /// In en, this message translates to:
  /// **'Password changed. You can now sign in with your new password.'**
  String get forgotPasswordDone;

  /// No description provided for @lockScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'App is locked'**
  String get lockScreenTitle;

  /// No description provided for @lockScreenFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify — try again.'**
  String get lockScreenFailedHint;

  /// No description provided for @lockScreenPrompt.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to continue.'**
  String get lockScreenPrompt;

  /// No description provided for @lockScreenUnlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockScreenUnlockButton;

  /// No description provided for @lockScreenUsePassword.
  ///
  /// In en, this message translates to:
  /// **'Use password instead'**
  String get lockScreenUsePassword;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailPromptGeneric.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email at sign-up.'**
  String get verifyEmailPromptGeneric;

  /// No description provided for @verifyEmailPromptWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to {email}.'**
  String verifyEmailPromptWithEmail(Object email);

  /// No description provided for @verifyEmailCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Code from the email'**
  String get verifyEmailCodeHint;

  /// No description provided for @verifyEmailResendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get verifyEmailResendButton;

  /// No description provided for @verifyEmailSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyEmailSubmitButton;

  /// No description provided for @verifyEmailResentMessage.
  ///
  /// In en, this message translates to:
  /// **'Code resent — check your inbox.'**
  String get verifyEmailResentMessage;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeLabel;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsBackgroundColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get settingsBackgroundColorLabel;

  /// No description provided for @settingsSectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE'**
  String get settingsSectionPerformance;

  /// No description provided for @settingsPerformanceModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Battery saver mode'**
  String get settingsPerformanceModeLabel;

  /// No description provided for @settingsPerformanceModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Turns off the animated background and glass blur throughout the app. Worth enabling if your phone is weak, laggy, or overheating — most devices don\'t need this.'**
  String get settingsPerformanceModeDescription;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSoundOnMessage.
  ///
  /// In en, this message translates to:
  /// **'Sound on new message'**
  String get settingsSoundOnMessage;

  /// No description provided for @settingsVibrationOnMessage.
  ///
  /// In en, this message translates to:
  /// **'Vibration on new message'**
  String get settingsVibrationOnMessage;

  /// No description provided for @settingsSectionVoice.
  ///
  /// In en, this message translates to:
  /// **'VOICE'**
  String get settingsSectionVoice;

  /// No description provided for @settingsVoiceButtonsInChat.
  ///
  /// In en, this message translates to:
  /// **'Voice buttons in chat'**
  String get settingsVoiceButtonsInChat;

  /// No description provided for @settingsVoiceAndSpeechRecognition.
  ///
  /// In en, this message translates to:
  /// **'Voice selection and speech recognition'**
  String get settingsVoiceAndSpeechRecognition;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsBiometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric sign-in'**
  String get settingsBiometricLogin;

  /// No description provided for @settingsBiometricNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Biometrics (Face ID/fingerprint) isn\'t set up on this device — enable it in your device settings if you\'d like to use it here.'**
  String get settingsBiometricNotSupported;

  /// No description provided for @settingsSectionReminders.
  ///
  /// In en, this message translates to:
  /// **'REMINDERS'**
  String get settingsSectionReminders;

  /// No description provided for @settingsReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'Once a day, at a time you choose (e.g. when you\'re usually home) — a gentle nudge to check in if you feel like talking.'**
  String get settingsReminderDescription;

  /// No description provided for @settingsDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsDailyReminder;

  /// No description provided for @settingsReminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get settingsReminderTimeLabel;

  /// No description provided for @settingsReminderPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications aren\'t allowed — enable them for this app in your device settings.'**
  String get settingsReminderPermissionDenied;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get settingsSectionAccount;

  /// No description provided for @settingsLogoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutButton;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settingsAppVersion;

  /// No description provided for @settingsModelInfo.
  ///
  /// In en, this message translates to:
  /// **'Default model: gemma4:e2b via local Ollama.'**
  String get settingsModelInfo;

  /// No description provided for @settingsSectionDangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get settingsSectionDangerZone;

  /// No description provided for @settingsDeleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccountButton;

  /// No description provided for @settingsDeleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsDeleteAccountDialogTitle;

  /// No description provided for @settingsDeleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This is irreversible: your account, support history, and usage stats will be permanently deleted. Chat history on this device will remain — it was never stored on the server, and you can delete it separately.'**
  String get settingsDeleteAccountWarning;

  /// No description provided for @settingsConfirmWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your password'**
  String get settingsConfirmWithPassword;

  /// No description provided for @settingsDeleteForeverButton.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get settingsDeleteForeverButton;

  /// No description provided for @chatNoSoundsUploaded.
  ///
  /// In en, this message translates to:
  /// **'No sounds uploaded yet — the admin hasn\'t added any.'**
  String get chatNoSoundsUploaded;

  /// No description provided for @chatStopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get chatStopButton;

  /// No description provided for @chatRoleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get chatRoleUser;

  /// No description provided for @chatRoleAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get chatRoleAi;

  /// No description provided for @chatMigraineLabel.
  ///
  /// In en, this message translates to:
  /// **'Migraine or heavy fatigue'**
  String get chatMigraineLabel;

  /// No description provided for @chatWhatDoYouNeedNow.
  ///
  /// In en, this message translates to:
  /// **'What do you need right now?'**
  String get chatWhatDoYouNeedNow;

  /// No description provided for @chatTakeTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a test'**
  String get chatTakeTestTitle;

  /// No description provided for @chatTakeTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A questionnaire — we\'ll discuss the result right here'**
  String get chatTakeTestSubtitle;

  /// No description provided for @chatWhichQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Which questionnaire?'**
  String get chatWhichQuestionnaire;

  /// No description provided for @chatPhq9Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Depression symptoms, 9 questions'**
  String get chatPhq9Subtitle;

  /// No description provided for @chatGad7Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Anxiety symptoms, 7 questions'**
  String get chatGad7Subtitle;

  /// No description provided for @chatAsrsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ADHD screening, 6 questions'**
  String get chatAsrsSubtitle;

  /// No description provided for @chatOtherTestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Other tests'**
  String get chatOtherTestsTitle;

  /// No description provided for @chatOtherTestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questionnaires created by the team'**
  String get chatOtherTestsSubtitle;

  /// No description provided for @chatCallHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Call in a real person for help?'**
  String get chatCallHelpTitle;

  /// No description provided for @chatCallHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'A doctor or specialist from the team will join. This isn\'t a substitute for emergency services — if the situation needs urgent medical help, call your local emergency number.'**
  String get chatCallHelpDescription;

  /// No description provided for @chatPrepareSummaryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Prepare a short summary of your conversation with the AI for the doctor (not the whole chat), so you don\'t have to explain everything again?'**
  String get chatPrepareSummaryQuestion;

  /// No description provided for @chatYesPrepareSummary.
  ///
  /// In en, this message translates to:
  /// **'Yes, prepare a summary'**
  String get chatYesPrepareSummary;

  /// No description provided for @chatNoDontShow.
  ///
  /// In en, this message translates to:
  /// **'No, don\'t show it'**
  String get chatNoDontShow;

  /// No description provided for @chatCallButton.
  ///
  /// In en, this message translates to:
  /// **'Call for help'**
  String get chatCallButton;

  /// No description provided for @chatCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get chatCloseTooltip;

  /// No description provided for @chatNewChatTitle.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatNewChatTitle;

  /// No description provided for @chatDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The AI can make mistakes. Double-check important information yourself.'**
  String get chatDisclaimer;

  /// No description provided for @chatVerifyEmailBanner.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get chatVerifyEmailBanner;

  /// No description provided for @chatMuteBackgroundSound.
  ///
  /// In en, this message translates to:
  /// **'Turn off background sound'**
  String get chatMuteBackgroundSound;

  /// No description provided for @chatUnmuteBackgroundSound.
  ///
  /// In en, this message translates to:
  /// **'Turn on background sound'**
  String get chatUnmuteBackgroundSound;

  /// No description provided for @chatMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get chatMenuTooltip;

  /// No description provided for @chatMenuProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get chatMenuProfile;

  /// No description provided for @chatMenuWellbeing.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing'**
  String get chatMenuWellbeing;

  /// No description provided for @chatMenuSleepMusic.
  ///
  /// In en, this message translates to:
  /// **'Sleep music'**
  String get chatMenuSleepMusic;

  /// No description provided for @chatMenuSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get chatMenuSubscription;

  /// No description provided for @chatMenuMyReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get chatMenuMyReports;

  /// No description provided for @chatMenuLiveHelp.
  ///
  /// In en, this message translates to:
  /// **'Live help'**
  String get chatMenuLiveHelp;

  /// No description provided for @chatMenuOperatorCabinet.
  ///
  /// In en, this message translates to:
  /// **'Operator dashboard'**
  String get chatMenuOperatorCabinet;

  /// No description provided for @chatMenuSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get chatMenuSupport;

  /// No description provided for @chatMenuBlog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get chatMenuBlog;

  /// No description provided for @chatSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Explain quantum physics in simple terms'**
  String get chatSuggestion1;

  /// No description provided for @chatSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Write a weekly workout plan'**
  String get chatSuggestion2;

  /// No description provided for @chatSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Help me name my project'**
  String get chatSuggestion3;

  /// No description provided for @chatSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'How do I improve my Dart code?'**
  String get chatSuggestion4;

  /// No description provided for @chatWhatCanIHelpWith.
  ///
  /// In en, this message translates to:
  /// **'What can I help with today?'**
  String get chatWhatCanIHelpWith;

  /// No description provided for @aiModeSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get aiModeSupportTitle;

  /// No description provided for @aiModeSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Just be there in the conversation'**
  String get aiModeSupportSubtitle;

  /// No description provided for @aiModeSupportOpener.
  ///
  /// In en, this message translates to:
  /// **'I need some support right now — just be here with me in the conversation and cheer me up.'**
  String get aiModeSupportOpener;

  /// No description provided for @aiModeListenTitle.
  ///
  /// In en, this message translates to:
  /// **'Just listen'**
  String get aiModeListenTitle;

  /// No description provided for @aiModeListenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No need to jump to advice'**
  String get aiModeListenSubtitle;

  /// No description provided for @aiModeListenOpener.
  ///
  /// In en, this message translates to:
  /// **'I just need to talk it out — listen, no need to give advice right away.'**
  String get aiModeListenOpener;

  /// No description provided for @aiModeBreakupTitle.
  ///
  /// In en, this message translates to:
  /// **'Divorce or breakup'**
  String get aiModeBreakupTitle;

  /// No description provided for @aiModeBreakupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation about it'**
  String get aiModeBreakupSubtitle;

  /// No description provided for @aiModeBreakupOpener.
  ///
  /// In en, this message translates to:
  /// **'I\'m going through a divorce or breakup right now, and it\'s hard to cope. Can you support me while I talk about it?'**
  String get aiModeBreakupOpener;

  /// No description provided for @aiModeGriefTitle.
  ///
  /// In en, this message translates to:
  /// **'Loss and grief'**
  String get aiModeGriefTitle;

  /// No description provided for @aiModeGriefSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation about it'**
  String get aiModeGriefSubtitle;

  /// No description provided for @aiModeGriefOpener.
  ///
  /// In en, this message translates to:
  /// **'I recently lost someone close to me, and I\'d like to talk to someone about it.'**
  String get aiModeGriefOpener;

  /// No description provided for @aiModeJobLossTitle.
  ///
  /// In en, this message translates to:
  /// **'Job loss or major life change'**
  String get aiModeJobLossTitle;

  /// No description provided for @aiModeJobLossSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation about it'**
  String get aiModeJobLossSubtitle;

  /// No description provided for @aiModeJobLossOpener.
  ///
  /// In en, this message translates to:
  /// **'I\'m going through a tough time — I lost my job or a sudden change happened in my life, and it\'s hard to deal with. Can you support me while I talk about it?'**
  String get aiModeJobLossOpener;

  /// No description provided for @aiModeRationalizerTitle.
  ///
  /// In en, this message translates to:
  /// **'Thought checker'**
  String get aiModeRationalizerTitle;

  /// No description provided for @aiModeRationalizerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Break down an anxious thought using CBT'**
  String get aiModeRationalizerSubtitle;

  /// No description provided for @aiModeRationalizerOpener.
  ///
  /// In en, this message translates to:
  /// **'I have an anxious thought that won\'t leave me alone. Help me break it down using CBT — ask me guiding questions one at a time (for example, what evidence supports this thought, what\'s the worst that could happen and how likely is it) so I can see the situation more clearly.'**
  String get aiModeRationalizerOpener;

  /// No description provided for @profileBirthDateHelpText.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileBirthDateHelpText;

  /// No description provided for @profileAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{age, plural, one {{age} year} other {{age} years}}'**
  String profileAgeYears(num age);

  /// No description provided for @profileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profileTakePhoto;

  /// No description provided for @profileChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profileChooseFromGallery;

  /// No description provided for @profileDeletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get profileDeletePhoto;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get profileNoData;

  /// No description provided for @profileSectionPersonal.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL'**
  String get profileSectionPersonal;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullName;

  /// No description provided for @profileNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'not specified'**
  String get profileNotSpecified;

  /// No description provided for @profileBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileBirthDate;

  /// No description provided for @profileHobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get profileHobbies;

  /// No description provided for @profileEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get profileEmergencyContact;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get profileSectionAccount;

  /// No description provided for @profileRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRole;

  /// No description provided for @profileRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get profileRoleAdmin;

  /// No description provided for @profileRoleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileRoleUser;

  /// No description provided for @profileAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get profileAccountCreated;

  /// No description provided for @profileEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditButton;

  /// No description provided for @profileChangePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePasswordButton;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get profileEditTitle;

  /// No description provided for @profileEditHint.
  ///
  /// In en, this message translates to:
  /// **'All fields are optional — leave blank to clear.'**
  String get profileEditHint;

  /// No description provided for @profileEmergencySectionLabel.
  ///
  /// In en, this message translates to:
  /// **'IN CASE OF EMERGENCY'**
  String get profileEmergencySectionLabel;

  /// No description provided for @profileEmergencyContactHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: Mom, +1 555 123-4567'**
  String get profileEmergencyContactHint;

  /// No description provided for @profileLogoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogoutButton;

  /// No description provided for @profilePasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 8 characters.'**
  String get profilePasswordTooShort;

  /// No description provided for @profilePasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get profilePasswordsMismatch;

  /// No description provided for @profileChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePasswordTitle;

  /// No description provided for @profileCurrentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profileCurrentPasswordLabel;

  /// No description provided for @profileNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profileNewPasswordLabel;

  /// No description provided for @profileRepeatNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get profileRepeatNewPasswordLabel;

  /// No description provided for @profileChangeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get profileChangeEmailTitle;

  /// No description provided for @profileCurrentEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Current: {email}'**
  String profileCurrentEmailLabel(Object email);

  /// No description provided for @profileNewEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'New address'**
  String get profileNewEmailLabel;

  /// No description provided for @profileCodeSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}. Enter it below to complete the change.'**
  String profileCodeSentMessage(Object email);

  /// No description provided for @profileCodeFromEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Code from the email'**
  String get profileCodeFromEmailLabel;

  /// No description provided for @profileSendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get profileSendCodeButton;

  /// No description provided for @sidebarCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get sidebarCalendarTitle;

  /// No description provided for @sidebarCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire results by day'**
  String get sidebarCalendarSubtitle;

  /// No description provided for @sidebarWellbeingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a test, situational support'**
  String get sidebarWellbeingSubtitle;

  /// No description provided for @sidebarCallHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Call for help'**
  String get sidebarCallHelpTitle;

  /// No description provided for @sidebarCallHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A doctor or specialist will join'**
  String get sidebarCallHelpSubtitle;

  /// No description provided for @sidebarHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get sidebarHistoryLabel;

  /// No description provided for @sidebarNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get sidebarNoConversations;

  /// No description provided for @sidebarRenameChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename chat'**
  String get sidebarRenameChatTitle;

  /// No description provided for @sidebarDeleteChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chat?'**
  String get sidebarDeleteChatTitle;

  /// No description provided for @sidebarDeleteChatBody.
  ///
  /// In en, this message translates to:
  /// **'The conversation \"{title}\" will be deleted permanently.'**
  String sidebarDeleteChatBody(Object title);

  /// No description provided for @sidebarEmptyConversation.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get sidebarEmptyConversation;

  /// No description provided for @crisisResourcesDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'If you feel like talking to someone'**
  String get crisisResourcesDefaultTitle;

  /// No description provided for @crisisResourcesBody.
  ///
  /// In en, this message translates to:
  /// **'• Emergency psychological support for adults and children in Russia, 24/7 and free: 8-800-100-49-94\n• Child and teen helpline (Russia): 8-800-2000-122 (short number: 124)\n\nIf you\'re not in Russia, search for a local crisis line for your country; in the US and Canada you can call or text 988.'**
  String get crisisResourcesBody;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get navSleep;

  /// No description provided for @navWellbeing.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get navWellbeing;

  /// No description provided for @sleepMusicTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep music'**
  String get sleepMusicTitle;

  /// No description provided for @sleepMusicNoneUploaded.
  ///
  /// In en, this message translates to:
  /// **'No music uploaded yet — the admin hasn\'t added any.'**
  String get sleepMusicNoneUploaded;

  /// No description provided for @customTestListTitle.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get customTestListTitle;

  /// No description provided for @customTestListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tests available yet.'**
  String get customTestListEmpty;

  /// No description provided for @blogTitle.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blogTitle;

  /// No description provided for @blogListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts yet — check back later.'**
  String get blogListEmpty;

  /// No description provided for @who5Q1.
  ///
  /// In en, this message translates to:
  /// **'I have felt cheerful and in good spirits'**
  String get who5Q1;

  /// No description provided for @who5Q2.
  ///
  /// In en, this message translates to:
  /// **'I have felt calm and relaxed'**
  String get who5Q2;

  /// No description provided for @who5Q3.
  ///
  /// In en, this message translates to:
  /// **'I have felt active and vigorous'**
  String get who5Q3;

  /// No description provided for @who5Q4.
  ///
  /// In en, this message translates to:
  /// **'I woke up feeling fresh and rested'**
  String get who5Q4;

  /// No description provided for @who5Q5.
  ///
  /// In en, this message translates to:
  /// **'My daily life has been filled with things that interest me'**
  String get who5Q5;

  /// No description provided for @who5ScaleAllTime.
  ///
  /// In en, this message translates to:
  /// **'All of the time'**
  String get who5ScaleAllTime;

  /// No description provided for @who5ScaleMostTime.
  ///
  /// In en, this message translates to:
  /// **'Most of the time'**
  String get who5ScaleMostTime;

  /// No description provided for @who5ScaleMoreThanHalf.
  ///
  /// In en, this message translates to:
  /// **'More than half of the time'**
  String get who5ScaleMoreThanHalf;

  /// No description provided for @who5ScaleLessThanHalf.
  ///
  /// In en, this message translates to:
  /// **'Less than half of the time'**
  String get who5ScaleLessThanHalf;

  /// No description provided for @who5ScaleSomeTime.
  ///
  /// In en, this message translates to:
  /// **'Some of the time'**
  String get who5ScaleSomeTime;

  /// No description provided for @who5ScaleNever.
  ///
  /// In en, this message translates to:
  /// **'At no time'**
  String get who5ScaleNever;

  /// No description provided for @wellbeingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the result locally. You can take it again.'**
  String get wellbeingSaveFailed;

  /// No description provided for @wellbeingToolsSection.
  ///
  /// In en, this message translates to:
  /// **'TOOLS'**
  String get wellbeingToolsSection;

  /// No description provided for @wellbeingBreathingTitle.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get wellbeingBreathingTitle;

  /// No description provided for @wellbeingGroundingTitle.
  ///
  /// In en, this message translates to:
  /// **'Grounding'**
  String get wellbeingGroundingTitle;

  /// No description provided for @wellbeingGratitudeTitle.
  ///
  /// In en, this message translates to:
  /// **'Gratitude'**
  String get wellbeingGratitudeTitle;

  /// No description provided for @wellbeingGratitudeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get wellbeingGratitudeSubtitle;

  /// No description provided for @wellbeingBilateralTitle.
  ///
  /// In en, this message translates to:
  /// **'Bilateral stimulation'**
  String get wellbeingBilateralTitle;

  /// No description provided for @wellbeingBilateralSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Eye tracking'**
  String get wellbeingBilateralSubtitle;

  /// No description provided for @wellbeingMuscleRelaxationTitle.
  ///
  /// In en, this message translates to:
  /// **'Muscle relaxation'**
  String get wellbeingMuscleRelaxationTitle;

  /// No description provided for @wellbeingMuscleRelaxationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tense/release'**
  String get wellbeingMuscleRelaxationSubtitle;

  /// No description provided for @wellbeingSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get wellbeingSafeTitle;

  /// No description provided for @wellbeingSafeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a thought aside'**
  String get wellbeingSafeSubtitle;

  /// No description provided for @wellbeingLeavesTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaves on a stream'**
  String get wellbeingLeavesTitle;

  /// No description provided for @wellbeingLeavesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let a thought go'**
  String get wellbeingLeavesSubtitle;

  /// No description provided for @wellbeingFreewritingTitle.
  ///
  /// In en, this message translates to:
  /// **'Freewriting'**
  String get wellbeingFreewritingTitle;

  /// No description provided for @wellbeingFreewritingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unload your thoughts'**
  String get wellbeingFreewritingSubtitle;

  /// No description provided for @wellbeingQuestionnairesSection.
  ///
  /// In en, this message translates to:
  /// **'QUESTIONNAIRES'**
  String get wellbeingQuestionnairesSection;

  /// No description provided for @wellbeingQuestionnairesDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Official, freely distributed tools. Not a diagnosis — just self-screening.'**
  String get wellbeingQuestionnairesDisclaimer;

  /// No description provided for @who5CardTitle.
  ///
  /// In en, this message translates to:
  /// **'WHO-5 — general wellbeing'**
  String get who5CardTitle;

  /// No description provided for @wellbeingReleaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Let go'**
  String get wellbeingReleaseTitle;

  /// No description provided for @wellbeingReleaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write down a heavy thought and burn/smash it'**
  String get wellbeingReleaseSubtitle;

  /// No description provided for @wellbeingSleepMusicTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep music'**
  String get wellbeingSleepMusicTitle;

  /// No description provided for @wellbeingSleepMusicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calm sounds before bed'**
  String get wellbeingSleepMusicSubtitle;

  /// No description provided for @who5HistorySection.
  ///
  /// In en, this message translates to:
  /// **'WHO-5 HISTORY'**
  String get who5HistorySection;

  /// No description provided for @who5Instructions.
  ///
  /// In en, this message translates to:
  /// **'Mark what\'s closest to how you\'ve felt over the last two weeks.'**
  String get who5Instructions;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @who5ShowResult.
  ///
  /// In en, this message translates to:
  /// **'Show result'**
  String get who5ShowResult;

  /// No description provided for @who5ResultLow.
  ///
  /// In en, this message translates to:
  /// **'Below-average score'**
  String get who5ResultLow;

  /// No description provided for @who5ResultNormal.
  ///
  /// In en, this message translates to:
  /// **'Score within the normal range'**
  String get who5ResultNormal;

  /// No description provided for @who5DescriptionLow.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a diagnosis. Under the WHO method, a score below 50% is a reason to see a specialist for a more accurate assessment, especially if this has continued for more than two weeks.'**
  String get who5DescriptionLow;

  /// No description provided for @who5DescriptionNormal.
  ///
  /// In en, this message translates to:
  /// **'The official WHO method considers this result a sign of normal psychological wellbeing over the last two weeks.'**
  String get who5DescriptionNormal;

  /// No description provided for @who5DiscussPrompt.
  ///
  /// In en, this message translates to:
  /// **'I took the WHO-5 well-being questionnaire: {result}. Can you comment on the result and support me?'**
  String who5DiscussPrompt(Object result);

  /// No description provided for @who5DiscussButton.
  ///
  /// In en, this message translates to:
  /// **'Discuss with AI'**
  String get who5DiscussButton;

  /// No description provided for @who5BackToHistory.
  ///
  /// In en, this message translates to:
  /// **'Back to history'**
  String get who5BackToHistory;

  /// No description provided for @wellbeingAiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The AI and automatic scoring can make mistakes. This questionnaire is a self-monitoring tool, not a diagnosis. For an accurate assessment of your psychological state, see a doctor or therapist.'**
  String get wellbeingAiDisclaimer;

  /// No description provided for @who5LicenseAttribution.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire: World Health Organization-Five Well-Being Index (WHO-5), © World Health Organization 2024, licensed under CC BY-NC-SA 3.0 IGO. WHO endorsement of this application is not implied.'**
  String get who5LicenseAttribution;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
