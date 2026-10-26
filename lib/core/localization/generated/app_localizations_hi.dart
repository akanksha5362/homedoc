// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'HomeDoc AI';

  @override
  String get homeGreeting => 'आज आप कैसा महसूस कर रहे हैं?';

  @override
  String get homeStartTriage => 'AI केयर गाइडेंस शुरू करें';

  @override
  String get homeBrowseDoctors => 'डॉक्टर खोजें';

  @override
  String get homeUpcomingAppointment => 'आगामी अपॉइंटमेंट';

  @override
  String get homeEmergency => 'आपातकाल';

  @override
  String get navHome => 'होम';

  @override
  String get navCare => 'केयर';

  @override
  String get navHealth => 'स्वास्थ्य';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get aiDisclaimer => 'यह AI मार्गदर्शन है, निदान नहीं।';

  @override
  String get aiThinking => 'आपकी जानकारी पर विचार किया जा रहा है…';

  @override
  String get aiCareTitle => 'AI केयर गाइडेंस';

  @override
  String get aiCareExplanation =>
      'आप कैसा महसूस कर रहे हैं बताएं। AI एक सुरक्षित अगला कदम सुझाएगा — यह निदान नहीं करता।';

  @override
  String get aiCareSymptomsLabel => 'आप क्या महसूस कर रहे हैं?';

  @override
  String get aiCareSymptomsHint => 'जैसे: कल से सिरदर्द और हल्का बुखार';

  @override
  String get aiCareDurationLabel => 'आपको ये लक्षण कब से हैं? (वैकल्पिक)';

  @override
  String get aiCareSubmit => 'केयर गाइडेंस प्राप्त करें';

  @override
  String get aiCareSummaryLabel => 'सारांश';

  @override
  String get aiCareRedFlagsLabel => 'ध्यान देने योग्य बातें';

  @override
  String get aiCareEmergencyMessage =>
      'इसके लिए तुरंत ध्यान देने की आवश्यकता हो सकती है';

  @override
  String get aiCareEmergencyAction => 'आपातकालीन सहायता प्राप्त करें';

  @override
  String get aiCareEmptySymptomsError =>
      'कृपया पहले बताएं कि आप क्या महसूस कर रहे हैं।';

  @override
  String get aiCareStartOver => 'कुछ और बताएं';

  @override
  String get errorGeneric => 'अभी इसे लोड नहीं किया जा सका।';

  @override
  String get errorRetry => 'पुनः प्रयास करें';

  @override
  String get errorOffline =>
      'आप ऑफ़लाइन हैं। कुछ सुविधाएँ उपलब्ध नहीं हो सकतीं।';

  @override
  String get errorNetwork =>
      'HomeDoc AI से संपर्क नहीं हो सका। कृपया अपना कनेक्शन जाँचें।';

  @override
  String get errorSessionExpired =>
      'आपका सत्र समाप्त हो गया है। कृपया फिर से साइन इन करें।';

  @override
  String get emptyAppointments =>
      'अभी तक कोई अपॉइंटमेंट नहीं है — बताएं कि आप कैसा महसूस कर रहे हैं।';

  @override
  String get doctorVerified => 'सत्यापित';

  @override
  String get loginTitle => 'HomeDoc AI में आपका स्वागत है';

  @override
  String get loginSubtitle => 'आपके दरवाज़े पर स्वास्थ्य सेवा।';

  @override
  String get loginPhoneLabel => 'फ़ोन नंबर';

  @override
  String get loginContinue => 'जारी रखें';

  @override
  String get comingSoon => 'यह सुविधा आगामी चरण में उपलब्ध होगी';
}
