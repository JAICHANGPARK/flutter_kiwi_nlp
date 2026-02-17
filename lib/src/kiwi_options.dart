/// Build-time option flags used by `KiwiAnalyzer.create`.
abstract final class KiwiBuildOption {
  /// Enables allomorph integration.
  static const int integrateAllomorph = 1;

  /// Loads the default dictionary.
  static const int loadDefaultDict = 2;

  /// Loads typo correction dictionary data.
  static const int loadTypoDict = 4;

  /// Loads multi-word dictionary data.
  static const int loadMultiDict = 8;

  /// Uses backend default model type.
  static const int modelTypeDefault = 0x0000;

  /// Uses the largest model variant.
  static const int modelTypeLargest = 0x0100;

  /// Uses KNLM model variant.
  static const int modelTypeKnlm = 0x0200;

  /// Uses SBG model variant.
  static const int modelTypeSbg = 0x0300;

  /// Uses CONG model variant.
  static const int modelTypeCong = 0x0400;

  /// Uses global CONG model variant.
  static const int modelTypeCongGlobal = 0x0500;

  /// The recommended default option bundle.
  static const int defaultOption =
      integrateAllomorph |
      loadDefaultDict |
      loadTypoDict |
      loadMultiDict |
      modelTypeCong;
}

/// Match option flags used by `KiwiAnalyzer.create` and [KiwiAnalyzeOptions].
abstract final class KiwiMatchOption {
  /// Detects URLs.
  static const int url = 1;

  /// Detects email addresses.
  static const int email = 2;

  /// Detects hashtags.
  static const int hashtag = 4;

  /// Detects mentions.
  static const int mention = 8;

  /// Detects serial-like tokens.
  static const int serial = 16;

  /// Normalizes final consonants.
  static const int normalizeCoda = 1 << 16;

  /// Joins noun prefixes.
  static const int joinNounPrefix = 1 << 17;

  /// Joins noun suffixes.
  static const int joinNounSuffix = 1 << 18;

  /// Joins verb suffixes.
  static const int joinVerbSuffix = 1 << 19;

  /// Joins adjective suffixes.
  static const int joinAdjSuffix = 1 << 20;

  /// Joins adverb suffixes.
  static const int joinAdvSuffix = 1 << 21;

  /// Splits complex forms.
  static const int splitComplex = 1 << 22;

  /// Enables coda-related matching behavior.
  static const int zCoda = 1 << 23;

  /// Uses compatibility jamo output.
  static const int compatibleJamo = 1 << 24;

  /// Splits sai-sios spelling forms.
  static const int splitSaisiot = 1 << 25;

  /// Merges sai-sios spelling forms.
  static const int mergeSaisiot = 1 << 26;

  /// A baseline bundle for URL/email/hashtag/mention/serial/coda matching.
  static const int all = url | email | hashtag | mention | serial | zCoda;

  /// [all] plus [normalizeCoda].
  static const int allWithNormalizing = all | normalizeCoda;
}

/// Per-request options for `KiwiAnalyzer.analyze`.
class KiwiAnalyzeOptions {
  /// The number of analysis candidates to return.
  final int topN;

  /// Bitwise [KiwiMatchOption] flags applied during analysis.
  final int matchOptions;

  /// Creates analysis options.
  ///
  /// The default configuration uses one candidate and
  /// [KiwiMatchOption.allWithNormalizing].
  const KiwiAnalyzeOptions({
    this.topN = 1,
    this.matchOptions = KiwiMatchOption.allWithNormalizing,
  });
}
