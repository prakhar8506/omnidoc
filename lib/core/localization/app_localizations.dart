import 'package:flutter/material.dart';

/// Lightweight, production-grade internationalization supporting English and Hindi.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('hi', ''),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Cura',
      'daily_balance': 'Daily Balance',
      'body_state_today': 'Your body state today',
      'feeling_tracker': 'Feeling Journal',
      'feeling_question': 'How are you feeling today?',
      'feeling_subtitle': 'Feeling tracker helps to analyse your state of mind',
      'good_balance': 'Good balance',
      'optimal_recovery': 'Optimal recovery',
      'tip_cardio': '💡 Tip: Today is good for light cardio or yoga',
      'active': 'Active',
      'weather': 'Hot & Sunny',
      'todays_stress': "Today's Stress",
      'daily_vitals': 'Daily Vitals & Wearables',
      'resting_hr': 'Resting HR',
      'sleep': 'Sleep',
      'activity': 'Activity',
      'blood_oxygen': 'Blood Oxygen',
      'blood_glucose': 'Blood Glucose',
      'blood_pressure': 'Blood Pressure',
      'today_medications': "Today's Medications",
      'upcoming_consultation': 'Upcoming Consultation',
      'quick_access': 'Quick Access',
      'wearable_connect': 'Wearable Connect',
      'nutrition_hydration': 'Nutrition & Hydration',
      'womens_health': "Women's Health",
      'chronic_care': 'Chronic Condition Care',
      'preventive_care': 'Preventive Care',
      'community_challenges': 'Community Challenges',
      'insurance_claims': 'Insurance & Claims',
      'emergency_id': 'Emergency Medical ID',
      'export_records': 'Export Health Records',
      'ask_ai': 'Ask Health AI',
      'language_toggle': 'Language / भाषा',
    },
    'hi': {
      'app_title': 'क्यूरा',
      'daily_balance': 'दैनिक संतुलन',
      'body_state_today': 'आज आपके शरीर की स्थिति',
      'feeling_tracker': 'मनोदशा पत्रिका',
      'feeling_question': 'आज आप कैसा महसूस कर रहे हैं?',
      'feeling_subtitle': 'फीलिंग ट्रैकर आपकी मानसिक स्थिति का विश्लेषण करने में मदद करता है',
      'good_balance': 'उत्कृष्ट संतुलन',
      'optimal_recovery': 'उत्तम रिकवरी',
      'tip_cardio': '💡 सुझाव: आज हल्के कार्डियो या योग के लिए उत्तम दिन है',
      'active': 'सक्रिय',
      'weather': 'धूप और गर्म',
      'todays_stress': 'आज का तनाव स्तर',
      'daily_vitals': 'दैनिक वाइटल्स और वियरेबल्स',
      'resting_hr': 'हृदय गति',
      'sleep': 'नींद',
      'activity': 'गतिविधि',
      'blood_oxygen': 'रक्त ऑक्सीजन',
      'blood_glucose': 'रक्त शर्करा',
      'blood_pressure': 'रक्तचाप',
      'today_medications': 'आज की दवाइयाँ',
      'upcoming_consultation': 'आगामी डॉक्टर परामर्श',
      'quick_access': 'त्वरित सेवाएँ',
      'wearable_connect': 'स्मार्टवॉच कनेक्ट',
      'nutrition_hydration': 'पोषण और जल सेवन',
      'womens_health': 'महिला स्वास्थ्य',
      'chronic_care': 'दीर्घकालिक स्वास्थ्य देखभाल',
      'preventive_care': 'निवारक स्वास्थ्य जांच',
      'community_challenges': 'सामुदायिक चुनौतियाँ',
      'insurance_claims': 'बीमा और दावे',
      'emergency_id': 'आपातकालीन मेडिकल आईडी',
      'export_records': 'स्वास्थ्य रिकॉर्ड डाउनलोड',
      'ask_ai': 'हेल्थ एआई से पूछें',
      'language_toggle': 'Language / भाषा',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
