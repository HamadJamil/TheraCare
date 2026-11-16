// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get activationTitle => 'Activate TheraCare';

  @override
  String get activationBody =>
      'Your health insurer gave you a 12-character activation code. Enter it to unlock your therapy.';

  @override
  String get activationCode => 'Activation code';

  @override
  String get activationCodeHelp => 'For example ABCD-EFGH-JKLM. You can paste it. Upper or lower case does not matter.';

  @override
  String get activationCodeLength => 'The code has 12 letters and numbers. Please check it.';

  @override
  String get activate => 'Activate';

  @override
  String get privacyTitle => 'Your privacy';

  @override
  String get privacyIntro =>
      'Before you start, please read what happens with your data. You decide about each point separately.';

  @override
  String get consentRequired => 'Needed for the therapy';

  @override
  String get consentOptional => 'Optional – your therapy works without it';

  @override
  String get readDetails => 'Read the details';

  @override
  String get consentAgree => 'I have read this and I agree';

  @override
  String get consentYesOptional => 'Yes, I allow this';

  @override
  String get consentNoOptional => 'No, thank you';

  @override
  String get privacyRequiredHint => 'To use the therapy, please agree to the points marked \"Needed for the therapy\".';

  @override
  String get saveMyChoices => 'Save my choices';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get welcomeTitle => 'Your back, step by step';

  @override
  String get welcomeBody =>
      'TheraCare guides you through gentle exercises and helps you keep track of how your back feels. Everything is explained in plain language.';

  @override
  String get email => 'Email address';

  @override
  String get emailHelp => 'We send you a confirmation code to this address.';

  @override
  String get password => 'Password';

  @override
  String get passwordRules => 'At least 10 characters. A short sentence is easy to remember.';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccountYet => 'No account yet? Create one';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get registerIntro => 'We only ask for what is needed to set up your account.';

  @override
  String get validationEmail => 'Enter a valid email address, for example name@example.com.';

  @override
  String get validationPassword => 'Use at least 10 characters.';

  @override
  String get validationRequired => 'Please fill in this field.';

  @override
  String get validationCode => 'Enter the 6-digit code from the email.';

  @override
  String get verifyTitle => 'Confirm your email';

  @override
  String get verifyBody =>
      'We sent a 6-digit code to your email address. Enter it below. The code is valid for 30 minutes.';

  @override
  String get verificationCode => 'Confirmation code';

  @override
  String get verificationCodeHelp => '6 digits, for example 123456';

  @override
  String get confirmEmail => 'Confirm email';

  @override
  String get sendNewCode => 'Send a new code';

  @override
  String get codeResent => 'If the address can be used, a new code is on its way.';

  @override
  String get forgotPasswordBody => 'Enter your email address. We will send you a code to choose a new password.';

  @override
  String get sendResetCode => 'Send reset code';

  @override
  String get resetPassword => 'Choose a new password';

  @override
  String get resetPasswordBody =>
      'Enter the code from the email and your new password. For your safety you will be signed out on all devices.';

  @override
  String get resetCode => 'Reset code';

  @override
  String get resetCodeHelp => '12 characters, for example ABCD-EFGH-JKLM';

  @override
  String get newPassword => 'New password';

  @override
  String get saveNewPassword => 'Save new password';

  @override
  String get passwordChanged => 'Your password has been changed. Please sign in with your new password.';

  @override
  String get appName => 'TheraCare';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get loading => 'Loading…';

  @override
  String get errorTitle => 'Something did not work';

  @override
  String get tryAgain => 'Try again';

  @override
  String scaleValue(int value, int max) {
    return '$value of $max';
  }

  @override
  String get errorGeneric => 'Something went wrong. Your saved data is safe. Please try again.';

  @override
  String get errorNetwork => 'No internet connection. Your entries are kept on this device and sent later.';

  @override
  String get errorInvalidCredentials => 'The email address or password is not correct.';

  @override
  String get errorEmailNotVerified => 'Please confirm your email address. We sent you a new code.';

  @override
  String get errorInvalidCode => 'This code is not correct or has expired. You can request a new code.';

  @override
  String get errorRateLimited => 'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get errorActivationInvalid => 'This code is not valid. Please check each character and try again.';

  @override
  String get errorActivationUsed =>
      'This code has already been used. Please contact your health insurer for a new code.';

  @override
  String get errorActivationExpired => 'This code has expired. Please ask your health insurer for a new code.';

  @override
  String get errorActivationRevoked => 'This code is no longer valid. Please contact your health insurer.';

  @override
  String get errorActivationWrongProduct => 'This code belongs to a different app.';

  @override
  String get errorAlreadyActivated => 'TheraCare is already activated for your account.';

  @override
  String get errorEntitlementRequired => 'Please activate TheraCare with your activation code first.';

  @override
  String get errorConsentRequired =>
      'Treatment is paused because a required consent is missing. You can review your privacy choices.';

  @override
  String get errorAlreadySubmitted => 'You have already answered this questionnaire.';

  @override
  String get errorReportNotReady => 'The file is still being prepared. Please try again in a moment.';

  @override
  String get errorValidation => 'Please check the highlighted fields.';

  @override
  String get errorSessionExpired => 'Please sign in again. Your saved entries are kept.';

  @override
  String get reviewPrivacy => 'Review privacy choices';

  @override
  String get demoNotice => 'Demo project – not an approved medical device.';

  @override
  String pendingEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries are saved on this device and will be sent when you are online.',
      one: '1 entry is saved on this device and will be sent when you are online.',
    );
    return '$_temp0';
  }

  @override
  String get sendNow => 'Send now';

  @override
  String get help => 'Help';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get notDone => 'Not done yet';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get homeTitle => 'Today';

  @override
  String greeting(String name) {
    return 'Hello $name';
  }

  @override
  String todayProgress(int done, int planned) {
    return 'Today you have done $done of $planned exercises.';
  }

  @override
  String get nextStep => 'Your next step';

  @override
  String get nextExerciseHint => 'A short exercise from your plan.';

  @override
  String get nextQuestionnaireHint => 'A few short questions.';

  @override
  String get startTodaysExercise => 'Start today\'s exercise';

  @override
  String get answerQuestionnaire => 'Answer the questions';

  @override
  String get allDoneTitle => 'Well done';

  @override
  String get allDoneBody => 'You have finished everything for today. You can rest or record how your back feels.';

  @override
  String get thisWeek => 'This week';

  @override
  String get recordPain => 'Record how my back feels';

  @override
  String get finalCheckTitle => 'Your therapy period has ended';

  @override
  String get finalCheckBody => 'Please answer the final back check. It takes about 5 minutes.';

  @override
  String get openQuestionnaires => 'Open questionnaires';

  @override
  String get therapyCompletedTitle => 'Therapy completed';

  @override
  String get therapyCompletedBody => 'Thank you for taking part. Your summary is ready.';

  @override
  String get viewMyReport => 'View my summary';

  @override
  String get navHome => 'Today';

  @override
  String get navPlan => 'Plan';

  @override
  String get navRecord => 'Record';

  @override
  String get navProgress => 'Progress';

  @override
  String get navProfile => 'Profile';

  @override
  String get offlineBanner => 'You are offline. You can keep using TheraCare – entries are saved on this device.';

  @override
  String get startupFailed => 'TheraCare could not start. Please check your connection and try again.';

  @override
  String get gettingStarted => 'Getting started';

  @override
  String stepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get continueLabel => 'Continue';

  @override
  String get onboardingIntroTitle => 'What to expect';

  @override
  String get onboardingPoint1 => 'Your therapy lasts 12 weeks.';

  @override
  String get onboardingPoint2 => 'Each day takes about 10 to 15 minutes.';

  @override
  String get onboardingPoint3 => 'You note how your back feels. This helps you see your progress.';

  @override
  String get importantTitle => 'Important';

  @override
  String get onboardingSafety =>
      'TheraCare does not replace your doctor and cannot help in an emergency. If you have sudden severe pain, numbness or problems with bladder or bowel, call 112.';

  @override
  String get onboardingSettingsTitle => 'Make it comfortable';

  @override
  String get onboardingSettingsBody =>
      'Choose what is easiest for you to read. You can change this later in your profile.';

  @override
  String get onboardingCheckTitle => 'Your starting back check';

  @override
  String get onboardingCheckBody =>
      'Answer 7 short questions about your back. There are no wrong answers and there is no time limit. Your answers are saved after each question.';

  @override
  String get startQuestions => 'Start the questions';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeHelp => 'This works together with the text size of your phone.';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeExtraLarge => 'Extra large';

  @override
  String get display => 'Display';

  @override
  String get highContrast => 'Stronger contrast';

  @override
  String get highContrastHelp => 'Darker text and clearer borders.';

  @override
  String get reducedMotion => 'Less movement';

  @override
  String get reducedMotionHelp => 'Turns off animations between screens.';

  @override
  String get stateOn => 'Currently on';

  @override
  String get stateOff => 'Currently off';

  @override
  String get profileTitle => 'Profile';

  @override
  String get personalData => 'Personal data';

  @override
  String get accessibilityTitle => 'Text size and display';

  @override
  String get accessibilityIntro => 'Changes apply immediately on all screens.';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get privacySettingsTitle => 'Privacy and consent';

  @override
  String get exportTitle => 'Export my data';

  @override
  String get sessionsTitle => 'Signed-in devices';

  @override
  String get closeAccountTitle => 'Close my account';

  @override
  String get language => 'Language';

  @override
  String get emailChangeInfo => 'To change your email address, please contact support.';

  @override
  String get accountStatus => 'Account status';

  @override
  String accountStatusValue(String status) {
    return '$status';
  }

  @override
  String get saveChanges => 'Save changes';

  @override
  String get changesSaved => 'Your changes are saved.';

  @override
  String get remindersIntro => 'A daily reminder can help you keep your routine. It is optional.';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String reminderAt(String time) {
    return 'Reminder at $time';
  }

  @override
  String get changeTime => 'Change time';

  @override
  String quietHoursInfo(String start, String end) {
    return 'No reminders between $start and $end.';
  }

  @override
  String get reminderPrivacy => 'Reminders only say \"You have a new task for today\". They never mention your health.';

  @override
  String get exportIntro => 'You can download your data at any time. You decide where the file goes.';

  @override
  String get fhirExport => 'Machine-readable export (FHIR)';

  @override
  String get fhirExportBody =>
      'A standard health data file (HL7 FHIR R4) that other systems can read. For people, the PDF summary is easier to read.';

  @override
  String get createExport => 'Create export';

  @override
  String withdrawTitle(String name) {
    return 'Withdraw consent: $name?';
  }

  @override
  String get withdrawRequiredWarning =>
      'Without this consent your therapy is paused. Records already saved are kept as the law requires. You can give consent again at any time.';

  @override
  String get withdrawOptionalInfo => 'Your therapy is not affected.';

  @override
  String get withdrawRequiredDone => 'Consent withdrawn. Your therapy is paused until you give consent again.';

  @override
  String get keepConsent => 'Keep my consent';

  @override
  String get withdraw => 'Withdraw';

  @override
  String giveConsent(String name) {
    return 'Give consent: $name';
  }

  @override
  String get consentGiven => 'Thank you. Your consent is saved.';

  @override
  String get consentHistory => 'History of my decisions';

  @override
  String decisionOn(String decision, String date) {
    return '$decision on $date';
  }

  @override
  String get decisionGranted => 'Agreed';

  @override
  String get decisionDeclined => 'Declined';

  @override
  String get decisionWithdrawn => 'Withdrawn';

  @override
  String policyVersion(String version) {
    return 'version $version';
  }

  @override
  String get sessionsIntro =>
      'These devices are signed in to your account. You can sign out devices you do not recognise.';

  @override
  String get unknownDevice => 'Unknown device';

  @override
  String lastUsed(String date) {
    return 'Last used: $date';
  }

  @override
  String get thisDevice => 'This device';

  @override
  String get signOutDevice => 'Sign out';

  @override
  String get closeAccountWarningTitle => 'Please read carefully';

  @override
  String get closeAccountWarning =>
      'You will no longer be able to sign in. Your therapy ends. Treatment records are kept only as long as the law requires and are then deleted or anonymised.';

  @override
  String get closeAccountExportHint => 'Tip: export your data first if you want to keep a copy.';

  @override
  String get closeAccountConfirm => 'I understand and want to close my account';

  @override
  String get closeAccountButton => 'Close my account now';

  @override
  String get progressTitle => 'Progress';

  @override
  String get lastFourWeeks => 'The last 4 weeks';

  @override
  String get chartTitle => 'Exercises per week';

  @override
  String get showAsTable => 'Show as table';

  @override
  String get showAsChart => 'Show as chart';

  @override
  String get weekStarting => 'Week starting';

  @override
  String get exercisesColumn => 'Exercises';

  @override
  String get painAverageColumn => 'Average pain (0–10)';

  @override
  String get backCheck => 'Back check';

  @override
  String backCheckStart(int score) {
    return 'At the start: $score points';
  }

  @override
  String backCheckEnd(int score) {
    return 'At the end: $score points';
  }

  @override
  String get backCheckScale => 'Scale 0 to 34. Lower numbers mean fewer difficulties. This is not a diagnosis.';

  @override
  String get summaryReport => 'Summary of my therapy (PDF)';

  @override
  String get summaryReportBody =>
      'A readable document with your exercises, pain entries and back check results. You can share it with your doctor.';

  @override
  String get createSummary => 'Create summary';

  @override
  String get exportConfirm =>
      'The file contains your personal health information. It is saved on this phone and you choose where to share it. Nothing is sent to anyone automatically.';

  @override
  String get createFile => 'Create file';

  @override
  String get preparingFile => 'Preparing your file. This can take a moment.';

  @override
  String get fileReady => 'Your file is ready.';

  @override
  String get questionnaire => 'Questionnaire';

  @override
  String get questionnaires => 'Questionnaires';

  @override
  String questionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get answerRequired => 'An answer is needed.';

  @override
  String get answerOptional => 'This question is optional.';

  @override
  String get pleaseAnswer => 'Please choose an answer to continue.';

  @override
  String get reviewAnswers => 'Check your answers';

  @override
  String get reviewAnswersBody => 'Please check your answers. You can still change them.';

  @override
  String get submitAnswers => 'Send my answers';

  @override
  String get change => 'Change';

  @override
  String get notAnswered => 'Not answered';

  @override
  String get yourAnswer => 'Your answer';

  @override
  String get noDateChosen => 'No date chosen yet';

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get thankYou => 'Thank you';

  @override
  String get answersSaved => 'Your answers are saved';

  @override
  String get baselineDone => 'Your personal exercise plan is ready. You can start today.';

  @override
  String get finalDone => 'You have completed your therapy. You can now view your summary.';

  @override
  String get checkInDone => 'Thank you for your weekly check-in.';

  @override
  String scoreInfo(int score) {
    return 'Your back check result: $score of 34 points. Lower numbers mean fewer difficulties.';
  }

  @override
  String get scoreNotDiagnosis =>
      'This number is not a diagnosis. It only helps to choose your exercise plan and show your progress.';

  @override
  String get goToHome => 'Go to my overview';

  @override
  String get noQuestionnaires => 'There are no questionnaires for you right now.';

  @override
  String questionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count questions', one: '1 question');
    return '$_temp0';
  }

  @override
  String get statusSubmitted => 'Status: answered';

  @override
  String get statusDraft => 'Status: started – you can continue';

  @override
  String get statusNotStarted => 'Status: not started';

  @override
  String get emergencyTitle => 'In an emergency';

  @override
  String get emergencyBody => 'TheraCare cannot help in an emergency. Call 112 for urgent medical help.';

  @override
  String get faqTitle => 'Frequently asked questions';

  @override
  String get contactTitle => 'Contact support';

  @override
  String get contactBody => 'Our support team helps with technical questions. They cannot see your health data.';

  @override
  String get contactSignedOut =>
      'Please sign in to write to our support team. You can also email support@theracare.example.';

  @override
  String get writeToSupport => 'Write to support';

  @override
  String ticketStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get supportPrivacyNote =>
      'Please do not include passwords, activation codes or health details. We will never ask for them.';

  @override
  String get topic => 'Topic';

  @override
  String get categoryLogin => 'Signing in';

  @override
  String get categoryActivation => 'Activation code';

  @override
  String get categoryExercises => 'Exercises';

  @override
  String get categorySync => 'Saving and sending entries';

  @override
  String get categoryPrivacy => 'Privacy';

  @override
  String get categoryAccessibility => 'Reading and using the app';

  @override
  String get categoryOther => 'Something else';

  @override
  String get subject => 'Subject';

  @override
  String get message => 'Your message';

  @override
  String get subjectTooShort => 'Please write a short subject.';

  @override
  String get messageTooShort => 'Please describe the problem in a few words.';

  @override
  String get sendMessage => 'Send message';

  @override
  String get messageSentTitle => 'Message sent';

  @override
  String get messageSentBody => 'Thank you. We will reply by email.';

  @override
  String get trackTitle => 'Record';

  @override
  String get whatToRecord => 'What would you like to record?';

  @override
  String howStrongNow(String name) {
    return '$name: how is it right now?';
  }

  @override
  String get chooseAValue => 'Please choose a number first.';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteHelp => 'For example what you did before. Please do not report emergencies here.';

  @override
  String get saveEntry => 'Save entry';

  @override
  String get entrySaved => 'Your entry is saved.';

  @override
  String get viewHistory => 'View my entries';

  @override
  String get history => 'My entries';

  @override
  String get noEntriesYet => 'You have not recorded anything yet. Your entries will appear here.';

  @override
  String get correct => 'Correct';

  @override
  String get correctEntry => 'Correct this entry';

  @override
  String correctEntryBody(int value) {
    return 'You entered $value. The original entry is kept for your records.';
  }

  @override
  String get correctionReason => 'Why are you correcting it?';

  @override
  String get saveCorrection => 'Save correction';

  @override
  String get myPlan => 'My plan';

  @override
  String get noPlanYet => 'You do not have an exercise plan yet. It is created after your starting back check.';

  @override
  String weekOf(int week, int weeks) {
    return 'Week $week of $weeks';
  }

  @override
  String get goals => 'Goals';

  @override
  String get todaysExercises => 'Today\'s exercises';

  @override
  String aboutMinutes(int minutes) {
    return 'About $minutes min';
  }

  @override
  String get viewSchedule => 'View my weekly schedule';

  @override
  String planVersion(int value) {
    return 'Plan version $value';
  }

  @override
  String get exercise => 'Exercise';

  @override
  String get startExercise => 'Start exercise';

  @override
  String get safetyFirst => 'Safety first';

  @override
  String get howItWorks => 'How it works';

  @override
  String stepText(int value, String text) {
    return 'Step $value: $text';
  }

  @override
  String get transcript => 'Read the full text';

  @override
  String contentVersion(int value) {
    return 'Content version $value';
  }

  @override
  String get stopExercise => 'Stop';

  @override
  String get stopExerciseTitle => 'Stop this exercise?';

  @override
  String get stopExerciseBody => 'That is fine. Nothing will be saved for this exercise. Stop if you feel pain.';

  @override
  String get continueExercise => 'Continue exercise';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get pausedInfo => 'Paused. Take your time.';

  @override
  String get nextStepButton => 'Next step';

  @override
  String get finishExercise => 'I have finished';

  @override
  String get howWasIt => 'How was it?';

  @override
  String get howWasItBody => 'Choose how hard the exercise felt. This is optional.';

  @override
  String get effort1 => 'Very easy';

  @override
  String get effort2 => 'Easy';

  @override
  String get effort3 => 'Just right';

  @override
  String get effort4 => 'Hard';

  @override
  String get effort5 => 'Too hard';

  @override
  String get saveExercise => 'Save exercise';

  @override
  String get wellDone => 'Well done';

  @override
  String get exerciseSavedTitle => 'Exercise saved';

  @override
  String get exerciseSavedBody => 'Your exercise is saved. If you are offline, it will be sent automatically later.';

  @override
  String get schedule => 'Weekly schedule';

  @override
  String dayProgress(int done, int planned) {
    return '$done of $planned exercises';
  }

  @override
  String scaleChosen(int value, int max) {
    return 'You chose $value of $max.';
  }

  @override
  String get quickActions => 'More for today';

  @override
  String get recordPainHint => 'Pain, stiffness, sleep or mood – takes less than a minute.';

  @override
  String get questionnairesHint => 'Short check-ins about your back.';

  @override
  String get statExercises => 'exercises';

  @override
  String get statActiveDays => 'active days';

  @override
  String get statAveragePain => 'average pain';

  @override
  String get weekByWeek => 'Week by week';

  @override
  String get groupSettings => 'Settings';

  @override
  String get groupPrivacy => 'Privacy and data';

  @override
  String get groupSupport => 'Support';
}
