// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HomeDoc AI';

  @override
  String get homeGreeting => 'How are you feeling today?';

  @override
  String get homeStartTriage => 'Start AI care guidance';

  @override
  String get homeBrowseDoctors => 'Browse doctors';

  @override
  String get homeUpcomingAppointment => 'Upcoming appointment';

  @override
  String get homeEmergency => 'Emergency';

  @override
  String get navHome => 'Home';

  @override
  String get navCare => 'Care';

  @override
  String get navHealth => 'Health';

  @override
  String get navProfile => 'Profile';

  @override
  String get aiDisclaimer => 'AI guidance, not a diagnosis.';

  @override
  String get aiThinking => 'Thinking through what you\'ve shared…';

  @override
  String get aiCareTitle => 'AI Care Guidance';

  @override
  String get aiCareExplanation =>
      'Describe how you\'re feeling. AI will suggest a safe next step — it does not diagnose you.';

  @override
  String get aiCareSymptomsLabel => 'What are you experiencing?';

  @override
  String get aiCareSymptomsHint =>
      'e.g. Headache and mild fever since yesterday';

  @override
  String get aiCareDurationLabel =>
      'How long have you had these symptoms? (optional)';

  @override
  String get aiCareSubmit => 'Get care guidance';

  @override
  String get aiCareSummaryLabel => 'Summary';

  @override
  String get aiCareRedFlagsLabel => 'Things to watch for';

  @override
  String get aiCareEmergencyMessage => 'This may need urgent attention';

  @override
  String get aiCareEmergencyAction => 'Get emergency help';

  @override
  String get aiCareEmptySymptomsError =>
      'Please describe what you\'re experiencing first.';

  @override
  String get aiCareStartOver => 'Describe something else';

  @override
  String get errorGeneric => 'We couldn\'t load this right now.';

  @override
  String get errorRetry => 'Retry';

  @override
  String get errorOffline =>
      'You\'re offline. Some features may be unavailable.';

  @override
  String get errorNetwork =>
      'We couldn\'t reach HomeDoc AI. Please check your connection.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get emptyAppointments =>
      'No appointments yet — start with how you\'re feeling.';

  @override
  String get doctorVerified => 'Verified';

  @override
  String get loginTitle => 'Welcome to HomeDoc AI';

  @override
  String get loginSubtitle => 'Healthcare at your doorstep.';

  @override
  String get loginPhoneLabel => 'Phone number';

  @override
  String get loginContinue => 'Continue';

  @override
  String get comingSoon => 'Coming in a later implementation phase';
}
