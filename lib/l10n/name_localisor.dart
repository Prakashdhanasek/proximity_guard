/// Localizes the FIXED set of demo driver names into the local script.
///
/// Person names are normally proper nouns and stay the same across languages.
/// For this demo we transliterate the known mock names (Ravi Kumar, Rohit,
/// Ajay, Maneesha, Sruthy) into non-Latin scripts (Hindi, Tamil, Arabic, Thai).
/// Latin-script locales (en, es, fr, de, ms, vi) keep the original spelling,
/// and any unknown name is returned unchanged.
String localizedName(String name, String localeCode) {
  final byLocale = _nameMap[name.trim()];
  if (byLocale == null) return name; // unknown name → leave as-is
  return byLocale[localeCode] ?? name;
}

const Map<String, Map<String, String>> _nameMap = {
  'Ravi Kumar': {
    'hi': 'रवि कुमार',
    'ta': 'ரவி குமார்',
    'ar': 'رافي كومار',
    'th': 'ราวี กุมาร',
  },
  'Rohit': {
    'hi': 'रोहित',
    'ta': 'ரோஹித்',
    'ar': 'روهيت',
    'th': 'โรหิต',
  },
  'Maneesha': {
    'hi': 'मनीषा',
    'ta': 'மனீஷா',
    'ar': 'مانيشا',
    'th': 'มานีชา',
  },
  'Sruthy': {
    'hi': 'श्रुति',
    'ta': 'ஸ்ருதி',
    'ar': 'سروتي',
    'th': 'สรุที',
  },
};