/// Country dial codes for phone auth (E.164 country calling codes).
class CountryDialCode {
  final String name;
  final String code;
  final String iso;

  const CountryDialCode({
    required this.name,
    required this.code,
    required this.iso,
  });
}

const List<CountryDialCode> kCountryDialCodes = [
  CountryDialCode(name: 'Afghanistan', code: '+93', iso: 'AF'),
  CountryDialCode(name: 'Albania', code: '+355', iso: 'AL'),
  CountryDialCode(name: 'Algeria', code: '+213', iso: 'DZ'),
  CountryDialCode(name: 'American Samoa', code: '+1684', iso: 'AS'),
  CountryDialCode(name: 'Andorra', code: '+376', iso: 'AD'),
  CountryDialCode(name: 'Angola', code: '+244', iso: 'AO'),
  CountryDialCode(name: 'Anguilla', code: '+1264', iso: 'AI'),
  CountryDialCode(name: 'Antigua and Barbuda', code: '+1268', iso: 'AG'),
  CountryDialCode(name: 'Argentina', code: '+54', iso: 'AR'),
  CountryDialCode(name: 'Armenia', code: '+374', iso: 'AM'),
  CountryDialCode(name: 'Aruba', code: '+297', iso: 'AW'),
  CountryDialCode(name: 'Australia', code: '+61', iso: 'AU'),
  CountryDialCode(name: 'Austria', code: '+43', iso: 'AT'),
  CountryDialCode(name: 'Azerbaijan', code: '+994', iso: 'AZ'),
  CountryDialCode(name: 'Bahamas', code: '+1242', iso: 'BS'),
  CountryDialCode(name: 'Bahrain', code: '+973', iso: 'BH'),
  CountryDialCode(name: 'Bangladesh', code: '+880', iso: 'BD'),
  CountryDialCode(name: 'Barbados', code: '+1246', iso: 'BB'),
  CountryDialCode(name: 'Belarus', code: '+375', iso: 'BY'),
  CountryDialCode(name: 'Belgium', code: '+32', iso: 'BE'),
  CountryDialCode(name: 'Belize', code: '+501', iso: 'BZ'),
  CountryDialCode(name: 'Benin', code: '+229', iso: 'BJ'),
  CountryDialCode(name: 'Bermuda', code: '+1441', iso: 'BM'),
  CountryDialCode(name: 'Bhutan', code: '+975', iso: 'BT'),
  CountryDialCode(name: 'Bolivia', code: '+591', iso: 'BO'),
  CountryDialCode(name: 'Bosnia and Herzegovina', code: '+387', iso: 'BA'),
  CountryDialCode(name: 'Botswana', code: '+267', iso: 'BW'),
  CountryDialCode(name: 'Brazil', code: '+55', iso: 'BR'),
  CountryDialCode(name: 'British Virgin Islands', code: '+1284', iso: 'VG'),
  CountryDialCode(name: 'Brunei', code: '+673', iso: 'BN'),
  CountryDialCode(name: 'Bulgaria', code: '+359', iso: 'BG'),
  CountryDialCode(name: 'Burkina Faso', code: '+226', iso: 'BF'),
  CountryDialCode(name: 'Burundi', code: '+257', iso: 'BI'),
  CountryDialCode(name: 'Cambodia', code: '+855', iso: 'KH'),
  CountryDialCode(name: 'Cameroon', code: '+237', iso: 'CM'),
  CountryDialCode(name: 'Canada', code: '+1', iso: 'CA'),
  CountryDialCode(name: 'Cape Verde', code: '+238', iso: 'CV'),
  CountryDialCode(name: 'Cayman Islands', code: '+1345', iso: 'KY'),
  CountryDialCode(name: 'Central African Republic', code: '+236', iso: 'CF'),
  CountryDialCode(name: 'Chad', code: '+235', iso: 'TD'),
  CountryDialCode(name: 'Chile', code: '+56', iso: 'CL'),
  CountryDialCode(name: 'China', code: '+86', iso: 'CN'),
  CountryDialCode(name: 'Colombia', code: '+57', iso: 'CO'),
  CountryDialCode(name: 'Comoros', code: '+269', iso: 'KM'),
  CountryDialCode(name: 'Congo', code: '+242', iso: 'CG'),
  CountryDialCode(name: 'Congo (DRC)', code: '+243', iso: 'CD'),
  CountryDialCode(name: 'Cook Islands', code: '+682', iso: 'CK'),
  CountryDialCode(name: 'Costa Rica', code: '+506', iso: 'CR'),
  CountryDialCode(name: 'Croatia', code: '+385', iso: 'HR'),
  CountryDialCode(name: 'Cuba', code: '+53', iso: 'CU'),
  CountryDialCode(name: 'Curaçao', code: '+599', iso: 'CW'),
  CountryDialCode(name: 'Cyprus', code: '+357', iso: 'CY'),
  CountryDialCode(name: 'Czech Republic', code: '+420', iso: 'CZ'),
  CountryDialCode(name: 'Denmark', code: '+45', iso: 'DK'),
  CountryDialCode(name: 'Djibouti', code: '+253', iso: 'DJ'),
  CountryDialCode(name: 'Dominica', code: '+1767', iso: 'DM'),
  CountryDialCode(name: 'Dominican Republic', code: '+1809', iso: 'DO'),
  CountryDialCode(name: 'Ecuador', code: '+593', iso: 'EC'),
  CountryDialCode(name: 'Egypt', code: '+20', iso: 'EG'),
  CountryDialCode(name: 'El Salvador', code: '+503', iso: 'SV'),
  CountryDialCode(name: 'Equatorial Guinea', code: '+240', iso: 'GQ'),
  CountryDialCode(name: 'Eritrea', code: '+291', iso: 'ER'),
  CountryDialCode(name: 'Estonia', code: '+372', iso: 'EE'),
  CountryDialCode(name: 'Eswatini', code: '+268', iso: 'SZ'),
  CountryDialCode(name: 'Ethiopia', code: '+251', iso: 'ET'),
  CountryDialCode(name: 'Fiji', code: '+679', iso: 'FJ'),
  CountryDialCode(name: 'Finland', code: '+358', iso: 'FI'),
  CountryDialCode(name: 'France', code: '+33', iso: 'FR'),
  CountryDialCode(name: 'French Guiana', code: '+594', iso: 'GF'),
  CountryDialCode(name: 'French Polynesia', code: '+689', iso: 'PF'),
  CountryDialCode(name: 'Gabon', code: '+241', iso: 'GA'),
  CountryDialCode(name: 'Gambia', code: '+220', iso: 'GM'),
  CountryDialCode(name: 'Georgia', code: '+995', iso: 'GE'),
  CountryDialCode(name: 'Germany', code: '+49', iso: 'DE'),
  CountryDialCode(name: 'Ghana', code: '+233', iso: 'GH'),
  CountryDialCode(name: 'Gibraltar', code: '+350', iso: 'GI'),
  CountryDialCode(name: 'Greece', code: '+30', iso: 'GR'),
  CountryDialCode(name: 'Greenland', code: '+299', iso: 'GL'),
  CountryDialCode(name: 'Grenada', code: '+1473', iso: 'GD'),
  CountryDialCode(name: 'Guadeloupe', code: '+590', iso: 'GP'),
  CountryDialCode(name: 'Guam', code: '+1671', iso: 'GU'),
  CountryDialCode(name: 'Guatemala', code: '+502', iso: 'GT'),
  CountryDialCode(name: 'Guinea', code: '+224', iso: 'GN'),
  CountryDialCode(name: 'Guinea-Bissau', code: '+245', iso: 'GW'),
  CountryDialCode(name: 'Guyana', code: '+592', iso: 'GY'),
  CountryDialCode(name: 'Haiti', code: '+509', iso: 'HT'),
  CountryDialCode(name: 'Honduras', code: '+504', iso: 'HN'),
  CountryDialCode(name: 'Hong Kong', code: '+852', iso: 'HK'),
  CountryDialCode(name: 'Hungary', code: '+36', iso: 'HU'),
  CountryDialCode(name: 'Iceland', code: '+354', iso: 'IS'),
  CountryDialCode(name: 'India', code: '+91', iso: 'IN'),
  CountryDialCode(name: 'Indonesia', code: '+62', iso: 'ID'),
  CountryDialCode(name: 'Iran', code: '+98', iso: 'IR'),
  CountryDialCode(name: 'Iraq', code: '+964', iso: 'IQ'),
  CountryDialCode(name: 'Ireland', code: '+353', iso: 'IE'),
  CountryDialCode(name: 'Isle of Man', code: '+44', iso: 'IM'),
  CountryDialCode(name: 'Israel', code: '+972', iso: 'IL'),
  CountryDialCode(name: 'Italy', code: '+39', iso: 'IT'),
  CountryDialCode(name: 'Ivory Coast', code: '+225', iso: 'CI'),
  CountryDialCode(name: 'Jamaica', code: '+1876', iso: 'JM'),
  CountryDialCode(name: 'Japan', code: '+81', iso: 'JP'),
  CountryDialCode(name: 'Jordan', code: '+962', iso: 'JO'),
  CountryDialCode(name: 'Kazakhstan', code: '+7', iso: 'KZ'),
  CountryDialCode(name: 'Kenya', code: '+254', iso: 'KE'),
  CountryDialCode(name: 'Kiribati', code: '+686', iso: 'KI'),
  CountryDialCode(name: 'Kosovo', code: '+383', iso: 'XK'),
  CountryDialCode(name: 'Kuwait', code: '+965', iso: 'KW'),
  CountryDialCode(name: 'Kyrgyzstan', code: '+996', iso: 'KG'),
  CountryDialCode(name: 'Laos', code: '+856', iso: 'LA'),
  CountryDialCode(name: 'Latvia', code: '+371', iso: 'LV'),
  CountryDialCode(name: 'Lebanon', code: '+961', iso: 'LB'),
  CountryDialCode(name: 'Lesotho', code: '+266', iso: 'LS'),
  CountryDialCode(name: 'Liberia', code: '+231', iso: 'LR'),
  CountryDialCode(name: 'Libya', code: '+218', iso: 'LY'),
  CountryDialCode(name: 'Liechtenstein', code: '+423', iso: 'LI'),
  CountryDialCode(name: 'Lithuania', code: '+370', iso: 'LT'),
  CountryDialCode(name: 'Luxembourg', code: '+352', iso: 'LU'),
  CountryDialCode(name: 'Macau', code: '+853', iso: 'MO'),
  CountryDialCode(name: 'Madagascar', code: '+261', iso: 'MG'),
  CountryDialCode(name: 'Malawi', code: '+265', iso: 'MW'),
  CountryDialCode(name: 'Malaysia', code: '+60', iso: 'MY'),
  CountryDialCode(name: 'Maldives', code: '+960', iso: 'MV'),
  CountryDialCode(name: 'Mali', code: '+223', iso: 'ML'),
  CountryDialCode(name: 'Malta', code: '+356', iso: 'MT'),
  CountryDialCode(name: 'Marshall Islands', code: '+692', iso: 'MH'),
  CountryDialCode(name: 'Martinique', code: '+596', iso: 'MQ'),
  CountryDialCode(name: 'Mauritania', code: '+222', iso: 'MR'),
  CountryDialCode(name: 'Mauritius', code: '+230', iso: 'MU'),
  CountryDialCode(name: 'Mexico', code: '+52', iso: 'MX'),
  CountryDialCode(name: 'Micronesia', code: '+691', iso: 'FM'),
  CountryDialCode(name: 'Moldova', code: '+373', iso: 'MD'),
  CountryDialCode(name: 'Monaco', code: '+377', iso: 'MC'),
  CountryDialCode(name: 'Mongolia', code: '+976', iso: 'MN'),
  CountryDialCode(name: 'Montenegro', code: '+382', iso: 'ME'),
  CountryDialCode(name: 'Montserrat', code: '+1664', iso: 'MS'),
  CountryDialCode(name: 'Morocco', code: '+212', iso: 'MA'),
  CountryDialCode(name: 'Mozambique', code: '+258', iso: 'MZ'),
  CountryDialCode(name: 'Myanmar', code: '+95', iso: 'MM'),
  CountryDialCode(name: 'Namibia', code: '+264', iso: 'NA'),
  CountryDialCode(name: 'Nauru', code: '+674', iso: 'NR'),
  CountryDialCode(name: 'Nepal', code: '+977', iso: 'NP'),
  CountryDialCode(name: 'Netherlands', code: '+31', iso: 'NL'),
  CountryDialCode(name: 'New Caledonia', code: '+687', iso: 'NC'),
  CountryDialCode(name: 'New Zealand', code: '+64', iso: 'NZ'),
  CountryDialCode(name: 'Nicaragua', code: '+505', iso: 'NI'),
  CountryDialCode(name: 'Niger', code: '+227', iso: 'NE'),
  CountryDialCode(name: 'Nigeria', code: '+234', iso: 'NG'),
  CountryDialCode(name: 'Niue', code: '+683', iso: 'NU'),
  CountryDialCode(name: 'North Korea', code: '+850', iso: 'KP'),
  CountryDialCode(name: 'North Macedonia', code: '+389', iso: 'MK'),
  CountryDialCode(name: 'Northern Mariana Islands', code: '+1670', iso: 'MP'),
  CountryDialCode(name: 'Norway', code: '+47', iso: 'NO'),
  CountryDialCode(name: 'Oman', code: '+968', iso: 'OM'),
  CountryDialCode(name: 'Pakistan', code: '+92', iso: 'PK'),
  CountryDialCode(name: 'Palau', code: '+680', iso: 'PW'),
  CountryDialCode(name: 'Palestine', code: '+970', iso: 'PS'),
  CountryDialCode(name: 'Panama', code: '+507', iso: 'PA'),
  CountryDialCode(name: 'Papua New Guinea', code: '+675', iso: 'PG'),
  CountryDialCode(name: 'Paraguay', code: '+595', iso: 'PY'),
  CountryDialCode(name: 'Peru', code: '+51', iso: 'PE'),
  CountryDialCode(name: 'Philippines', code: '+63', iso: 'PH'),
  CountryDialCode(name: 'Poland', code: '+48', iso: 'PL'),
  CountryDialCode(name: 'Portugal', code: '+351', iso: 'PT'),
  CountryDialCode(name: 'Puerto Rico', code: '+1787', iso: 'PR'),
  CountryDialCode(name: 'Qatar', code: '+974', iso: 'QA'),
  CountryDialCode(name: 'Réunion', code: '+262', iso: 'RE'),
  CountryDialCode(name: 'Romania', code: '+40', iso: 'RO'),
  CountryDialCode(name: 'Russia', code: '+7', iso: 'RU'),
  CountryDialCode(name: 'Rwanda', code: '+250', iso: 'RW'),
  CountryDialCode(name: 'Saint Kitts and Nevis', code: '+1869', iso: 'KN'),
  CountryDialCode(name: 'Saint Lucia', code: '+1758', iso: 'LC'),
  CountryDialCode(name: 'Saint Vincent and the Grenadines', code: '+1784', iso: 'VC'),
  CountryDialCode(name: 'Samoa', code: '+685', iso: 'WS'),
  CountryDialCode(name: 'San Marino', code: '+378', iso: 'SM'),
  CountryDialCode(name: 'Sao Tome and Principe', code: '+239', iso: 'ST'),
  CountryDialCode(name: 'Saudi Arabia', code: '+966', iso: 'SA'),
  CountryDialCode(name: 'Senegal', code: '+221', iso: 'SN'),
  CountryDialCode(name: 'Serbia', code: '+381', iso: 'RS'),
  CountryDialCode(name: 'Seychelles', code: '+248', iso: 'SC'),
  CountryDialCode(name: 'Sierra Leone', code: '+232', iso: 'SL'),
  CountryDialCode(name: 'Singapore', code: '+65', iso: 'SG'),
  CountryDialCode(name: 'Sint Maarten', code: '+1721', iso: 'SX'),
  CountryDialCode(name: 'Slovakia', code: '+421', iso: 'SK'),
  CountryDialCode(name: 'Slovenia', code: '+386', iso: 'SI'),
  CountryDialCode(name: 'Solomon Islands', code: '+677', iso: 'SB'),
  CountryDialCode(name: 'Somalia', code: '+252', iso: 'SO'),
  CountryDialCode(name: 'South Africa', code: '+27', iso: 'ZA'),
  CountryDialCode(name: 'South Korea', code: '+82', iso: 'KR'),
  CountryDialCode(name: 'South Sudan', code: '+211', iso: 'SS'),
  CountryDialCode(name: 'Spain', code: '+34', iso: 'ES'),
  CountryDialCode(name: 'Sri Lanka', code: '+94', iso: 'LK'),
  CountryDialCode(name: 'Sudan', code: '+249', iso: 'SD'),
  CountryDialCode(name: 'Suriname', code: '+597', iso: 'SR'),
  CountryDialCode(name: 'Sweden', code: '+46', iso: 'SE'),
  CountryDialCode(name: 'Switzerland', code: '+41', iso: 'CH'),
  CountryDialCode(name: 'Syria', code: '+963', iso: 'SY'),
  CountryDialCode(name: 'Taiwan', code: '+886', iso: 'TW'),
  CountryDialCode(name: 'Tajikistan', code: '+992', iso: 'TJ'),
  CountryDialCode(name: 'Tanzania', code: '+255', iso: 'TZ'),
  CountryDialCode(name: 'Thailand', code: '+66', iso: 'TH'),
  CountryDialCode(name: 'Timor-Leste', code: '+670', iso: 'TL'),
  CountryDialCode(name: 'Togo', code: '+228', iso: 'TG'),
  CountryDialCode(name: 'Tonga', code: '+676', iso: 'TO'),
  CountryDialCode(name: 'Trinidad and Tobago', code: '+1868', iso: 'TT'),
  CountryDialCode(name: 'Tunisia', code: '+216', iso: 'TN'),
  CountryDialCode(name: 'Turkey', code: '+90', iso: 'TR'),
  CountryDialCode(name: 'Turkmenistan', code: '+993', iso: 'TM'),
  CountryDialCode(name: 'Turks and Caicos Islands', code: '+1649', iso: 'TC'),
  CountryDialCode(name: 'Tuvalu', code: '+688', iso: 'TV'),
  CountryDialCode(name: 'Uganda', code: '+256', iso: 'UG'),
  CountryDialCode(name: 'Ukraine', code: '+380', iso: 'UA'),
  CountryDialCode(name: 'United Arab Emirates', code: '+971', iso: 'AE'),
  CountryDialCode(name: 'United Kingdom', code: '+44', iso: 'GB'),
  CountryDialCode(name: 'United States', code: '+1', iso: 'US'),
  CountryDialCode(name: 'Uruguay', code: '+598', iso: 'UY'),
  CountryDialCode(name: 'US Virgin Islands', code: '+1340', iso: 'VI'),
  CountryDialCode(name: 'Uzbekistan', code: '+998', iso: 'UZ'),
  CountryDialCode(name: 'Vanuatu', code: '+678', iso: 'VU'),
  CountryDialCode(name: 'Vatican City', code: '+379', iso: 'VA'),
  CountryDialCode(name: 'Venezuela', code: '+58', iso: 'VE'),
  CountryDialCode(name: 'Vietnam', code: '+84', iso: 'VN'),
  CountryDialCode(name: 'Yemen', code: '+967', iso: 'YE'),
  CountryDialCode(name: 'Zambia', code: '+260', iso: 'ZM'),
  CountryDialCode(name: 'Zimbabwe', code: '+263', iso: 'ZW'),
];

