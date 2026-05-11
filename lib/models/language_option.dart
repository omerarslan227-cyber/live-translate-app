class LanguageOption {
  final String name;
  final String sourceCode;
  final String targetCode;
  final String ttsCode;

  const LanguageOption({
    required this.name,
    required this.sourceCode,
    required this.targetCode,
    required this.ttsCode,
  });
}

const List<LanguageOption> bridgeCallLanguages = [
  LanguageOption(
    name: 'Türkçe',
    sourceCode: 'TR',
    targetCode: 'TR',
    ttsCode: 'tr-TR',
  ),
  LanguageOption(
    name: 'İngilizce',
    sourceCode: 'EN',
    targetCode: 'EN-US',
    ttsCode: 'en-US',
  ),
  LanguageOption(
    name: 'Almanca',
    sourceCode: 'DE',
    targetCode: 'DE',
    ttsCode: 'de-DE',
  ),
  LanguageOption(
    name: 'Hollandaca',
    sourceCode: 'NL',
    targetCode: 'NL',
    ttsCode: 'nl-NL',
  ),
  LanguageOption(
    name: 'Arapça',
    sourceCode: 'AR',
    targetCode: 'AR',
    ttsCode: 'ar-SA',
  ),
  LanguageOption(
    name: 'İspanyolca',
    sourceCode: 'ES',
    targetCode: 'ES',
    ttsCode: 'es-ES',
  ),
  LanguageOption(
    name: 'Çince',
    sourceCode: 'ZH',
    targetCode: 'ZH',
    ttsCode: 'zh-CN',
  ),
  LanguageOption(
    name: 'Rusça',
    sourceCode: 'RU',
    targetCode: 'RU',
    ttsCode: 'ru-RU',
  ),
  LanguageOption(
    name: 'Ukraynaca',
    sourceCode: 'UK',
    targetCode: 'UK',
    ttsCode: 'uk-UA',
  ),
  LanguageOption(
    name: 'Gürcüce',
    sourceCode: 'KA',
    targetCode: 'KA',
    ttsCode: 'ka-GE',
  ),
];

List<String> get bridgeCallLanguageNames =>
    bridgeCallLanguages.map((language) => language.name).toList();

Map<String, String> get bridgeCallSourceLanguages => {
  for (final language in bridgeCallLanguages)
    language.name: language.sourceCode,
};

Map<String, String> get bridgeCallTargetLanguages => {
  for (final language in bridgeCallLanguages)
    language.name: language.targetCode,
};

String bridgeCallTtsCode(String? backendLang) {
  final normalized = (backendLang ?? '').toUpperCase();
  return bridgeCallLanguages
      .firstWhere(
        (language) =>
            language.sourceCode == normalized ||
            language.targetCode == normalized,
        orElse: () => bridgeCallLanguages[1],
      )
      .ttsCode;
}
