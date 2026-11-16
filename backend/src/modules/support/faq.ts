import type { Localized } from '../../common/localized';

type FaqEntry = { category: string; question: Localized; answer: Localized };

export const FAQ: FaqEntry[] = [
  {
    category: 'login',
    question: { de: 'Ich habe mein Passwort vergessen.', en: 'I forgot my password.' },
    answer: {
      de: 'Tippen Sie bei der Anmeldung auf „Passwort vergessen“. Wir senden Ihnen einen Code per E-Mail.',
      en: 'Tap “Forgot password” on the sign-in screen. We will email you a code.',
    },
  },
  {
    category: 'activation',
    question: {
      de: 'Wo finde ich meinen Aktivierungscode?',
      en: 'Where do I find my activation code?',
    },
    answer: {
      de: 'Den Code erhalten Sie von Ihrer Krankenkasse. Er hat 12 Zeichen, z. B. ABCD-EFGH-JKLM.',
      en: 'Your health insurer sends you the code. It has 12 characters, e.g. ABCD-EFGH-JKLM.',
    },
  },
  {
    category: 'exercises',
    question: {
      de: 'Was tue ich, wenn eine Übung weh tut?',
      en: 'What should I do if an exercise hurts?',
    },
    answer: {
      de: 'Hören Sie sofort auf. Bei starken oder neuen Beschwerden wenden Sie sich an Ihre Ärztin oder Ihren Arzt. Im Notfall rufen Sie 112.',
      en: 'Stop immediately. For strong or new symptoms contact your doctor. In an emergency call 112.',
    },
  },
  {
    category: 'sync',
    question: {
      de: 'Funktioniert TheraCare ohne Internet?',
      en: 'Does TheraCare work without internet?',
    },
    answer: {
      de: 'Ja. Ihre Einträge werden auf dem Gerät gespeichert und gesendet, sobald Sie wieder online sind.',
      en: 'Yes. Your entries are saved on your device and sent as soon as you are online again.',
    },
  },
  {
    category: 'privacy',
    question: { de: 'Wer sieht meine Daten?', en: 'Who can see my data?' },
    answer: {
      de: 'Nur Sie. Unser Support sieht keine Gesundheitsdaten. Sie können Ihre Daten jederzeit exportieren.',
      en: 'Only you. Our support team cannot see health data. You can export your data at any time.',
    },
  },
  {
    category: 'accessibility',
    question: { de: 'Wie mache ich die Schrift größer?', en: 'How do I make the text larger?' },
    answer: {
      de: 'Unter Profil → Barrierefreiheit können Sie die Schriftgröße anpassen. TheraCare folgt auch den Einstellungen Ihres Telefons.',
      en: 'Go to Profile → Accessibility to change the text size. TheraCare also follows your phone settings.',
    },
  },
];
