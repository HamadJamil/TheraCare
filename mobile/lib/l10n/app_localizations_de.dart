// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get activationTitle => 'TheraCare freischalten';

  @override
  String get activationBody =>
      'Ihre Krankenkasse hat Ihnen einen 12-stelligen Freischaltcode gegeben. Geben Sie ihn ein, um Ihre Therapie freizuschalten.';

  @override
  String get activationCode => 'Freischaltcode';

  @override
  String get activationCodeHelp =>
      'Zum Beispiel ABCD-EFGH-JKLM. Sie können ihn einfügen. Groß- oder Kleinschreibung ist egal.';

  @override
  String get activationCodeLength => 'Der Code hat 12 Buchstaben und Ziffern. Bitte prüfen Sie ihn.';

  @override
  String get activate => 'Freischalten';

  @override
  String get privacyTitle => 'Ihr Datenschutz';

  @override
  String get privacyIntro =>
      'Bevor Sie beginnen, lesen Sie bitte, was mit Ihren Daten geschieht. Sie entscheiden zu jedem Punkt einzeln.';

  @override
  String get consentRequired => 'Für die Therapie notwendig';

  @override
  String get consentOptional => 'Freiwillig – Ihre Therapie funktioniert auch ohne';

  @override
  String get readDetails => 'Details lesen';

  @override
  String get consentAgree => 'Ich habe das gelesen und stimme zu';

  @override
  String get consentYesOptional => 'Ja, ich erlaube das';

  @override
  String get consentNoOptional => 'Nein, danke';

  @override
  String get privacyRequiredHint =>
      'Um die Therapie zu nutzen, stimmen Sie bitte den Punkten „Für die Therapie notwendig“ zu.';

  @override
  String get saveMyChoices => 'Meine Auswahl speichern';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get welcomeTitle => 'Ihr Rücken, Schritt für Schritt';

  @override
  String get welcomeBody =>
      'TheraCare begleitet Sie mit sanften Übungen und hilft Ihnen, Ihr Befinden festzuhalten. Alles wird in einfacher Sprache erklärt.';

  @override
  String get email => 'E-Mail-Adresse';

  @override
  String get emailHelp => 'An diese Adresse senden wir Ihnen einen Bestätigungscode.';

  @override
  String get password => 'Passwort';

  @override
  String get passwordRules => 'Mindestens 10 Zeichen. Ein kurzer Satz ist leicht zu merken.';

  @override
  String get firstName => 'Vorname';

  @override
  String get lastName => 'Nachname';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get noAccountYet => 'Noch kein Konto? Jetzt erstellen';

  @override
  String get haveAccount => 'Schon ein Konto? Anmelden';

  @override
  String get registerIntro => 'Wir fragen nur, was für Ihr Konto nötig ist.';

  @override
  String get validationEmail => 'Geben Sie eine gültige E-Mail-Adresse ein, zum Beispiel name@beispiel.de.';

  @override
  String get validationPassword => 'Verwenden Sie mindestens 10 Zeichen.';

  @override
  String get validationRequired => 'Bitte füllen Sie dieses Feld aus.';

  @override
  String get validationCode => 'Geben Sie den 6-stelligen Code aus der E-Mail ein.';

  @override
  String get verifyTitle => 'E-Mail bestätigen';

  @override
  String get verifyBody =>
      'Wir haben einen 6-stelligen Code an Ihre E-Mail-Adresse gesendet. Geben Sie ihn unten ein. Der Code ist 30 Minuten gültig.';

  @override
  String get verificationCode => 'Bestätigungscode';

  @override
  String get verificationCodeHelp => '6 Ziffern, zum Beispiel 123456';

  @override
  String get confirmEmail => 'E-Mail bestätigen';

  @override
  String get sendNewCode => 'Neuen Code senden';

  @override
  String get codeResent => 'Wenn die Adresse genutzt werden kann, ist ein neuer Code unterwegs.';

  @override
  String get forgotPasswordBody =>
      'Geben Sie Ihre E-Mail-Adresse ein. Wir senden Ihnen einen Code, um ein neues Passwort zu wählen.';

  @override
  String get sendResetCode => 'Code zum Zurücksetzen senden';

  @override
  String get resetPassword => 'Neues Passwort wählen';

  @override
  String get resetPasswordBody =>
      'Geben Sie den Code aus der E-Mail und Ihr neues Passwort ein. Zu Ihrer Sicherheit werden Sie auf allen Geräten abgemeldet.';

  @override
  String get resetCode => 'Code zum Zurücksetzen';

  @override
  String get resetCodeHelp => '12 Zeichen, zum Beispiel ABCD-EFGH-JKLM';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get saveNewPassword => 'Neues Passwort speichern';

  @override
  String get passwordChanged => 'Ihr Passwort wurde geändert. Bitte melden Sie sich mit dem neuen Passwort an.';

  @override
  String get appName => 'TheraCare';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort verbergen';

  @override
  String get loading => 'Wird geladen …';

  @override
  String get errorTitle => 'Etwas hat nicht funktioniert';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String scaleValue(int value, int max) {
    return '$value von $max';
  }

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Ihre gespeicherten Daten sind sicher. Bitte versuchen Sie es erneut.';

  @override
  String get errorNetwork =>
      'Keine Internetverbindung. Ihre Einträge bleiben auf diesem Gerät und werden später gesendet.';

  @override
  String get errorInvalidCredentials => 'E-Mail-Adresse oder Passwort sind nicht korrekt.';

  @override
  String get errorEmailNotVerified =>
      'Bitte bestätigen Sie Ihre E-Mail-Adresse. Wir haben Ihnen einen neuen Code gesendet.';

  @override
  String get errorInvalidCode => 'Dieser Code ist falsch oder abgelaufen. Sie können einen neuen Code anfordern.';

  @override
  String get errorRateLimited => 'Zu viele Versuche. Bitte warten Sie einige Minuten und versuchen Sie es erneut.';

  @override
  String get errorActivationInvalid =>
      'Dieser Code ist ungültig. Bitte prüfen Sie jedes Zeichen und versuchen Sie es erneut.';

  @override
  String get errorActivationUsed =>
      'Dieser Code wurde bereits verwendet. Bitte wenden Sie sich für einen neuen Code an Ihre Krankenkasse.';

  @override
  String get errorActivationExpired =>
      'Dieser Code ist abgelaufen. Bitte fragen Sie Ihre Krankenkasse nach einem neuen Code.';

  @override
  String get errorActivationRevoked => 'Dieser Code ist nicht mehr gültig. Bitte wenden Sie sich an Ihre Krankenkasse.';

  @override
  String get errorActivationWrongProduct => 'Dieser Code gehört zu einer anderen App.';

  @override
  String get errorAlreadyActivated => 'TheraCare ist für Ihr Konto bereits freigeschaltet.';

  @override
  String get errorEntitlementRequired => 'Bitte schalten Sie TheraCare zuerst mit Ihrem Code frei.';

  @override
  String get errorConsentRequired =>
      'Die Therapie ist pausiert, weil eine notwendige Einwilligung fehlt. Sie können Ihre Datenschutz-Auswahl prüfen.';

  @override
  String get errorAlreadySubmitted => 'Sie haben diesen Fragebogen bereits beantwortet.';

  @override
  String get errorReportNotReady => 'Die Datei wird noch erstellt. Bitte versuchen Sie es gleich noch einmal.';

  @override
  String get errorValidation => 'Bitte prüfen Sie die markierten Felder.';

  @override
  String get errorSessionExpired => 'Bitte melden Sie sich erneut an. Ihre gespeicherten Einträge bleiben erhalten.';

  @override
  String get reviewPrivacy => 'Datenschutz-Auswahl prüfen';

  @override
  String get demoNotice => 'Demo-Projekt – kein zugelassenes Medizinprodukt.';

  @override
  String pendingEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge sind auf diesem Gerät gespeichert und werden gesendet, sobald Sie online sind.',
      one: '1 Eintrag ist auf diesem Gerät gespeichert und wird gesendet, sobald Sie online sind.',
    );
    return '$_temp0';
  }

  @override
  String get sendNow => 'Jetzt senden';

  @override
  String get help => 'Hilfe';

  @override
  String get back => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get close => 'Schließen';

  @override
  String get done => 'Erledigt';

  @override
  String get notDone => 'Noch offen';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get homeTitle => 'Heute';

  @override
  String greeting(String name) {
    return 'Hallo $name';
  }

  @override
  String todayProgress(int done, int planned) {
    return 'Heute haben Sie $done von $planned Übungen gemacht.';
  }

  @override
  String get nextStep => 'Ihr nächster Schritt';

  @override
  String get nextExerciseHint => 'Eine kurze Übung aus Ihrem Plan.';

  @override
  String get nextQuestionnaireHint => 'Ein paar kurze Fragen.';

  @override
  String get startTodaysExercise => 'Heutige Übung starten';

  @override
  String get answerQuestionnaire => 'Fragen beantworten';

  @override
  String get allDoneTitle => 'Gut gemacht';

  @override
  String get allDoneBody =>
      'Sie haben für heute alles erledigt. Sie können sich ausruhen oder notieren, wie es Ihrem Rücken geht.';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get recordPain => 'Notieren, wie es meinem Rücken geht';

  @override
  String get finalCheckTitle => 'Ihr Therapiezeitraum ist beendet';

  @override
  String get finalCheckBody => 'Bitte beantworten Sie den abschließenden Rücken-Check. Er dauert etwa 5 Minuten.';

  @override
  String get openQuestionnaires => 'Fragebögen öffnen';

  @override
  String get therapyCompletedTitle => 'Therapie abgeschlossen';

  @override
  String get therapyCompletedBody => 'Danke für Ihre Teilnahme. Ihre Zusammenfassung ist bereit.';

  @override
  String get viewMyReport => 'Meine Zusammenfassung ansehen';

  @override
  String get navHome => 'Heute';

  @override
  String get navPlan => 'Plan';

  @override
  String get navRecord => 'Notieren';

  @override
  String get navProgress => 'Fortschritt';

  @override
  String get navProfile => 'Profil';

  @override
  String get offlineBanner =>
      'Sie sind offline. Sie können TheraCare weiter nutzen – Einträge werden auf diesem Gerät gespeichert.';

  @override
  String get startupFailed =>
      'TheraCare konnte nicht starten. Bitte prüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get gettingStarted => 'Erste Schritte';

  @override
  String stepProgress(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get continueLabel => 'Weiter';

  @override
  String get onboardingIntroTitle => 'Was Sie erwartet';

  @override
  String get onboardingPoint1 => 'Ihre Therapie dauert 12 Wochen.';

  @override
  String get onboardingPoint2 => 'Jeder Tag dauert etwa 10 bis 15 Minuten.';

  @override
  String get onboardingPoint3 => 'Sie notieren, wie es Ihrem Rücken geht. So sehen Sie Ihren Fortschritt.';

  @override
  String get importantTitle => 'Wichtig';

  @override
  String get onboardingSafety =>
      'TheraCare ersetzt nicht Ihre Ärztin oder Ihren Arzt und hilft nicht im Notfall. Bei plötzlichen starken Schmerzen, Taubheit oder Problemen mit Blase oder Darm rufen Sie 112.';

  @override
  String get onboardingSettingsTitle => 'Bequem einstellen';

  @override
  String get onboardingSettingsBody =>
      'Wählen Sie, was für Sie am besten lesbar ist. Sie können das später im Profil ändern.';

  @override
  String get onboardingCheckTitle => 'Ihr Rücken-Check zu Beginn';

  @override
  String get onboardingCheckBody =>
      'Beantworten Sie 7 kurze Fragen zu Ihrem Rücken. Es gibt keine falschen Antworten und kein Zeitlimit. Ihre Antworten werden nach jeder Frage gespeichert.';

  @override
  String get startQuestions => 'Fragen starten';

  @override
  String get textSize => 'Schriftgröße';

  @override
  String get textSizeHelp => 'Das wirkt zusammen mit der Schriftgröße Ihres Telefons.';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Groß';

  @override
  String get textSizeExtraLarge => 'Sehr groß';

  @override
  String get display => 'Darstellung';

  @override
  String get highContrast => 'Stärkerer Kontrast';

  @override
  String get highContrastHelp => 'Dunklerer Text und deutlichere Rahmen.';

  @override
  String get reducedMotion => 'Weniger Bewegung';

  @override
  String get reducedMotionHelp => 'Schaltet Animationen zwischen Bildschirmen aus.';

  @override
  String get stateOn => 'Derzeit an';

  @override
  String get stateOff => 'Derzeit aus';

  @override
  String get profileTitle => 'Profil';

  @override
  String get personalData => 'Persönliche Daten';

  @override
  String get accessibilityTitle => 'Schriftgröße und Darstellung';

  @override
  String get accessibilityIntro => 'Änderungen gelten sofort auf allen Bildschirmen.';

  @override
  String get remindersTitle => 'Erinnerungen';

  @override
  String get privacySettingsTitle => 'Datenschutz und Einwilligung';

  @override
  String get exportTitle => 'Meine Daten exportieren';

  @override
  String get sessionsTitle => 'Angemeldete Geräte';

  @override
  String get closeAccountTitle => 'Mein Konto schließen';

  @override
  String get language => 'Sprache';

  @override
  String get emailChangeInfo => 'Um Ihre E-Mail-Adresse zu ändern, wenden Sie sich bitte an den Support.';

  @override
  String get accountStatus => 'Kontostatus';

  @override
  String accountStatusValue(String status) {
    return '$status';
  }

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get changesSaved => 'Ihre Änderungen sind gespeichert.';

  @override
  String get remindersIntro => 'Eine tägliche Erinnerung kann helfen, dranzubleiben. Sie ist freiwillig.';

  @override
  String get dailyReminder => 'Tägliche Erinnerung';

  @override
  String reminderAt(String time) {
    return 'Erinnerung um $time';
  }

  @override
  String get changeTime => 'Uhrzeit ändern';

  @override
  String quietHoursInfo(String start, String end) {
    return 'Keine Erinnerungen zwischen $start und $end.';
  }

  @override
  String get reminderPrivacy =>
      'Erinnerungen lauten nur „Sie haben heute eine neue Aufgabe“. Sie erwähnen nie Ihre Gesundheit.';

  @override
  String get exportIntro => 'Sie können Ihre Daten jederzeit herunterladen. Sie entscheiden, wohin die Datei geht.';

  @override
  String get fhirExport => 'Maschinenlesbarer Export (FHIR)';

  @override
  String get fhirExportBody =>
      'Eine Gesundheitsdaten-Datei im Standard HL7 FHIR R4, die andere Systeme lesen können. Für Menschen ist die PDF-Zusammenfassung leichter zu lesen.';

  @override
  String get createExport => 'Export erstellen';

  @override
  String withdrawTitle(String name) {
    return 'Einwilligung widerrufen: $name?';
  }

  @override
  String get withdrawRequiredWarning =>
      'Ohne diese Einwilligung wird Ihre Therapie pausiert. Bereits gespeicherte Daten bleiben erhalten, wie es das Gesetz verlangt. Sie können jederzeit wieder einwilligen.';

  @override
  String get withdrawOptionalInfo => 'Ihre Therapie ist davon nicht betroffen.';

  @override
  String get withdrawRequiredDone => 'Einwilligung widerrufen. Ihre Therapie ist pausiert, bis Sie wieder einwilligen.';

  @override
  String get keepConsent => 'Einwilligung behalten';

  @override
  String get withdraw => 'Widerrufen';

  @override
  String giveConsent(String name) {
    return 'Einwilligen: $name';
  }

  @override
  String get consentGiven => 'Danke. Ihre Einwilligung ist gespeichert.';

  @override
  String get consentHistory => 'Verlauf meiner Entscheidungen';

  @override
  String decisionOn(String decision, String date) {
    return '$decision am $date';
  }

  @override
  String get decisionGranted => 'Zugestimmt';

  @override
  String get decisionDeclined => 'Abgelehnt';

  @override
  String get decisionWithdrawn => 'Widerrufen';

  @override
  String policyVersion(String version) {
    return 'Version $version';
  }

  @override
  String get sessionsIntro =>
      'Diese Geräte sind mit Ihrem Konto angemeldet. Sie können Geräte abmelden, die Sie nicht kennen.';

  @override
  String get unknownDevice => 'Unbekanntes Gerät';

  @override
  String lastUsed(String date) {
    return 'Zuletzt genutzt: $date';
  }

  @override
  String get thisDevice => 'Dieses Gerät';

  @override
  String get signOutDevice => 'Abmelden';

  @override
  String get closeAccountWarningTitle => 'Bitte sorgfältig lesen';

  @override
  String get closeAccountWarning =>
      'Sie können sich danach nicht mehr anmelden. Ihre Therapie endet. Behandlungsdaten werden nur so lange aufbewahrt, wie es das Gesetz verlangt, und dann gelöscht oder anonymisiert.';

  @override
  String get closeAccountExportHint => 'Tipp: Exportieren Sie zuerst Ihre Daten, wenn Sie eine Kopie behalten möchten.';

  @override
  String get closeAccountConfirm => 'Ich habe verstanden und möchte mein Konto schließen';

  @override
  String get closeAccountButton => 'Mein Konto jetzt schließen';

  @override
  String get progressTitle => 'Fortschritt';

  @override
  String get lastFourWeeks => 'Die letzten 4 Wochen';

  @override
  String get chartTitle => 'Übungen pro Woche';

  @override
  String get showAsTable => 'Als Tabelle anzeigen';

  @override
  String get showAsChart => 'Als Diagramm anzeigen';

  @override
  String get weekStarting => 'Woche ab';

  @override
  String get exercisesColumn => 'Übungen';

  @override
  String get painAverageColumn => 'Durchschnittlicher Schmerz (0–10)';

  @override
  String get backCheck => 'Rücken-Check';

  @override
  String backCheckStart(int score) {
    return 'Zu Beginn: $score Punkte';
  }

  @override
  String backCheckEnd(int score) {
    return 'Zum Abschluss: $score Punkte';
  }

  @override
  String get backCheckScale =>
      'Skala 0 bis 34. Niedrigere Werte bedeuten weniger Beschwerden. Dies ist keine Diagnose.';

  @override
  String get summaryReport => 'Zusammenfassung meiner Therapie (PDF)';

  @override
  String get summaryReportBody =>
      'Ein gut lesbares Dokument mit Ihren Übungen, Schmerzangaben und Rücken-Check-Ergebnissen. Sie können es mit Ihrer Ärztin oder Ihrem Arzt teilen.';

  @override
  String get createSummary => 'Zusammenfassung erstellen';

  @override
  String get exportConfirm =>
      'Die Datei enthält Ihre persönlichen Gesundheitsdaten. Sie wird auf diesem Telefon gespeichert und Sie entscheiden, mit wem Sie sie teilen. Nichts wird automatisch verschickt.';

  @override
  String get createFile => 'Datei erstellen';

  @override
  String get preparingFile => 'Ihre Datei wird vorbereitet. Das kann einen Moment dauern.';

  @override
  String get fileReady => 'Ihre Datei ist fertig.';

  @override
  String get questionnaire => 'Fragebogen';

  @override
  String get questionnaires => 'Fragebögen';

  @override
  String questionProgress(int current, int total) {
    return 'Frage $current von $total';
  }

  @override
  String get answerRequired => 'Eine Antwort ist nötig.';

  @override
  String get answerOptional => 'Diese Frage ist freiwillig.';

  @override
  String get pleaseAnswer => 'Bitte wählen Sie eine Antwort, um fortzufahren.';

  @override
  String get reviewAnswers => 'Antworten prüfen';

  @override
  String get reviewAnswersBody => 'Bitte prüfen Sie Ihre Antworten. Sie können sie noch ändern.';

  @override
  String get submitAnswers => 'Meine Antworten senden';

  @override
  String get change => 'Ändern';

  @override
  String get notAnswered => 'Nicht beantwortet';

  @override
  String get yourAnswer => 'Ihre Antwort';

  @override
  String get noDateChosen => 'Noch kein Datum gewählt';

  @override
  String get chooseDate => 'Datum wählen';

  @override
  String get thankYou => 'Vielen Dank';

  @override
  String get answersSaved => 'Ihre Antworten sind gespeichert';

  @override
  String get baselineDone => 'Ihr persönlicher Übungsplan ist bereit. Sie können heute beginnen.';

  @override
  String get finalDone => 'Sie haben Ihre Therapie abgeschlossen. Sie können jetzt Ihre Zusammenfassung ansehen.';

  @override
  String get checkInDone => 'Danke für Ihren Wochen-Rückblick.';

  @override
  String scoreInfo(int score) {
    return 'Ihr Rücken-Check-Ergebnis: $score von 34 Punkten. Niedrigere Werte bedeuten weniger Beschwerden.';
  }

  @override
  String get scoreNotDiagnosis =>
      'Dieser Wert ist keine Diagnose. Er hilft nur, Ihren Übungsplan auszuwählen und Ihren Verlauf zu zeigen.';

  @override
  String get goToHome => 'Zu meiner Übersicht';

  @override
  String get noQuestionnaires => 'Im Moment gibt es keine Fragebögen für Sie.';

  @override
  String questionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Fragen', one: '1 Frage');
    return '$_temp0';
  }

  @override
  String get statusSubmitted => 'Status: beantwortet';

  @override
  String get statusDraft => 'Status: begonnen – Sie können weitermachen';

  @override
  String get statusNotStarted => 'Status: noch nicht begonnen';

  @override
  String get emergencyTitle => 'Im Notfall';

  @override
  String get emergencyBody => 'TheraCare hilft nicht im Notfall. Rufen Sie bei dringender medizinischer Hilfe die 112.';

  @override
  String get faqTitle => 'Häufige Fragen';

  @override
  String get contactTitle => 'Support kontaktieren';

  @override
  String get contactBody => 'Unser Support hilft bei technischen Fragen. Er kann Ihre Gesundheitsdaten nicht sehen.';

  @override
  String get contactSignedOut =>
      'Bitte melden Sie sich an, um dem Support zu schreiben. Sie können auch an support@theracare.example schreiben.';

  @override
  String get writeToSupport => 'Dem Support schreiben';

  @override
  String ticketStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get supportPrivacyNote =>
      'Bitte geben Sie keine Passwörter, Freischaltcodes oder Gesundheitsangaben an. Wir fragen nie danach.';

  @override
  String get topic => 'Thema';

  @override
  String get categoryLogin => 'Anmeldung';

  @override
  String get categoryActivation => 'Freischaltcode';

  @override
  String get categoryExercises => 'Übungen';

  @override
  String get categorySync => 'Speichern und Senden von Einträgen';

  @override
  String get categoryPrivacy => 'Datenschutz';

  @override
  String get categoryAccessibility => 'Lesen und Bedienen der App';

  @override
  String get categoryOther => 'Etwas anderes';

  @override
  String get subject => 'Betreff';

  @override
  String get message => 'Ihre Nachricht';

  @override
  String get subjectTooShort => 'Bitte schreiben Sie einen kurzen Betreff.';

  @override
  String get messageTooShort => 'Bitte beschreiben Sie das Problem in ein paar Worten.';

  @override
  String get sendMessage => 'Nachricht senden';

  @override
  String get messageSentTitle => 'Nachricht gesendet';

  @override
  String get messageSentBody => 'Danke. Wir antworten Ihnen per E-Mail.';

  @override
  String get trackTitle => 'Notieren';

  @override
  String get whatToRecord => 'Was möchten Sie notieren?';

  @override
  String howStrongNow(String name) {
    return '$name: Wie ist es gerade?';
  }

  @override
  String get chooseAValue => 'Bitte wählen Sie zuerst eine Zahl.';

  @override
  String get noteOptional => 'Notiz (freiwillig)';

  @override
  String get noteHelp => 'Zum Beispiel, was Sie vorher gemacht haben. Bitte melden Sie hier keine Notfälle.';

  @override
  String get saveEntry => 'Eintrag speichern';

  @override
  String get entrySaved => 'Ihr Eintrag ist gespeichert.';

  @override
  String get viewHistory => 'Meine Einträge ansehen';

  @override
  String get history => 'Meine Einträge';

  @override
  String get noEntriesYet => 'Sie haben noch nichts notiert. Ihre Einträge erscheinen hier.';

  @override
  String get correct => 'Korrigieren';

  @override
  String get correctEntry => 'Eintrag korrigieren';

  @override
  String correctEntryBody(int value) {
    return 'Sie haben $value eingetragen. Der ursprüngliche Eintrag bleibt für Ihre Unterlagen erhalten.';
  }

  @override
  String get correctionReason => 'Warum korrigieren Sie?';

  @override
  String get saveCorrection => 'Korrektur speichern';

  @override
  String get myPlan => 'Mein Plan';

  @override
  String get noPlanYet => 'Sie haben noch keinen Übungsplan. Er wird nach Ihrem Rücken-Check erstellt.';

  @override
  String weekOf(int week, int weeks) {
    return 'Woche $week von $weeks';
  }

  @override
  String get goals => 'Ziele';

  @override
  String get todaysExercises => 'Heutige Übungen';

  @override
  String aboutMinutes(int minutes) {
    return 'Etwa $minutes Min.';
  }

  @override
  String get viewSchedule => 'Meinen Wochenplan ansehen';

  @override
  String planVersion(int value) {
    return 'Planversion $value';
  }

  @override
  String get exercise => 'Übung';

  @override
  String get startExercise => 'Übung starten';

  @override
  String get safetyFirst => 'Sicherheit zuerst';

  @override
  String get howItWorks => 'So geht\'s';

  @override
  String stepText(int value, String text) {
    return 'Schritt $value: $text';
  }

  @override
  String get transcript => 'Ganzen Text lesen';

  @override
  String contentVersion(int value) {
    return 'Inhaltsversion $value';
  }

  @override
  String get stopExercise => 'Beenden';

  @override
  String get stopExerciseTitle => 'Übung beenden?';

  @override
  String get stopExerciseBody =>
      'Das ist in Ordnung. Für diese Übung wird nichts gespeichert. Hören Sie auf, wenn Sie Schmerzen haben.';

  @override
  String get continueExercise => 'Übung fortsetzen';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get pausedInfo => 'Pausiert. Lassen Sie sich Zeit.';

  @override
  String get nextStepButton => 'Nächster Schritt';

  @override
  String get finishExercise => 'Ich bin fertig';

  @override
  String get howWasIt => 'Wie war es?';

  @override
  String get howWasItBody => 'Wählen Sie, wie anstrengend die Übung war. Das ist freiwillig.';

  @override
  String get effort1 => 'Sehr leicht';

  @override
  String get effort2 => 'Leicht';

  @override
  String get effort3 => 'Genau richtig';

  @override
  String get effort4 => 'Anstrengend';

  @override
  String get effort5 => 'Zu anstrengend';

  @override
  String get saveExercise => 'Übung speichern';

  @override
  String get wellDone => 'Gut gemacht';

  @override
  String get exerciseSavedTitle => 'Übung gespeichert';

  @override
  String get exerciseSavedBody =>
      'Ihre Übung ist gespeichert. Wenn Sie offline sind, wird sie später automatisch gesendet.';

  @override
  String get schedule => 'Wochenplan';

  @override
  String dayProgress(int done, int planned) {
    return '$done von $planned Übungen';
  }
}
