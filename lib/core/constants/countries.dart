/// Country data for the phone-number country-code picker.
///
/// Each [Country] carries the info the phone input needs to render the flag +
/// dial code prefix and to validate the national number length. Lengths are the
/// national significant number (digits typed *after* the dial code). Most
/// entries use the permissive E.164 default (4–15); the region we actually serve
/// (Uzbekistan + CIS) and a handful of majors carry exact lengths for stricter
/// validation.
class Country {
  /// English display name, e.g. "Uzbekistan".
  final String name;

  /// Emoji flag, e.g. 🇺🇿.
  final String flag;

  /// International dial code including the leading '+', e.g. "+998".
  final String dialCode;

  /// ISO 3166-1 alpha-2 code, e.g. "UZ". Used for search and stable keys.
  final String isoCode;

  /// Minimum national number length (digits after the dial code).
  final int minLength;

  /// Maximum national number length (digits after the dial code).
  final int maxLength;

  /// Optional sample national number shown as the input hint, e.g. "90 123 45 67".
  final String? example;

  const Country({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.isoCode,
    this.minLength = 4,
    this.maxLength = 15,
    this.example,
  });

  /// True when [nationalNumber] (digits only, no dial code) has a plausible
  /// length for this country.
  bool isValidLength(String nationalNumber) {
    final digits = nationalNumber.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= minLength && digits.length <= maxLength;
  }

  /// Digit grouping used to visually format the input, derived from [example].
  /// e.g. "90 123 45 67" → [2, 3, 2, 2]. Empty when no example is defined, in
  /// which case the input formatter falls back to generic groups of three.
  List<int> get digitGroupSizes {
    final ex = example;
    if (ex == null) return const [];
    return ex
        .trim()
        .split(RegExp(r'\s+'))
        .map((g) => g.replaceAll(RegExp(r'[^\d]'), '').length)
        .where((n) => n > 0)
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      other is Country &&
      other.isoCode == isoCode &&
      other.dialCode == dialCode;

  @override
  int get hashCode => Object.hash(isoCode, dialCode);
}

/// The catalogue of selectable countries plus lookup helpers.
class Countries {
  Countries._();

  /// Default selection for the phone field — Uzbekistan is the primary market.
  static const Country uzbekistan = Country(
    name: 'Uzbekistan',
    flag: '🇺🇿',
    dialCode: '+998',
    isoCode: 'UZ',
    minLength: 9,
    maxLength: 9,
    example: '90 123 45 67',
  );

  static const Country defaultCountry = uzbekistan;