CountryDialCode? findCountryByCode(String code) {
  for (final c in kCountryDialCodes) {
    if (c.code == code) return c;
  }
  return null;
}

CountryDialCode get defaultCountryDialCode {
  return findCountryByCode('+92') ?? kCountryDialCodes.first;
}

/// Longest dial-code prefix match for an E.164 phone (e.g. +92300...).
CountryDialCode? findCountryByPhone(String? rawPhone) {
  if (rawPhone == null) return null;
  final phone = rawPhone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (!phone.startsWith('+') || phone.length < 3) return null;

  CountryDialCode? best;
  for (final c in kCountryDialCodes) {
    if (phone.startsWith(c.code)) {
      if (best == null || c.code.length > best.code.length) {
        best = c;
      }
    }
  }
  return best;
}

/// Maps dial-code country display name → [Constants.countries] key (lowercase).
String? regionKeyForDialCountry(CountryDialCode country) {
  const aliases = <String, String>{
    'cape verde': 'cabo verde',
    'ivory coast': "côte d'ivoire",
    'czech republic': 'czechia (czech republic)',
    'congo': 'congo (congo-brazzaville)',
    'congo (drc)': 'democratic republic of the congo',
    'eswatini': 'eswatini (swaziland)',
    'myanmar': 'myanmar (burma)',
    'palestine': 'palestine state',
    'vatican city': 'holy see',
    'united states': 'united states',
    'united kingdom': 'united kingdom',
    'united arab emirates': 'united arab emirates',
  };

  final lower = country.name.trim().toLowerCase();
  return aliases[lower] ?? lower;
}

/// Resolve region list key from phone number, or null if unknown / not in list.
String? regionKeyFromPhone(
  String? phone, {
  required List<String> regionOptions,
}) {
  final country = findCountryByPhone(phone);
  if (country == null) return null;
  final key = regionKeyForDialCountry(country);
  if (key == null) return null;
  for (final option in regionOptions) {
    if (option == key) return option;
  }
  return null;
}

