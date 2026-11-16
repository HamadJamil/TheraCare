/// Journey steps as decided by the server.
enum NextStep {
  verifyEmail,
  enterActivationCode,
  reviewPrivacy,
  startOnboarding,
  completeBaselineAssessment,
  startTreatment,
  today,
  completeFinalAssessment,
  viewReport,
  none;

  static NextStep parse(String raw) => switch (raw) {
    'VERIFY_EMAIL' => verifyEmail,
    'ENTER_ACTIVATION_CODE' => enterActivationCode,
    'REVIEW_PRIVACY' => reviewPrivacy,
    'START_ONBOARDING' => startOnboarding,
    'COMPLETE_BASELINE_ASSESSMENT' => completeBaselineAssessment,
    'START_TREATMENT' => startTreatment,
    'TODAY' => today,
    'COMPLETE_FINAL_ASSESSMENT' => completeFinalAssessment,
    'VIEW_REPORT' => viewReport,
    _ => none,
  };
}

class Profile {
  const Profile({
    required this.firstName,
    required this.lastName,
    required this.preferredLanguage,
    required this.timezone,
  });
  final String firstName;
  final String lastName;
  final String preferredLanguage;
  final String timezone;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    firstName: j['firstName'] as String,
    lastName: j['lastName'] as String,
    preferredLanguage: j['preferredLanguage'] as String,
    timezone: j['timezone'] as String,
  );

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'preferredLanguage': preferredLanguage,
    'timezone': timezone,
  };
}

/// The signed-in patient: account status and journey are separate concepts.
class Me {
  const Me({
    required this.id,
    required this.email,
    required this.accountStatus,
    required this.journeyState,
    required this.nextStep,
    this.profile,
  });

  final String id;
  final String email;
  final String accountStatus;
  final String journeyState;
  final NextStep nextStep;
  final Profile? profile;

  factory Me.fromJson(Map<String, dynamic> j) {
    final journey = j['journey'] as Map<String, dynamic>;
    return Me(
      id: j['id'] as String,
      email: j['email'] as String,
      accountStatus: j['accountStatus'] as String,
      journeyState: journey['state'] as String,
      nextStep: NextStep.parse(journey['nextStep'] as String),
      profile: j['profile'] == null ? null : Profile.fromJson(j['profile'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'accountStatus': accountStatus,
    'journey': {'state': journeyState, 'nextStep': _wire(nextStep)},
    'profile': profile?.toJson(),
  };

  static String _wire(NextStep s) => s.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();
}
