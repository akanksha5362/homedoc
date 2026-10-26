import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HomeDoc AI'**
  String get appName;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get homeGreeting;

  /// No description provided for @homeStartTriage.
  ///
  /// In en, this message translates to:
  /// **'Start AI care guidance'**
  String get homeStartTriage;

  /// No description provided for @homeBrowseDoctors.
  ///
  /// In en, this message translates to:
  /// **'Browse doctors'**
  String get homeBrowseDoctors;

  /// No description provided for @homeUpcomingAppointment.
  ///
  /// In en, this message translates to:
  /// **'Upcoming appointment'**
  String get homeUpcomingAppointment;

  /// No description provided for @homeEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get homeEmergency;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get navCare;

  /// No description provided for @navHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get navHealth;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI guidance, not a diagnosis.'**
  String get aiDisclaimer;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking through what you\'ve shared…'**
  String get aiThinking;

  /// No description provided for @aiCareTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Care Guidance'**
  String get aiCareTitle;

  /// No description provided for @aiCareExplanation.
  ///
  /// In en, this message translates to:
  /// **'Describe how you\'re feeling. AI will suggest a safe next step — it does not diagnose you.'**
  String get aiCareExplanation;

  /// No description provided for @aiCareSymptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'What are you experiencing?'**
  String get aiCareSymptomsLabel;

  /// No description provided for @aiCareSymptomsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Headache and mild fever since yesterday'**
  String get aiCareSymptomsHint;

  /// No description provided for @aiCareDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'How long have you had these symptoms? (optional)'**
  String get aiCareDurationLabel;

  /// No description provided for @aiCareSubmit.
  ///
  /// In en, this message translates to:
  /// **'Get care guidance'**
  String get aiCareSubmit;

  /// No description provided for @aiCareSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get aiCareSummaryLabel;

  /// No description provided for @aiCareRedFlagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Things to watch for'**
  String get aiCareRedFlagsLabel;

  /// No description provided for @aiCareEmergencyMessage.
  ///
  /// In en, this message translates to:
  /// **'This may need urgent attention'**
  String get aiCareEmergencyMessage;

  /// No description provided for @aiCareEmergencyAction.
  ///
  /// In en, this message translates to:
  /// **'Get emergency help'**
  String get aiCareEmergencyAction;

  /// No description provided for @aiCareEmptySymptomsError.
  ///
  /// In en, this message translates to:
  /// **'Please describe what you\'re experiencing first.'**
  String get aiCareEmptySymptomsError;

  /// No description provided for @aiCareStartOver.
  ///
  /// In en, this message translates to:
  /// **'Describe something else'**
  String get aiCareStartOver;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this right now.'**
  String get errorGeneric;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorRetry;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Some features may be unavailable.'**
  String get errorOffline;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach HomeDoc AI. Please check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @emptyAppointments.
  ///
  /// In en, this message translates to:
  /// **'No appointments yet — start with how you\'re feeling.'**
  String get emptyAppointments;

  /// No description provided for @doctorVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get doctorVerified;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to HomeDoc AI'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Healthcare at your doorstep.'**
  String get loginSubtitle;

  /// No description provided for @loginPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get loginPhoneLabel;

  /// No description provided for @loginContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginContinue;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later implementation phase'**
  String get comingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