  /// Full list, Uzbekistan first, then alphabetical by [name].
  static const List<Country> all = [
    uzbekistan,
    Country(name: 'Afghanistan', flag: '🇦🇫', dialCode: '+93', isoCode: 'AF', minLength: 9, maxLength: 9),
    Country(name: 'Albania', flag: '🇦🇱', dialCode: '+355', isoCode: 'AL'),
    Country(name: 'Algeria', flag: '🇩🇿', dialCode: '+213', isoCode: 'DZ'),
    Country(name: 'Andorra', flag: '🇦🇩', dialCode: '+376', isoCode: 'AD'),
    Country(name: 'Angola', flag: '🇦🇴', dialCode: '+244', isoCode: 'AO'),
    Country(name: 'Argentina', flag: '🇦🇷', dialCode: '+54', isoCode: 'AR', minLength: 10, maxLength: 11),
    Country(name: 'Armenia', flag: '🇦🇲', dialCode: '+374', isoCode: 'AM', minLength: 8, maxLength: 8),
    Country(name: 'Australia', flag: '🇦🇺', dialCode: '+61', isoCode: 'AU', minLength: 9, maxLength: 9),
    Country(name: 'Austria', flag: '🇦🇹', dialCode: '+43', isoCode: 'AT', minLength: 10, maxLength: 13),
    Country(name: 'Azerbaijan', flag: '🇦🇿', dialCode: '+994', isoCode: 'AZ', minLength: 9, maxLength: 9),
    Country(name: 'Bahrain', flag: '🇧🇭', dialCode: '+973', isoCode: 'BH', minLength: 8, maxLength: 8),
    Country(name: 'Bangladesh', flag: '🇧🇩', dialCode: '+880', isoCode: 'BD', minLength: 10, maxLength: 10),
    Country(name: 'Belarus', flag: '🇧🇾', dialCode: '+375', isoCode: 'BY', minLength: 9, maxLength: 9),
    Country(name: 'Belgium', flag: '🇧🇪', dialCode: '+32', isoCode: 'BE', minLength: 9, maxLength: 9),
    Country(name: 'Bolivia', flag: '🇧🇴', dialCode: '+591', isoCode: 'BO'),
    Country(name: 'Bosnia and Herzegovina', flag: '🇧🇦', dialCode: '+387', isoCode: 'BA'),
    Country(name: 'Brazil', flag: '🇧🇷', dialCode: '+55', isoCode: 'BR', minLength: 10, maxLength: 11),
    Country(name: 'Bulgaria', flag: '🇧🇬', dialCode: '+359', isoCode: 'BG'),
    Country(name: 'Cambodia', flag: '🇰🇭', dialCode: '+855', isoCode: 'KH'),
    Country(name: 'Cameroon', flag: '🇨🇲', dialCode: '+237', isoCode: 'CM'),
    Country(name: 'Canada', flag: '🇨🇦', dialCode: '+1', isoCode: 'CA', minLength: 10, maxLength: 10),
    Country(name: 'Chile', flag: '🇨🇱', dialCode: '+56', isoCode: 'CL', minLength: 9, maxLength: 9),
    Country(name: 'China', flag: '🇨🇳', dialCode: '+86', isoCode: 'CN', minLength: 11, maxLength: 11),
    Country(name: 'Colombia', flag: '🇨🇴', dialCode: '+57', isoCode: 'CO', minLength: 10, maxLength: 10),
    Country(name: 'Costa Rica', flag: '🇨🇷', dialCode: '+506', isoCode: 'CR'),
    Country(name: 'Croatia', flag: '🇭🇷', dialCode: '+385', isoCode: 'HR'),
    Country(name: 'Cyprus', flag: '🇨🇾', dialCode: '+357', isoCode: 'CY'),
    Country(name: 'Czechia', flag: '🇨🇿', dialCode: '+420', isoCode: 'CZ', minLength: 9, maxLength: 9),
    Country(name: 'Denmark', flag: '🇩🇰', dialCode: '+45', isoCode: 'DK', minLength: 8, maxLength: 8),
    Country(name: 'Dominican Republic', flag: '🇩🇴', dialCode: '+1', isoCode: 'DO', minLength: 10, maxLength: 10),
    Country(name: 'Ecuador', flag: '🇪🇨', dialCode: '+593', isoCode: 'EC'),
    Country(name: 'Egypt', flag: '🇪🇬', dialCode: '+20', isoCode: 'EG', minLength: 10, maxLength: 10),
    Country(name: 'El Salvador', flag: '🇸🇻', dialCode: '+503', isoCode: 'SV'),
    Country(name: 'Estonia', flag: '🇪🇪', dialCode: '+372', isoCode: 'EE'),
    Country(name: 'Ethiopia', flag: '🇪🇹', dialCode: '+251', isoCode: 'ET'),
    Country(name: 'Finland', flag: '🇫🇮', dialCode: '+358', isoCode: 'FI'),
    Country(name: 'France', flag: '🇫🇷', dialCode: '+33', isoCode: 'FR', minLength: 9, maxLength: 9),
    Country(name: 'Georgia', flag: '🇬🇪', dialCode: '+995', isoCode: 'GE', minLength: 9, maxLength: 9),
    Country(name: 'Germany', flag: '🇩🇪', dialCode: '+49', isoCode: 'DE', minLength: 10, maxLength: 11),
    Country(name: 'Ghana', flag: '🇬🇭', dialCode: '+233', isoCode: 'GH'),
    Country(name: 'Greece', flag: '🇬🇷', dialCode: '+30', isoCode: 'GR', minLength: 10, maxLength: 10),
    Country(name: 'Guatemala', flag: '🇬🇹', dialCode: '+502', isoCode: 'GT'),
    Country(name: 'Honduras', flag: '🇭🇳', dialCode: '+504', isoCode: 'HN'),
    Country(name: 'Hong Kong', flag: '🇭🇰', dialCode: '+852', isoCode: 'HK', minLength: 8, maxLength: 8),
    Country(name: 'Hungary', flag: '🇭🇺', dialCode: '+36', isoCode: 'HU'),
    Country(name: 'Iceland', flag: '🇮🇸', dialCode: '+354', isoCode: 'IS'),
    Country(name: 'India', flag: '🇮🇳', dialCode: '+91', isoCode: 'IN', minLength: 10, maxLength: 10),
    Country(name: 'Indonesia', flag: '🇮🇩', dialCode: '+62', isoCode: 'ID', minLength: 9, maxLength: 11),
    Country(name: 'Iran', flag: '🇮🇷', dialCode: '+98', isoCode: 'IR', minLength: 10, maxLength: 10),
    Country(name: 'Iraq', flag: '🇮🇶', dialCode: '+964', isoCode: 'IQ'),
    Country(name: 'Ireland', flag: '🇮🇪', dialCode: '+353', isoCode: 'IE'),
    Country(name: 'Israel', flag: '🇮🇱', dialCode: '+972', isoCode: 'IL', minLength: 9, maxLength: 9),
    Country(name: 'Italy', flag: '🇮🇹', dialCode: '+39', isoCode: 'IT', minLength: 9, maxLength: 10),
    Country(name: 'Japan', flag: '🇯🇵', dialCode: '+81', isoCode: 'JP', minLength: 10, maxLength: 10),
    Country(name: 'Jordan', flag: '🇯🇴', dialCode: '+962', isoCode: 'JO'),
    Country(name: 'Kazakhstan', flag: '🇰🇿', dialCode: '+7', isoCode: 'KZ', minLength: 10, maxLength: 10),
    Country(name: 'Kenya', flag: '🇰🇪', dialCode: '+254', isoCode: 'KE'),
    Country(name: 'Kuwait', flag: '🇰🇼', dialCode: '+965', isoCode: 'KW', minLength: 8, maxLength: 8),
    Country(name: 'Kyrgyzstan', flag: '🇰🇬', dialCode: '+996', isoCode: 'KG', minLength: 9, maxLength: 9),
    Country(name: 'Laos', flag: '🇱🇦', dialCode: '+856', isoCode: 'LA'),
    Country(name: 'Latvia', flag: '🇱🇻', dialCode: '+371', isoCode: 'LV'),
    Country(name: 'Lebanon', flag: '🇱🇧', dialCode: '+961', isoCode: 'LB'),
    Country(name: 'Libya', flag: '🇱🇾', dialCode: '+218', isoCode: 'LY'),
    Country(name: 'Lithuania', flag: '🇱🇹', dialCode: '+370', isoCode: 'LT'),
    Country(name: 'Luxembourg', flag: '🇱🇺', dialCode: '+352', isoCode: 'LU'),
    Country(name: 'Malaysia', flag: '🇲🇾', dialCode: '+60', isoCode: 'MY', minLength: 9, maxLength: 10),
    Country(name: 'Maldives', flag: '🇲🇻', dialCode: '+960', isoCode: 'MV'),
    Country(name: 'Malta', flag: '🇲🇹', dialCode: '+356', isoCode: 'MT'),
    Country(name: 'Mexico', flag: '🇲🇽', dialCode: '+52', isoCode: 'MX', minLength: 10, maxLength: 10),
    Country(name: 'Moldova', flag: '🇲🇩', dialCode: '+373', isoCode: 'MD', minLength: 8, maxLength: 8),
    Country(name: 'Monaco', flag: '🇲🇨', dialCode: '+377', isoCode: 'MC'),
    Country(name: 'Mongolia', flag: '🇲🇳', dialCode: '+976', isoCode: 'MN'),
    Country(name: 'Montenegro', flag: '🇲🇪', dialCode: '+382', isoCode: 'ME'),
    Country(name: 'Morocco', flag: '🇲🇦', dialCode: '+212', isoCode: 'MA', minLength: 9, maxLength: 9),
    Country(name: 'Myanmar', flag: '🇲🇲', dialCode: '+95', isoCode: 'MM'),
    Country(name: 'Nepal', flag: '🇳🇵', dialCode: '+977', isoCode: 'NP'),
    Country(name: 'Netherlands', flag: '🇳🇱', dialCode: '+31', isoCode: 'NL', minLength: 9, maxLength: 9),
    Country(name: 'New Zealand', flag: '🇳🇿', dialCode: '+64', isoCode: 'NZ', minLength: 8, maxLength: 10),
    Country(name: 'Nigeria', flag: '🇳🇬', dialCode: '+234', isoCode: 'NG', minLength: 10, maxLength: 10),
    Country(name: 'North Macedonia', flag: '🇲🇰', dialCode: '+389', isoCode: 'MK'),
    Country(name: 'Norway', flag: '🇳🇴', dialCode: '+47', isoCode: 'NO', minLength: 8, maxLength: 8),
    Country(name: 'Oman', flag: '🇴🇲', dialCode: '+968', isoCode: 'OM', minLength: 8, maxLength: 8),
    Country(name: 'Pakistan', flag: '🇵🇰', dialCode: '+92', isoCode: 'PK', minLength: 10, maxLength: 10),
    Country(name: 'Palestine', flag: '🇵🇸', dialCode: '+970', isoCode: 'PS'),
    Country(name: 'Panama', flag: '🇵🇦', dialCode: '+507', isoCode: 'PA'),
    Country(name: 'Paraguay', flag: '🇵🇾', dialCode: '+595', isoCode: 'PY'),
    Country(name: 'Peru', flag: '🇵🇪', dialCode: '+51', isoCode: 'PE', minLength: 9, maxLength: 9),
    Country(name: 'Philippines', flag: '🇵🇭', dialCode: '+63', isoCode: 'PH', minLength: 10, maxLength: 10),
    Country(name: 'Poland', flag: '🇵🇱', dialCode: '+48', isoCode: 'PL', minLength: 9, maxLength: 9),
    Country(name: 'Portugal', flag: '🇵🇹', dialCode: '+351', isoCode: 'PT', minLength: 9, maxLength: 9),
    Country(name: 'Qatar', flag: '🇶🇦', dialCode: '+974', isoCode: 'QA', minLength: 8, maxLength: 8),
    Country(name: 'Romania', flag: '🇷🇴', dialCode: '+40', isoCode: 'RO', minLength: 9, maxLength: 9),
    Country(name: 'Russia', flag: '🇷🇺', dialCode: '+7', isoCode: 'RU', minLength: 10, maxLength: 10, example: '912 345 67 89'),
    Country(name: 'Saudi Arabia', flag: '🇸🇦', dialCode: '+966', isoCode: 'SA', minLength: 9, maxLength: 9),
    Country(name: 'Senegal', flag: '🇸🇳', dialCode: '+221', isoCode: 'SN'),
    Country(name: 'Serbia', flag: '🇷🇸', dialCode: '+381', isoCode: 'RS'),
    Country(name: 'Singapore', flag: '🇸🇬', dialCode: '+65', isoCode: 'SG', minLength: 8, maxLength: 8),
    Country(name: 'Slovakia', flag: '🇸🇰', dialCode: '+421', isoCode: 'SK', minLength: 9, maxLength: 9),
    Country(name: 'Slovenia', flag: '🇸🇮', dialCode: '+386', isoCode: 'SI'),
    Country(name: 'South Africa', flag: '🇿🇦', dialCode: '+27', isoCode: 'ZA', minLength: 9, maxLength: 9),
    Country(name: 'South Korea', flag: '🇰🇷', dialCode: '+82', isoCode: 'KR', minLength: 9, maxLength: 10),
    Country(name: 'Spain', flag: '🇪🇸', dialCode: '+34', isoCode: 'ES', minLength: 9, maxLength: 9),
    Country(name: 'Sri Lanka', flag: '🇱🇰', dialCode: '+94', isoCode: 'LK'),
    Country(name: 'Sweden', flag: '🇸🇪', dialCode: '+46', isoCode: 'SE', minLength: 9, maxLength: 9),
    Country(name: 'Switzerland', flag: '🇨🇭', dialCode: '+41', isoCode: 'CH', minLength: 9, maxLength: 9),
    Country(name: 'Syria', flag: '🇸🇾', dialCode: '+963', isoCode: 'SY'),
    Country(name: 'Taiwan', flag: '🇹🇼', dialCode: '+886', isoCode: 'TW'),
    Country(name: 'Tajikistan', flag: '🇹🇯', dialCode: '+992', isoCode: 'TJ', minLength: 9, maxLength: 9),
    Country(name: 'Tanzania', flag: '🇹🇿', dialCode: '+255', isoCode: 'TZ'),
    Country(name: 'Thailand', flag: '🇹🇭', dialCode: '+66', isoCode: 'TH', minLength: 9, maxLength: 9),
    Country(name: 'Tunisia', flag: '🇹🇳', dialCode: '+216', isoCode: 'TN', minLength: 8, maxLength: 8),
    Country(name: 'Turkey', flag: '🇹🇷', dialCode: '+90', isoCode: 'TR', minLength: 10, maxLength: 10, example: '501 234 56 78'),
    Country(name: 'Turkmenistan', flag: '🇹🇲', dialCode: '+993', isoCode: 'TM', minLength: 8, maxLength: 8),
    Country(name: 'Uganda', flag: '🇺🇬', dialCode: '+256', isoCode: 'UG'),
    Country(name: 'Ukraine', flag: '🇺🇦', dialCode: '+380', isoCode: 'UA', minLength: 9, maxLength: 9, example: '50 123 45 67'),
    Country(name: 'United Arab Emirates', flag: '🇦🇪', dialCode: '+971', isoCode: 'AE', minLength: 9, maxLength: 9),
    Country(name: 'United Kingdom', flag: '🇬🇧', dialCode: '+44', isoCode: 'GB', minLength: 10, maxLength: 10, example: '7400 123456'),
    Country(name: 'United States', flag: '🇺🇸', dialCode: '+1', isoCode: 'US', minLength: 10, maxLength: 10, example: '201 555 0123'),
    Country(name: 'Uruguay', flag: '🇺🇾', dialCode: '+598', isoCode: 'UY'),
    Country(name: 'Venezuela', flag: '🇻🇪', dialCode: '+58', isoCode: 'VE'),
    Country(name: 'Vietnam', flag: '🇻🇳', dialCode: '+84', isoCode: 'VN', minLength: 9, maxLength: 10),
    Country(name: 'Yemen', flag: '🇾🇪', dialCode: '+967', isoCode: 'YE'),
    Country(name: 'Zambia', flag: '🇿🇲', dialCode: '+260', isoCode: 'ZM'),
    Country(name: 'Zimbabwe', flag: '🇿🇼', dialCode: '+263', isoCode: 'ZW'),
  ];

  /// First country whose dial code matches [dialCode] (with or without '+'),
  /// or null. When a code is shared (e.g. +7 by RU and KZ, +1 by US/CA), the
  /// earliest list entry wins — good enough for prefill; the user can re-pick.
  static Country? byDialCode(String dialCode) {
    final normalized = dialCode.startsWith('+') ? dialCode : '+$dialCode';
    for (final c in all) {
      if (c.dialCode == normalized) return c;
    }
    return null;
  }

  /// Country for an ISO alpha-2 code (case-insensitive), or null.
  static Country? byIsoCode(String isoCode) {
    final upper = isoCode.toUpperCase();
    for (final c in all) {
      if (c.isoCode == upper) return c;
    }
    return null;
  }

  /// Filters [all] by a free-text query matching name, dial code, or ISO code.
  static List<Country> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    final digits = q.replaceAll(RegExp(r'[^\d]'), '');
    return all.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      if (c.isoCode.toLowerCase().contains(q)) return true;
      if (digits.isNotEmpty && c.dialCode.contains(digits)) return true;
      return false;
    }).toList();
  }
}
