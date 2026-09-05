// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Glass Chat';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Error';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLogout => 'Log out';

  @override
  String get authSignInTitle => 'Sign in to AI Chat';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authRepeatPasswordHint => 'Repeat password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authRegisterButton => 'Sign up';

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authNoAccount => 'No account? Sign up';

  @override
  String get authPasswordLengthOk => 'Password length is fine';

  @override
  String authPasswordLengthHint(Object length, Object minLength) {
    return 'At least $minLength characters ($length entered)';
  }

  @override
  String get authPasswordsMatch => 'Passwords match';

  @override
  String get authPasswordsMismatch => 'Passwords don\'t match';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordEmailPrompt => 'Enter the email your account is registered with — we\'ll send a reset code.';

  @override
  String get forgotPasswordSendCode => 'Send code';

  @override
  String get forgotPasswordCheckEmail => 'If that email is registered, a reset code has been sent to it. Check your inbox (and spam folder) and enter the code below along with your new password.';

  @override
  String get forgotPasswordHaveCode => 'I have a code';

  @override
  String get forgotPasswordResend => 'Resend';

  @override
  String get forgotPasswordCodeTitle => 'Code from the email';

  @override
  String get forgotPasswordCodeHint => 'Code';

  @override
  String get forgotPasswordNewPasswordHint => 'New password';

  @override
  String get forgotPasswordSubmit => 'Change password';

  @override
  String get forgotPasswordDone => 'Password changed. You can now sign in with your new password.';

  @override
  String get lockScreenTitle => 'App is locked';

  @override
  String get lockScreenFailedHint => 'Couldn\'t verify — try again.';

  @override
  String get lockScreenPrompt => 'Verify your identity to continue.';

  @override
  String get lockScreenUnlockButton => 'Unlock';

  @override
  String get lockScreenUsePassword => 'Use password instead';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get verifyEmailPromptGeneric => 'Enter the code sent to your email at sign-up.';

  @override
  String verifyEmailPromptWithEmail(Object email) {
    return 'Enter the code sent to $email.';
  }

  @override
  String get verifyEmailCodeHint => 'Code from the email';

  @override
  String get verifyEmailResendButton => 'Resend code';

  @override
  String get verifyEmailSubmitButton => 'Verify';

  @override
  String get verifyEmailResentMessage => 'Code resent — check your inbox.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsBackgroundColorLabel => 'Background color';

  @override
  String get settingsSectionPerformance => 'PERFORMANCE';

  @override
  String get settingsPerformanceModeLabel => 'Battery saver mode';

  @override
  String get settingsPerformanceModeDescription => 'Turns off the animated background and glass blur throughout the app. Worth enabling if your phone is weak, laggy, or overheating — most devices don\'t need this.';

  @override
  String get settingsSectionNotifications => 'NOTIFICATIONS';

  @override
  String get settingsSoundOnMessage => 'Sound on new message';

  @override
  String get settingsVibrationOnMessage => 'Vibration on new message';

  @override
  String get settingsSectionVoice => 'VOICE';

  @override
  String get settingsVoiceButtonsInChat => 'Voice buttons in chat';

  @override
  String get settingsVoiceAndSpeechRecognition => 'Voice selection and speech recognition';

  @override
  String get settingsSectionSecurity => 'SECURITY';

  @override
  String get settingsBiometricLogin => 'Biometric sign-in';

  @override
  String get settingsBiometricNotSupported => 'Biometrics (Face ID/fingerprint) isn\'t set up on this device — enable it in your device settings if you\'d like to use it here.';

  @override
  String get settingsSectionReminders => 'REMINDERS';

  @override
  String get settingsReminderDescription => 'Once a day, at a time you choose (e.g. when you\'re usually home) — a gentle nudge to check in if you feel like talking.';

  @override
  String get settingsDailyReminder => 'Daily reminder';

  @override
  String get settingsReminderTimeLabel => 'Time';

  @override
  String get settingsReminderPermissionDenied => 'Notifications aren\'t allowed — enable them for this app in your device settings.';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get settingsLogoutButton => 'Log out';

  @override
  String get settingsSectionAbout => 'ABOUT';

  @override
  String get settingsAppVersion => 'Version 1.0.0';

  @override
  String get settingsModelInfo => 'Default model: gemma4:e2b via local Ollama.';

  @override
  String get settingsSectionDangerZone => 'DANGER ZONE';

  @override
  String get settingsDeleteAccountButton => 'Delete account';

  @override
  String get settingsDeleteAccountDialogTitle => 'Delete account?';

  @override
  String get settingsDeleteAccountWarning => 'This is irreversible: your account, support history, and usage stats will be permanently deleted. Chat history on this device will remain — it was never stored on the server, and you can delete it separately.';

  @override
  String get settingsConfirmWithPassword => 'Confirm with your password';

  @override
  String get settingsDeleteForeverButton => 'Delete forever';

  @override
  String get chatNoSoundsUploaded => 'No sounds uploaded yet — the admin hasn\'t added any.';

  @override
  String get chatStopButton => 'Stop';

  @override
  String get chatRoleUser => 'User';

  @override
  String get chatRoleAi => 'AI';

  @override
  String get chatMigraineLabel => 'Migraine or heavy fatigue';

  @override
  String get chatWhatDoYouNeedNow => 'What do you need right now?';

  @override
  String get chatTakeTestTitle => 'Take a test';

  @override
  String get chatTakeTestSubtitle => 'A questionnaire — we\'ll discuss the result right here';

  @override
  String get chatWhichQuestionnaire => 'Which questionnaire?';

  @override
  String get chatPhq9Subtitle => 'Depression symptoms, 9 questions';

  @override
  String get chatGad7Subtitle => 'Anxiety symptoms, 7 questions';

  @override
  String get chatAsrsSubtitle => 'ADHD screening, 6 questions';

  @override
  String get chatOtherTestsTitle => 'Other tests';

  @override
  String get chatOtherTestsSubtitle => 'Questionnaires created by the team';

  @override
  String get chatCallHelpTitle => 'Call in a real person for help?';

  @override
  String get chatCallHelpDescription => 'A doctor or specialist from the team will join. This isn\'t a substitute for emergency services — if the situation needs urgent medical help, call your local emergency number.';

  @override
  String get chatPrepareSummaryQuestion => 'Prepare a short summary of your conversation with the AI for the doctor (not the whole chat), so you don\'t have to explain everything again?';

  @override
  String get chatYesPrepareSummary => 'Yes, prepare a summary';

  @override
  String get chatNoDontShow => 'No, don\'t show it';

  @override
  String get chatCallButton => 'Call for help';

  @override
  String get chatCloseTooltip => 'Close';

  @override
  String get chatNewChatTitle => 'New chat';

  @override
  String get chatDisclaimer => 'The AI can make mistakes. Double-check important information yourself.';

  @override
  String get chatVerifyEmailBanner => 'Verify your email';

  @override
  String get chatMuteBackgroundSound => 'Turn off background sound';

  @override
  String get chatUnmuteBackgroundSound => 'Turn on background sound';

  @override
  String get chatMenuTooltip => 'Menu';

  @override
  String get chatMenuProfile => 'Profile';

  @override
  String get chatMenuWellbeing => 'Wellbeing';

  @override
  String get chatMenuSleepMusic => 'Sleep music';

  @override
  String get chatMenuSubscription => 'Subscription';

  @override
  String get chatMenuMyReports => 'My reports';

  @override
  String get chatMenuLiveHelp => 'Live help';

  @override
  String get chatMenuOperatorCabinet => 'Operator dashboard';

  @override
  String get chatMenuSupport => 'Support';

  @override
  String get chatMenuBlog => 'Blog';

  @override
  String get chatSuggestion1 => 'Explain quantum physics in simple terms';

  @override
  String get chatSuggestion2 => 'Write a weekly workout plan';

  @override
  String get chatSuggestion3 => 'Help me name my project';

  @override
  String get chatSuggestion4 => 'How do I improve my Dart code?';

  @override
  String get chatWhatCanIHelpWith => 'What can I help with today?';

  @override
  String get aiModeSupportTitle => 'Support';

  @override
  String get aiModeSupportSubtitle => 'Just be there in the conversation';

  @override
  String get aiModeSupportOpener => 'I need some support right now — just be here with me in the conversation and cheer me up.';

  @override
  String get aiModeListenTitle => 'Just listen';

  @override
  String get aiModeListenSubtitle => 'No need to jump to advice';

  @override
  String get aiModeListenOpener => 'I just need to talk it out — listen, no need to give advice right away.';

  @override
  String get aiModeBreakupTitle => 'Divorce or breakup';

  @override
  String get aiModeBreakupSubtitle => 'Start a conversation about it';

  @override
  String get aiModeBreakupOpener => 'I\'m going through a divorce or breakup right now, and it\'s hard to cope. Can you support me while I talk about it?';

  @override
  String get aiModeGriefTitle => 'Loss and grief';

  @override
  String get aiModeGriefSubtitle => 'Start a conversation about it';

  @override
  String get aiModeGriefOpener => 'I recently lost someone close to me, and I\'d like to talk to someone about it.';

  @override
  String get aiModeJobLossTitle => 'Job loss or major life change';

  @override
  String get aiModeJobLossSubtitle => 'Start a conversation about it';

  @override
  String get aiModeJobLossOpener => 'I\'m going through a tough time — I lost my job or a sudden change happened in my life, and it\'s hard to deal with. Can you support me while I talk about it?';

  @override
  String get aiModeRationalizerTitle => 'Thought checker';

  @override
  String get aiModeRationalizerSubtitle => 'Break down an anxious thought using CBT';

  @override
  String get aiModeRationalizerOpener => 'I have an anxious thought that won\'t leave me alone. Help me break it down using CBT — ask me guiding questions one at a time (for example, what evidence supports this thought, what\'s the worst that could happen and how likely is it) so I can see the situation more clearly.';

  @override
  String get profileBirthDateHelpText => 'Date of birth';

  @override
  String profileAgeYears(num age) {
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age years',
      one: '$age year',
    );
    return '$_temp0';
  }

  @override
  String get profileTakePhoto => 'Take a photo';

  @override
  String get profileChooseFromGallery => 'Choose from gallery';

  @override
  String get profileDeletePhoto => 'Delete photo';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileNoData => 'No data';

  @override
  String get profileSectionPersonal => 'PERSONAL';

  @override
  String get profileFullName => 'Full name';

  @override
  String get profileNotSpecified => 'not specified';

  @override
  String get profileBirthDate => 'Date of birth';

  @override
  String get profileHobbies => 'Hobbies';

  @override
  String get profileEmergencyContact => 'Emergency contact';

  @override
  String get profileSectionAccount => 'ACCOUNT';

  @override
  String get profileRole => 'Role';

  @override
  String get profileRoleAdmin => 'Administrator';

  @override
  String get profileRoleUser => 'User';

  @override
  String get profileAccountCreated => 'Account created';

  @override
  String get profileEditButton => 'Edit profile';

  @override
  String get profileChangePasswordButton => 'Change password';

  @override
  String get profileEditTitle => 'Personal details';

  @override
  String get profileEditHint => 'All fields are optional — leave blank to clear.';

  @override
  String get profileEmergencySectionLabel => 'IN CASE OF EMERGENCY';

  @override
  String get profileEmergencyContactHint => 'E.g.: Mom, +1 555 123-4567';

  @override
  String get profileLogoutButton => 'Log out';

  @override
  String get profilePasswordTooShort => 'New password must be at least 8 characters.';

  @override
  String get profilePasswordsMismatch => 'Passwords don\'t match.';

  @override
  String get profileChangePasswordTitle => 'Change password';

  @override
  String get profileCurrentPasswordLabel => 'Current password';

  @override
  String get profileNewPasswordLabel => 'New password';

  @override
  String get profileRepeatNewPasswordLabel => 'Repeat new password';

  @override
  String get profileChangeEmailTitle => 'Change email';

  @override
  String profileCurrentEmailLabel(Object email) {
    return 'Current: $email';
  }

  @override
  String get profileNewEmailLabel => 'New address';

  @override
  String profileCodeSentMessage(Object email) {
    return 'Code sent to $email. Enter it below to complete the change.';
  }

  @override
  String get profileCodeFromEmailLabel => 'Code from the email';

  @override
  String get profileSendCodeButton => 'Send code';

  @override
  String get sidebarCalendarTitle => 'Calendar';

  @override
  String get sidebarCalendarSubtitle => 'Questionnaire results by day';

  @override
  String get sidebarWellbeingSubtitle => 'Take a test, situational support';

  @override
  String get sidebarCallHelpTitle => 'Call for help';

  @override
  String get sidebarCallHelpSubtitle => 'A doctor or specialist will join';

  @override
  String get sidebarHistoryLabel => 'HISTORY';

  @override
  String get sidebarNoConversations => 'No conversations yet';

  @override
  String get sidebarRenameChatTitle => 'Rename chat';

  @override
  String get sidebarDeleteChatTitle => 'Delete chat?';

  @override
  String sidebarDeleteChatBody(Object title) {
    return 'The conversation \"$title\" will be deleted permanently.';
  }

  @override
  String get sidebarEmptyConversation => 'Empty';

  @override
  String get crisisResourcesDefaultTitle => 'If you feel like talking to someone';

  @override
  String get crisisResourcesBody => '• Emergency psychological support for adults and children in Russia, 24/7 and free: 8-800-100-49-94\n• Child and teen helpline (Russia): 8-800-2000-122 (short number: 124)\n\nIf you\'re not in Russia, search for a local crisis line for your country; in the US and Canada you can call or text 988.';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSleep => 'Sleep';

  @override
  String get navWellbeing => 'Care';

  @override
  String get sleepMusicTitle => 'Sleep music';

  @override
  String get sleepMusicNoneUploaded => 'No music uploaded yet — the admin hasn\'t added any.';

  @override
  String get customTestListTitle => 'Tests';

  @override
  String get customTestListEmpty => 'No tests available yet.';

  @override
  String get blogTitle => 'Blog';

  @override
  String get blogListEmpty => 'No posts yet — check back later.';

  @override
  String get who5Q1 => 'I have felt cheerful and in good spirits';

  @override
  String get who5Q2 => 'I have felt calm and relaxed';

  @override
  String get who5Q3 => 'I have felt active and vigorous';

  @override
  String get who5Q4 => 'I woke up feeling fresh and rested';

  @override
  String get who5Q5 => 'My daily life has been filled with things that interest me';

  @override
  String get who5ScaleAllTime => 'All of the time';

  @override
  String get who5ScaleMostTime => 'Most of the time';

  @override
  String get who5ScaleMoreThanHalf => 'More than half of the time';

  @override
  String get who5ScaleLessThanHalf => 'Less than half of the time';

  @override
  String get who5ScaleSomeTime => 'Some of the time';

  @override
  String get who5ScaleNever => 'At no time';

  @override
  String get wellbeingSaveFailed => 'Couldn\'t save the result locally. You can take it again.';

  @override
  String get wellbeingToolsSection => 'TOOLS';

  @override
  String get wellbeingBreathingTitle => 'Breathing';

  @override
  String get wellbeingGroundingTitle => 'Grounding';

  @override
  String get wellbeingGratitudeTitle => 'Gratitude';

  @override
  String get wellbeingGratitudeSubtitle => 'Journal';

  @override
  String get wellbeingBilateralTitle => 'Bilateral stimulation';

  @override
  String get wellbeingBilateralSubtitle => 'Eye tracking';

  @override
  String get wellbeingMuscleRelaxationTitle => 'Muscle relaxation';

  @override
  String get wellbeingMuscleRelaxationSubtitle => 'Tense/release';

  @override
  String get wellbeingSafeTitle => 'Safe';

  @override
  String get wellbeingSafeSubtitle => 'Set a thought aside';

  @override
  String get wellbeingLeavesTitle => 'Leaves on a stream';

  @override
  String get wellbeingLeavesSubtitle => 'Let a thought go';

  @override
  String get wellbeingFreewritingTitle => 'Freewriting';

  @override
  String get wellbeingFreewritingSubtitle => 'Unload your thoughts';

  @override
  String get wellbeingQuestionnairesSection => 'QUESTIONNAIRES';

  @override
  String get wellbeingQuestionnairesDisclaimer => 'Official, freely distributed tools. Not a diagnosis — just self-screening.';

  @override
  String get who5CardTitle => 'WHO-5 — general wellbeing';

  @override
  String get wellbeingReleaseTitle => 'Let go';

  @override
  String get wellbeingReleaseSubtitle => 'Write down a heavy thought and burn/smash it';

  @override
  String get wellbeingSleepMusicTitle => 'Sleep music';

  @override
  String get wellbeingSleepMusicSubtitle => 'Calm sounds before bed';

  @override
  String get who5HistorySection => 'WHO-5 HISTORY';

  @override
  String get who5Instructions => 'Mark what\'s closest to how you\'ve felt over the last two weeks.';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get who5ShowResult => 'Show result';

  @override
  String get who5ResultLow => 'Below-average score';

  @override
  String get who5ResultNormal => 'Score within the normal range';

  @override
  String get who5DescriptionLow => 'This isn\'t a diagnosis. Under the WHO method, a score below 50% is a reason to see a specialist for a more accurate assessment, especially if this has continued for more than two weeks.';

  @override
  String get who5DescriptionNormal => 'The official WHO method considers this result a sign of normal psychological wellbeing over the last two weeks.';

  @override
  String who5DiscussPrompt(Object result) {
    return 'I took the WHO-5 well-being questionnaire: $result. Can you comment on the result and support me?';
  }

  @override
  String get who5DiscussButton => 'Discuss with AI';

  @override
  String get who5BackToHistory => 'Back to history';

  @override
  String get wellbeingAiDisclaimer => 'The AI and automatic scoring can make mistakes. This questionnaire is a self-monitoring tool, not a diagnosis. For an accurate assessment of your psychological state, see a doctor or therapist.';

  @override
  String get who5LicenseAttribution => 'Questionnaire: World Health Organization-Five Well-Being Index (WHO-5), © World Health Organization 2024, licensed under CC BY-NC-SA 3.0 IGO. WHO endorsement of this application is not implied.';
}
