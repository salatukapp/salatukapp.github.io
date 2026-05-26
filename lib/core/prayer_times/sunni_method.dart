import 'package:adhan_dart/adhan_dart.dart' as adhan;

/// Sunni-recognized prayer-time calculation methods.
/// Shia methods (Tehran, Jafari) are intentionally omitted.
enum SunniMethod {
  northAmerica(
    code: 'ISNA',
    displayName: 'ISNA (North America)',
    arabicName: 'الجمعية الإسلامية لأمريكا الشمالية',
    summary: 'Fajr 15°, Isha 15°. Standard for North America.',
  ),
  ummAlQura(
    code: 'UAQ',
    displayName: 'Umm al-Qura (Makkah)',
    arabicName: 'أم القرى',
    summary: 'Fajr 18.5°, Isha 90 min after Maghrib. Standard in Saudi Arabia.',
  ),
  karachi(
    code: 'KAR',
    displayName: 'University of Karachi',
    arabicName: 'جامعة العلوم الإسلامية بكراتشي',
    summary: 'Fajr 18°, Isha 18°. Used in Pakistan, India, Bangladesh, Afghanistan.',
  ),
  moonsightingCommittee(
    code: 'MSC',
    displayName: 'Moonsighting Committee',
    arabicName: 'لجنة رؤية الهلال',
    summary: 'Fajr 18°, Isha 18° with seasonal correction. Recommended for high latitudes.',
  ),
  kuwait(
    code: 'KWT',
    displayName: 'Kuwait',
    arabicName: 'الكويت',
    summary: 'Fajr 18°, Isha 17.5°.',
  ),
  qatar(
    code: 'QAT',
    displayName: 'Qatar',
    arabicName: 'قطر',
    summary: 'Fajr 18°, Isha 90 min after Maghrib.',
  ),
  singapore(
    code: 'SGP',
    displayName: 'Singapore (MUIS)',
    arabicName: 'سنغافورة',
    summary: 'Fajr 20°, Isha 18°. Used across Southeast Asia.',
  ),
  turkiye(
    code: 'DIY',
    displayName: 'Türkiye (Diyanet)',
    arabicName: 'تركيا - الديانة',
    summary: 'Fajr 18°, Isha 17° with adjustments. Used in Turkey. Note: may differ by ±2-4 min from official Diyanet tables.',
  ),
  dubai(
    code: 'DXB',
    displayName: 'Dubai',
    arabicName: 'دبي',
    summary: 'Fajr 18.2°, Isha 18.2°.',
  ),
  algerian(
    code: 'DZA',
    displayName: 'Algerian Ministry',
    arabicName: 'الجزائر',
    summary: 'Fajr 18°, Isha 17°.',
  ),
  tunisia(
    code: 'TUN',
    displayName: 'Tunisia',
    arabicName: 'تونس',
    summary: 'Fajr 18°, Isha 18°.',
  ),
  morocco(
    code: 'MAR',
    displayName: 'Morocco',
    arabicName: 'المغرب',
    summary: 'Fajr 19°, Isha 17°.',
  ),
  jordan(
    code: 'JOR',
    displayName: 'Jordan',
    arabicName: 'الأردن',
    summary: 'Fajr 18°, Isha 18°.',
  ),
  gulfRegion(
    code: 'GLF',
    displayName: 'Gulf Region',
    arabicName: 'منطقة الخليج',
    summary: 'Fajr 19.5°, Isha 90 min after Maghrib.',
  ),
  portugal(
    code: 'PRT',
    displayName: 'Portugal (ICL)',
    arabicName: 'البرتغال',
    summary: 'Fajr 18°, Isha 77 min after Maghrib.',
  ),
  france(
    code: 'FRA',
    displayName: 'France (UOIF)',
    arabicName: 'فرنسا',
    summary: 'Fajr 12°, Isha 12°.',
  ),
  russia(
    code: 'RUS',
    displayName: 'Russia (Spiritual Admin.)',
    arabicName: 'روسيا',
    summary: 'Fajr 16°, Isha 15°.',
  ),
  indonesian(
    code: 'IDN',
    displayName: 'Indonesia (KEMENAG)',
    arabicName: 'إندونيسيا',
    summary: 'Fajr 20°, Isha 18°.',
  );

  final String code;
  final String displayName;
  final String arabicName;
  final String summary;

  const SunniMethod({
    required this.code,
    required this.displayName,
    required this.arabicName,
    required this.summary,
  });

  /// Map to adhan_dart's CalculationParameters.
  adhan.CalculationParameters toAdhanParameters() {
    switch (this) {
      case SunniMethod.northAmerica:
        return adhan.CalculationMethodParameters.northAmerica();
      case SunniMethod.ummAlQura:
        return adhan.CalculationMethodParameters.ummAlQura();
      case SunniMethod.karachi:
        return adhan.CalculationMethodParameters.karachi();
      case SunniMethod.moonsightingCommittee:
        return adhan.CalculationMethodParameters.moonsightingCommittee();
      case SunniMethod.kuwait:
        return adhan.CalculationMethodParameters.kuwait();
      case SunniMethod.qatar:
        return adhan.CalculationMethodParameters.qatar();
      case SunniMethod.singapore:
        return adhan.CalculationMethodParameters.singapore();
      case SunniMethod.turkiye:
        return adhan.CalculationMethodParameters.turkiye();
      case SunniMethod.dubai:
        return adhan.CalculationMethodParameters.dubai();
      case SunniMethod.algerian:
        return adhan.CalculationMethodParameters.algerian();
      case SunniMethod.tunisia:
        return adhan.CalculationMethodParameters.tunisia();
      case SunniMethod.morocco:
        return adhan.CalculationMethodParameters.morocco();
      case SunniMethod.jordan:
        return adhan.CalculationMethodParameters.jordan();
      case SunniMethod.gulfRegion:
        return adhan.CalculationMethodParameters.gulfRegion();
      case SunniMethod.portugal:
        return adhan.CalculationMethodParameters.portugal();
      case SunniMethod.france:
        return adhan.CalculationMethodParameters.france();
      case SunniMethod.russia:
        return adhan.CalculationMethodParameters.russia();
      case SunniMethod.indonesian:
        return adhan.CalculationMethodParameters.indonesian();
    }
  }

  static SunniMethod fromCode(String code) {
    return SunniMethod.values.firstWhere(
      (m) => m.code == code,
      orElse: () => SunniMethod.karachi,
    );
  }
}
