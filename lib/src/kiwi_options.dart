abstract final class KiwiBuildOption {
  static const int integrateAllomorph = 1;
  static const int loadDefaultDict = 2;
  static const int loadTypoDict = 4;
  static const int loadMultiDict = 8;
  static const int modelTypeDefault = 0x0000;
  static const int modelTypeLargest = 0x0100;
  static const int modelTypeKnlm = 0x0200;
  static const int modelTypeSbg = 0x0300;
  static const int modelTypeCong = 0x0400;
  static const int modelTypeCongGlobal = 0x0500;
  static const int defaultOption =
      integrateAllomorph |
      loadDefaultDict |
      loadTypoDict |
      loadMultiDict |
      modelTypeCong;
}

abstract final class KiwiMatchOption {
  static const int url = 1;
  static const int email = 2;
  static const int hashtag = 4;
  static const int mention = 8;
  static const int serial = 16;
  static const int normalizeCoda = 1 << 16;
  static const int joinNounPrefix = 1 << 17;
  static const int joinNounSuffix = 1 << 18;
  static const int joinVerbSuffix = 1 << 19;
  static const int joinAdjSuffix = 1 << 20;
  static const int joinAdvSuffix = 1 << 21;
  static const int splitComplex = 1 << 22;
  static const int zCoda = 1 << 23;
  static const int compatibleJamo = 1 << 24;
  static const int splitSaisiot = 1 << 25;
  static const int mergeSaisiot = 1 << 26;

  static const int all = url | email | hashtag | mention | serial | zCoda;
  static const int allWithNormalizing = all | normalizeCoda;
}

class KiwiAnalyzeOptions {
  final int topN;
  final int matchOptions;

  const KiwiAnalyzeOptions({
    this.topN = 1,
    this.matchOptions = KiwiMatchOption.allWithNormalizing,
  });
}
