import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('de'), Locale('en')];

  /// No description provided for @activationTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate TheraCare'**
  String get activationTitle;

  /// No description provided for @activationBody.
  ///
  /// In en, this message translates to:
  /// **'Your health insurer gave you a 12-character activation code. Enter it to unlock your therapy.'**
  String get activationBody;

  /// No description provided for @activationCode.
  ///
  /// In en, this message translates to:
  /// **'Activation code'**
  String get activationCode;

  /// No description provided for @activationCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'For example ABCD-EFGH-JKLM. You can paste it. Upper or lower case does not matter.'**
  String get activationCodeHelp;

  /// No description provided for @activationCodeLength.
  ///
  /// In en, this message translates to:
  /// **'The code has 12 letters and numbers. Please check it.'**
  String get activationCodeLength;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get privacyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Before you start, please read what happens with your data. You decide about each point separately.'**
  String get privacyIntro;

  /// No description provided for @consentRequired.
  ///
  /// In en, this message translates to:
  /// **'Needed for the therapy'**
  String get consentRequired;

  /// No description provided for @consentOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional – your therapy works without it'**
  String get consentOptional;

  /// No description provided for @readDetails.
  ///
  /// In en, this message translates to:
  /// **'Read the details'**
  String get readDetails;

  /// No description provided for @consentAgree.
  ///
  /// In en, this message translates to:
  /// **'I have read this and I agree'**
  String get consentAgree;

  /// No description provided for @consentYesOptional.
  ///
  /// In en, this message translates to:
  /// **'Yes, I allow this'**
  String get consentYesOptional;

  /// No description provided for @consentNoOptional.
  ///
  /// In en, this message translates to:
  /// **'No, thank you'**
  String get consentNoOptional;

  /// No description provided for @privacyRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'To use the therapy, please agree to the points marked \"Needed for the therapy\".'**
  String get privacyRequiredHint;

  /// No description provided for @saveMyChoices.
  ///
  /// In en, this message translates to:
  /// **'Save my choices'**
  String get saveMyChoices;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your back, step by step'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'TheraCare guides you through gentle exercises and helps you keep track of how your back feels. Everything is explained in plain language.'**
  String get welcomeBody;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email;

  /// No description provided for @emailHelp.
  ///
  /// In en, this message translates to:
  /// **'We send you a confirmation code to this address.'**
  String get emailHelp;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRules.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters. A short sentence is easy to remember.'**
  String get passwordRules;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Create one'**
  String get noAccountYet;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @registerIntro.
  ///
  /// In en, this message translates to:
  /// **'We only ask for what is needed to set up your account.'**
  String get registerIntro;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address, for example name@example.com.'**
  String get validationEmail;

  /// No description provided for @validationPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 10 characters.'**
  String get validationPassword;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in this field.'**
  String get validationRequired;

  /// No description provided for @validationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from the email.'**
  String get validationCode;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to your email address. Enter it below. The code is valid for 30 minutes.'**
  String get verifyBody;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code'**
  String get verificationCode;

  /// No description provided for @verificationCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'6 digits, for example 123456'**
  String get verificationCodeHelp;

  /// No description provided for @confirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm email'**
  String get confirmEmail;

  /// No description provided for @sendNewCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get sendNewCode;

  /// No description provided for @codeResent.
  ///
  /// In en, this message translates to:
  /// **'If the address can be used, a new code is on its way.'**
  String get codeResent;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address. We will send you a code to choose a new password.'**
  String get forgotPasswordBody;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get sendResetCode;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetPassword;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from the email and your new password. For your safety you will be signed out on all devices.'**
  String get resetPasswordBody;

  /// No description provided for @resetCode.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get resetCode;

  /// No description provided for @resetCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'12 characters, for example ABCD-EFGH-JKLM'**
  String get resetCodeHelp;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @saveNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get saveNewPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed. Please sign in with your new password.'**
  String get passwordChanged;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'TheraCare'**
  String get appName;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something did not work'**
  String get errorTitle;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @scaleValue.
  ///
  /// In en, this message translates to:
  /// **'{value} of {max}'**
  String scaleValue(int value, int max);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Your saved data is safe. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Your entries are kept on this device and sent later.'**
  String get errorNetwork;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email address or password is not correct.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email address. We sent you a new code.'**
  String get errorEmailNotVerified;

  /// No description provided for @errorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'This code is not correct or has expired. You can request a new code.'**
  String get errorInvalidCode;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorActivationInvalid.
  ///
  /// In en, this message translates to:
  /// **'This code is not valid. Please check each character and try again.'**
  String get errorActivationInvalid;

  /// No description provided for @errorActivationUsed.
  ///
  /// In en, this message translates to:
  /// **'This code has already been used. Please contact your health insurer for a new code.'**
  String get errorActivationUsed;

  /// No description provided for @errorActivationExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Please ask your health insurer for a new code.'**
  String get errorActivationExpired;

  /// No description provided for @errorActivationRevoked.
  ///
  /// In en, this message translates to:
  /// **'This code is no longer valid. Please contact your health insurer.'**
  String get errorActivationRevoked;

  /// No description provided for @errorActivationWrongProduct.
  ///
  /// In en, this message translates to:
  /// **'This code belongs to a different app.'**
  String get errorActivationWrongProduct;

  /// No description provided for @errorAlreadyActivated.
  ///
  /// In en, this message translates to:
  /// **'TheraCare is already activated for your account.'**
  String get errorAlreadyActivated;

  /// No description provided for @errorEntitlementRequired.
  ///
  /// In en, this message translates to:
  /// **'Please activate TheraCare with your activation code first.'**
  String get errorEntitlementRequired;

  /// No description provided for @errorConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Treatment is paused because a required consent is missing. You can review your privacy choices.'**
  String get errorConsentRequired;

  /// No description provided for @errorAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You have already answered this questionnaire.'**
  String get errorAlreadySubmitted;

  /// No description provided for @errorReportNotReady.
  ///
  /// In en, this message translates to:
  /// **'The file is still being prepared. Please try again in a moment.'**
  String get errorReportNotReady;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get errorValidation;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again. Your saved entries are kept.'**
  String get errorSessionExpired;

  /// No description provided for @reviewPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Review privacy choices'**
  String get reviewPrivacy;

  /// No description provided for @demoNotice.
  ///
  /// In en, this message translates to:
  /// **'Demo project – not an approved medical device.'**
  String get demoNotice;

  /// No description provided for @pendingEntries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry is saved on this device and will be sent when you are online.} other{{count} entries are saved on this device and will be sent when you are online.}}'**
  String pendingEntries(int count);

  /// No description provided for @sendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get sendNow;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @notDone.
  ///
  /// In en, this message translates to:
  /// **'Not done yet'**
  String get notDone;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTitle;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}'**
  String greeting(String name);

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today you have done {done} of {planned} exercises.'**
  String todayProgress(int done, int planned);

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Your next step'**
  String get nextStep;

  /// No description provided for @nextExerciseHint.
  ///
  /// In en, this message translates to:
  /// **'A short exercise from your plan.'**
  String get nextExerciseHint;

  /// No description provided for @nextQuestionnaireHint.
  ///
  /// In en, this message translates to:
  /// **'A few short questions.'**
  String get nextQuestionnaireHint;

  /// No description provided for @startTodaysExercise.
  ///
  /// In en, this message translates to:
  /// **'Start today\'s exercise'**
  String get startTodaysExercise;

  /// No description provided for @answerQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Answer the questions'**
  String get answerQuestionnaire;

  /// No description provided for @allDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Well done'**
  String get allDoneTitle;

  /// No description provided for @allDoneBody.
  ///
  /// In en, this message translates to:
  /// **'You have finished everything for today. You can rest or record how your back feels.'**
  String get allDoneBody;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @recordPain.
  ///
  /// In en, this message translates to:
  /// **'Record how my back feels'**
  String get recordPain;

  /// No description provided for @finalCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Your therapy period has ended'**
  String get finalCheckTitle;

  /// No description provided for @finalCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Please answer the final back check. It takes about 5 minutes.'**
  String get finalCheckBody;

  /// No description provided for @openQuestionnaires.
  ///
  /// In en, this message translates to:
  /// **'Open questionnaires'**
  String get openQuestionnaires;

  /// No description provided for @therapyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Therapy completed'**
  String get therapyCompletedTitle;

  /// No description provided for @therapyCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you for taking part. Your summary is ready.'**
  String get therapyCompletedBody;

  /// No description provided for @viewMyReport.
  ///
  /// In en, this message translates to:
  /// **'View my summary'**
  String get viewMyReport;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navHome;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get navRecord;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. You can keep using TheraCare – entries are saved on this device.'**
  String get offlineBanner;

  /// No description provided for @startupFailed.
  ///
  /// In en, this message translates to:
  /// **'TheraCare could not start. Please check your connection and try again.'**
  String get startupFailed;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get gettingStarted;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepProgress(int current, int total);

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @onboardingIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'What to expect'**
  String get onboardingIntroTitle;

  /// No description provided for @onboardingPoint1.
  ///
  /// In en, this message translates to:
  /// **'Your therapy lasts 12 weeks.'**
  String get onboardingPoint1;

  /// No description provided for @onboardingPoint2.
  ///
  /// In en, this message translates to:
  /// **'Each day takes about 10 to 15 minutes.'**
  String get onboardingPoint2;

  /// No description provided for @onboardingPoint3.
  ///
  /// In en, this message translates to:
  /// **'You note how your back feels. This helps you see your progress.'**
  String get onboardingPoint3;

  /// No description provided for @importantTitle.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get importantTitle;

  /// No description provided for @onboardingSafety.
  ///
  /// In en, this message translates to:
  /// **'TheraCare does not replace your doctor and cannot help in an emergency. If you have sudden severe pain, numbness or problems with bladder or bowel, call 112.'**
  String get onboardingSafety;

  /// No description provided for @onboardingSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it comfortable'**
  String get onboardingSettingsTitle;

  /// No description provided for @onboardingSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose what is easiest for you to read. You can change this later in your profile.'**
  String get onboardingSettingsBody;

  /// No description provided for @onboardingCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Your starting back check'**
  String get onboardingCheckTitle;

  /// No description provided for @onboardingCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Answer 7 short questions about your back. There are no wrong answers and there is no time limit. Your answers are saved after each question.'**
  String get onboardingCheckBody;

  /// No description provided for @startQuestions.
  ///
  /// In en, this message translates to:
  /// **'Start the questions'**
  String get startQuestions;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSizeHelp.
  ///
  /// In en, this message translates to:
  /// **'This works together with the text size of your phone.'**
  String get textSizeHelp;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textSizeExtraLarge;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'Stronger contrast'**
  String get highContrast;

  /// No description provided for @highContrastHelp.
  ///
  /// In en, this message translates to:
  /// **'Darker text and clearer borders.'**
  String get highContrastHelp;

  /// No description provided for @reducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Less movement'**
  String get reducedMotion;

  /// No description provided for @reducedMotionHelp.
  ///
  /// In en, this message translates to:
  /// **'Turns off animations between screens.'**
  String get reducedMotionHelp;

  /// No description provided for @stateOn.
  ///
  /// In en, this message translates to:
  /// **'Currently on'**
  String get stateOn;

  /// No description provided for @stateOff.
  ///
  /// In en, this message translates to:
  /// **'Currently off'**
  String get stateOff;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @personalData.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get personalData;

  /// No description provided for @accessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Text size and display'**
  String get accessibilityTitle;

  /// No description provided for @accessibilityIntro.
  ///
  /// In en, this message translates to:
  /// **'Changes apply immediately on all screens.'**
  String get accessibilityIntro;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @privacySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy and consent'**
  String get privacySettingsTitle;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportTitle;

  /// No description provided for @sessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Signed-in devices'**
  String get sessionsTitle;

  /// No description provided for @closeAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Close my account'**
  String get closeAccountTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @emailChangeInfo.
  ///
  /// In en, this message translates to:
  /// **'To change your email address, please contact support.'**
  String get emailChangeInfo;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get accountStatus;

  /// No description provided for @accountStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status}'**
  String accountStatusValue(String status);

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Your changes are saved.'**
  String get changesSaved;

  /// No description provided for @remindersIntro.
  ///
  /// In en, this message translates to:
  /// **'A daily reminder can help you keep your routine. It is optional.'**
  String get remindersIntro;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @reminderAt.
  ///
  /// In en, this message translates to:
  /// **'Reminder at {time}'**
  String reminderAt(String time);

  /// No description provided for @changeTime.
  ///
  /// In en, this message translates to:
  /// **'Change time'**
  String get changeTime;

  /// No description provided for @quietHoursInfo.
  ///
  /// In en, this message translates to:
  /// **'No reminders between {start} and {end}.'**
  String quietHoursInfo(String start, String end);

  /// No description provided for @reminderPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Reminders only say \"You have a new task for today\". They never mention your health.'**
  String get reminderPrivacy;

  /// No description provided for @exportIntro.
  ///
  /// In en, this message translates to:
  /// **'You can download your data at any time. You decide where the file goes.'**
  String get exportIntro;

  /// No description provided for @fhirExport.
  ///
  /// In en, this message translates to:
  /// **'Machine-readable export (FHIR)'**
  String get fhirExport;

  /// No description provided for @fhirExportBody.
  ///
  /// In en, this message translates to:
  /// **'A standard health data file (HL7 FHIR R4) that other systems can read. For people, the PDF summary is easier to read.'**
  String get fhirExportBody;

  /// No description provided for @createExport.
  ///
  /// In en, this message translates to:
  /// **'Create export'**
  String get createExport;

  /// No description provided for @withdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw consent: {name}?'**
  String withdrawTitle(String name);

  /// No description provided for @withdrawRequiredWarning.
  ///
  /// In en, this message translates to:
  /// **'Without this consent your therapy is paused. Records already saved are kept as the law requires. You can give consent again at any time.'**
  String get withdrawRequiredWarning;

  /// No description provided for @withdrawOptionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Your therapy is not affected.'**
  String get withdrawOptionalInfo;

  /// No description provided for @withdrawRequiredDone.
  ///
  /// In en, this message translates to:
  /// **'Consent withdrawn. Your therapy is paused until you give consent again.'**
  String get withdrawRequiredDone;

  /// No description provided for @keepConsent.
  ///
  /// In en, this message translates to:
  /// **'Keep my consent'**
  String get keepConsent;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @giveConsent.
  ///
  /// In en, this message translates to:
  /// **'Give consent: {name}'**
  String giveConsent(String name);

  /// No description provided for @consentGiven.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your consent is saved.'**
  String get consentGiven;

  /// No description provided for @consentHistory.
  ///
  /// In en, this message translates to:
  /// **'History of my decisions'**
  String get consentHistory;

  /// No description provided for @decisionOn.
  ///
  /// In en, this message translates to:
  /// **'{decision} on {date}'**
  String decisionOn(String decision, String date);

  /// No description provided for @decisionGranted.
  ///
  /// In en, this message translates to:
  /// **'Agreed'**
  String get decisionGranted;

  /// No description provided for @decisionDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get decisionDeclined;

  /// No description provided for @decisionWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get decisionWithdrawn;

  /// No description provided for @policyVersion.
  ///
  /// In en, this message translates to:
  /// **'version {version}'**
  String policyVersion(String version);

  /// No description provided for @sessionsIntro.
  ///
  /// In en, this message translates to:
  /// **'These devices are signed in to your account. You can sign out devices you do not recognise.'**
  String get sessionsIntro;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get unknownDevice;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used: {date}'**
  String lastUsed(String date);

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @signOutDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutDevice;

  /// No description provided for @closeAccountWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Please read carefully'**
  String get closeAccountWarningTitle;

  /// No description provided for @closeAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'You will no longer be able to sign in. Your therapy ends. Treatment records are kept only as long as the law requires and are then deleted or anonymised.'**
  String get closeAccountWarning;

  /// No description provided for @closeAccountExportHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: export your data first if you want to keep a copy.'**
  String get closeAccountExportHint;

  /// No description provided for @closeAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'I understand and want to close my account'**
  String get closeAccountConfirm;

  /// No description provided for @closeAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Close my account now'**
  String get closeAccountButton;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @lastFourWeeks.
  ///
  /// In en, this message translates to:
  /// **'The last 4 weeks'**
  String get lastFourWeeks;

  /// No description provided for @chartTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercises per week'**
  String get chartTitle;

  /// No description provided for @showAsTable.
  ///
  /// In en, this message translates to:
  /// **'Show as table'**
  String get showAsTable;

  /// No description provided for @showAsChart.
  ///
  /// In en, this message translates to:
  /// **'Show as chart'**
  String get showAsChart;

  /// No description provided for @weekStarting.
  ///
  /// In en, this message translates to:
  /// **'Week starting'**
  String get weekStarting;

  /// No description provided for @exercisesColumn.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesColumn;

  /// No description provided for @painAverageColumn.
  ///
  /// In en, this message translates to:
  /// **'Average pain (0–10)'**
  String get painAverageColumn;

  /// No description provided for @backCheck.
  ///
  /// In en, this message translates to:
  /// **'Back check'**
  String get backCheck;

  /// No description provided for @backCheckStart.
  ///
  /// In en, this message translates to:
  /// **'At the start: {score} points'**
  String backCheckStart(int score);

  /// No description provided for @backCheckEnd.
  ///
  /// In en, this message translates to:
  /// **'At the end: {score} points'**
  String backCheckEnd(int score);

  /// No description provided for @backCheckScale.
  ///
  /// In en, this message translates to:
  /// **'Scale 0 to 34. Lower numbers mean fewer difficulties. This is not a diagnosis.'**
  String get backCheckScale;

  /// No description provided for @summaryReport.
  ///
  /// In en, this message translates to:
  /// **'Summary of my therapy (PDF)'**
  String get summaryReport;

  /// No description provided for @summaryReportBody.
  ///
  /// In en, this message translates to:
  /// **'A readable document with your exercises, pain entries and back check results. You can share it with your doctor.'**
  String get summaryReportBody;

  /// No description provided for @createSummary.
  ///
  /// In en, this message translates to:
  /// **'Create summary'**
  String get createSummary;

  /// No description provided for @exportConfirm.
  ///
  /// In en, this message translates to:
  /// **'The file contains your personal health information. It is saved on this phone and you choose where to share it. Nothing is sent to anyone automatically.'**
  String get exportConfirm;

  /// No description provided for @createFile.
  ///
  /// In en, this message translates to:
  /// **'Create file'**
  String get createFile;

  /// No description provided for @preparingFile.
  ///
  /// In en, this message translates to:
  /// **'Preparing your file. This can take a moment.'**
  String get preparingFile;

  /// No description provided for @fileReady.
  ///
  /// In en, this message translates to:
  /// **'Your file is ready.'**
  String get fileReady;

  /// No description provided for @questionnaire.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire'**
  String get questionnaire;

  /// No description provided for @questionnaires.
  ///
  /// In en, this message translates to:
  /// **'Questionnaires'**
  String get questionnaires;

  /// No description provided for @questionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionProgress(int current, int total);

  /// No description provided for @answerRequired.
  ///
  /// In en, this message translates to:
  /// **'An answer is needed.'**
  String get answerRequired;

  /// No description provided for @answerOptional.
  ///
  /// In en, this message translates to:
  /// **'This question is optional.'**
  String get answerOptional;

  /// No description provided for @pleaseAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please choose an answer to continue.'**
  String get pleaseAnswer;

  /// No description provided for @reviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'Check your answers'**
  String get reviewAnswers;

  /// No description provided for @reviewAnswersBody.
  ///
  /// In en, this message translates to:
  /// **'Please check your answers. You can still change them.'**
  String get reviewAnswersBody;

  /// No description provided for @submitAnswers.
  ///
  /// In en, this message translates to:
  /// **'Send my answers'**
  String get submitAnswers;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @notAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get notAnswered;

  /// No description provided for @yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get yourAnswer;

  /// No description provided for @noDateChosen.
  ///
  /// In en, this message translates to:
  /// **'No date chosen yet'**
  String get noDateChosen;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get chooseDate;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get thankYou;

  /// No description provided for @answersSaved.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved'**
  String get answersSaved;

  /// No description provided for @baselineDone.
  ///
  /// In en, this message translates to:
  /// **'Your personal exercise plan is ready. You can start today.'**
  String get baselineDone;

  /// No description provided for @finalDone.
  ///
  /// In en, this message translates to:
  /// **'You have completed your therapy. You can now view your summary.'**
  String get finalDone;

  /// No description provided for @checkInDone.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your weekly check-in.'**
  String get checkInDone;

  /// No description provided for @scoreInfo.
  ///
  /// In en, this message translates to:
  /// **'Your back check result: {score} of 34 points. Lower numbers mean fewer difficulties.'**
  String scoreInfo(int score);

  /// No description provided for @scoreNotDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'This number is not a diagnosis. It only helps to choose your exercise plan and show your progress.'**
  String get scoreNotDiagnosis;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to my overview'**
  String get goToHome;

  /// No description provided for @noQuestionnaires.
  ///
  /// In en, this message translates to:
  /// **'There are no questionnaires for you right now.'**
  String get noQuestionnaires;

  /// No description provided for @questionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String questionCount(int count);

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Status: answered'**
  String get statusSubmitted;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Status: started – you can continue'**
  String get statusDraft;

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Status: not started'**
  String get statusNotStarted;

  /// No description provided for @emergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'In an emergency'**
  String get emergencyTitle;

  /// No description provided for @emergencyBody.
  ///
  /// In en, this message translates to:
  /// **'TheraCare cannot help in an emergency. Call 112 for urgent medical help.'**
  String get emergencyBody;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faqTitle;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactTitle;

  /// No description provided for @contactBody.
  ///
  /// In en, this message translates to:
  /// **'Our support team helps with technical questions. They cannot see your health data.'**
  String get contactBody;

  /// No description provided for @contactSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to write to our support team. You can also email support@theracare.example.'**
  String get contactSignedOut;

  /// No description provided for @writeToSupport.
  ///
  /// In en, this message translates to:
  /// **'Write to support'**
  String get writeToSupport;

  /// No description provided for @ticketStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String ticketStatus(String status);

  /// No description provided for @supportPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Please do not include passwords, activation codes or health details. We will never ask for them.'**
  String get supportPrivacyNote;

  /// No description provided for @topic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topic;

  /// No description provided for @categoryLogin.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get categoryLogin;

  /// No description provided for @categoryActivation.
  ///
  /// In en, this message translates to:
  /// **'Activation code'**
  String get categoryActivation;

  /// No description provided for @categoryExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get categoryExercises;

  /// No description provided for @categorySync.
  ///
  /// In en, this message translates to:
  /// **'Saving and sending entries'**
  String get categorySync;

  /// No description provided for @categoryPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get categoryPrivacy;

  /// No description provided for @categoryAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Reading and using the app'**
  String get categoryAccessibility;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get categoryOther;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get message;

  /// No description provided for @subjectTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please write a short subject.'**
  String get subjectTooShort;

  /// No description provided for @messageTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please describe the problem in a few words.'**
  String get messageTooShort;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @messageSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get messageSentTitle;

  /// No description provided for @messageSentBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. We will reply by email.'**
  String get messageSentBody;

  /// No description provided for @trackTitle.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get trackTitle;

  /// No description provided for @whatToRecord.
  ///
  /// In en, this message translates to:
  /// **'What would you like to record?'**
  String get whatToRecord;

  /// No description provided for @howStrongNow.
  ///
  /// In en, this message translates to:
  /// **'{name}: how is it right now?'**
  String howStrongNow(String name);

  /// No description provided for @chooseAValue.
  ///
  /// In en, this message translates to:
  /// **'Please choose a number first.'**
  String get chooseAValue;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @noteHelp.
  ///
  /// In en, this message translates to:
  /// **'For example what you did before. Please do not report emergencies here.'**
  String get noteHelp;

  /// No description provided for @saveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get saveEntry;

  /// No description provided for @entrySaved.
  ///
  /// In en, this message translates to:
  /// **'Your entry is saved.'**
  String get entrySaved;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View my entries'**
  String get viewHistory;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'My entries'**
  String get history;

  /// No description provided for @noEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'You have not recorded anything yet. Your entries will appear here.'**
  String get noEntriesYet;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @correctEntry.
  ///
  /// In en, this message translates to:
  /// **'Correct this entry'**
  String get correctEntry;

  /// No description provided for @correctEntryBody.
  ///
  /// In en, this message translates to:
  /// **'You entered {value}. The original entry is kept for your records.'**
  String correctEntryBody(int value);

  /// No description provided for @correctionReason.
  ///
  /// In en, this message translates to:
  /// **'Why are you correcting it?'**
  String get correctionReason;

  /// No description provided for @saveCorrection.
  ///
  /// In en, this message translates to:
  /// **'Save correction'**
  String get saveCorrection;

  /// No description provided for @myPlan.
  ///
  /// In en, this message translates to:
  /// **'My plan'**
  String get myPlan;

  /// No description provided for @noPlanYet.
  ///
  /// In en, this message translates to:
  /// **'You do not have an exercise plan yet. It is created after your starting back check.'**
  String get noPlanYet;

  /// No description provided for @weekOf.
  ///
  /// In en, this message translates to:
  /// **'Week {week} of {weeks}'**
  String weekOf(int week, int weeks);

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @todaysExercises.
  ///
  /// In en, this message translates to:
  /// **'Today\'s exercises'**
  String get todaysExercises;

  /// No description provided for @aboutMinutes.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min'**
  String aboutMinutes(int minutes);

  /// No description provided for @viewSchedule.
  ///
  /// In en, this message translates to:
  /// **'View my weekly schedule'**
  String get viewSchedule;

  /// No description provided for @planVersion.
  ///
  /// In en, this message translates to:
  /// **'Plan version {value}'**
  String planVersion(int value);

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// No description provided for @startExercise.
  ///
  /// In en, this message translates to:
  /// **'Start exercise'**
  String get startExercise;

  /// No description provided for @safetyFirst.
  ///
  /// In en, this message translates to:
  /// **'Safety first'**
  String get safetyFirst;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @stepText.
  ///
  /// In en, this message translates to:
  /// **'Step {value}: {text}'**
  String stepText(int value, String text);

  /// No description provided for @transcript.
  ///
  /// In en, this message translates to:
  /// **'Read the full text'**
  String get transcript;

  /// No description provided for @contentVersion.
  ///
  /// In en, this message translates to:
  /// **'Content version {value}'**
  String contentVersion(int value);

  /// No description provided for @stopExercise.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopExercise;

  /// No description provided for @stopExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop this exercise?'**
  String get stopExerciseTitle;

  /// No description provided for @stopExerciseBody.
  ///
  /// In en, this message translates to:
  /// **'That is fine. Nothing will be saved for this exercise. Stop if you feel pain.'**
  String get stopExerciseBody;

  /// No description provided for @continueExercise.
  ///
  /// In en, this message translates to:
  /// **'Continue exercise'**
  String get continueExercise;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pausedInfo.
  ///
  /// In en, this message translates to:
  /// **'Paused. Take your time.'**
  String get pausedInfo;

  /// No description provided for @nextStepButton.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStepButton;

  /// No description provided for @finishExercise.
  ///
  /// In en, this message translates to:
  /// **'I have finished'**
  String get finishExercise;

  /// No description provided for @howWasIt.
  ///
  /// In en, this message translates to:
  /// **'How was it?'**
  String get howWasIt;

  /// No description provided for @howWasItBody.
  ///
  /// In en, this message translates to:
  /// **'Choose how hard the exercise felt. This is optional.'**
  String get howWasItBody;

  /// No description provided for @effort1.
  ///
  /// In en, this message translates to:
  /// **'Very easy'**
  String get effort1;

  /// No description provided for @effort2.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get effort2;

  /// No description provided for @effort3.
  ///
  /// In en, this message translates to:
  /// **'Just right'**
  String get effort3;

  /// No description provided for @effort4.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get effort4;

  /// No description provided for @effort5.
  ///
  /// In en, this message translates to:
  /// **'Too hard'**
  String get effort5;

  /// No description provided for @saveExercise.
  ///
  /// In en, this message translates to:
  /// **'Save exercise'**
  String get saveExercise;

  /// No description provided for @wellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done'**
  String get wellDone;

  /// No description provided for @exerciseSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise saved'**
  String get exerciseSavedTitle;

  /// No description provided for @exerciseSavedBody.
  ///
  /// In en, this message translates to:
  /// **'Your exercise is saved. If you are offline, it will be sent automatically later.'**
  String get exerciseSavedBody;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly schedule'**
  String get schedule;

  /// No description provided for @dayProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {planned} exercises'**
  String dayProgress(int done, int planned);

  /// No description provided for @scaleChosen.
  ///
  /// In en, this message translates to:
  /// **'You chose {value} of {max}.'**
  String scaleChosen(int value, int max);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'More for today'**
  String get quickActions;

  /// No description provided for @recordPainHint.
  ///
  /// In en, this message translates to:
  /// **'Pain, stiffness, sleep or mood – takes less than a minute.'**
  String get recordPainHint;

  /// No description provided for @questionnairesHint.
  ///
  /// In en, this message translates to:
  /// **'Short check-ins about your back.'**
  String get questionnairesHint;

  /// No description provided for @statExercises.
  ///
  /// In en, this message translates to:
  /// **'exercises'**
  String get statExercises;

  /// No description provided for @statActiveDays.
  ///
  /// In en, this message translates to:
  /// **'active days'**
  String get statActiveDays;

  /// No description provided for @statAveragePain.
  ///
  /// In en, this message translates to:
  /// **'average pain'**
  String get statAveragePain;

  /// No description provided for @weekByWeek.
  ///
  /// In en, this message translates to:
  /// **'Week by week'**
  String get weekByWeek;

  /// No description provided for @groupSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get groupSettings;

  /// No description provided for @groupPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data'**
  String get groupPrivacy;

  /// No description provided for @groupSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get groupSupport;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
