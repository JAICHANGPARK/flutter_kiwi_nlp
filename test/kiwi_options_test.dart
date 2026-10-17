// Verifies option bit-mask composition and request option defaults.
import 'package:flutter_kiwi_nlp/src/kiwi_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KiwiBuildOption', () {
    test('defaultOption composes expected flags', () {
      const int expected =
          KiwiBuildOption.integrateAllomorph |
          KiwiBuildOption.loadDefaultDict |
          KiwiBuildOption.loadTypoDict |
          KiwiBuildOption.loadMultiDict |
          KiwiBuildOption.modelTypeCong;

      expect(KiwiBuildOption.defaultOption, expected);
    });
  });

  group('KiwiMatchOption', () {
    test('all includes base token matching flags including emoji', () {
      const int expected =
          KiwiMatchOption.url |
          KiwiMatchOption.email |
          KiwiMatchOption.hashtag |
          KiwiMatchOption.mention |
          KiwiMatchOption.serial |
          KiwiMatchOption.emoji |
          KiwiMatchOption.zCoda;

      expect(KiwiMatchOption.all, expected);
    });

    test('allWithNormalizing adds normalizeCoda', () {
      expect(
        KiwiMatchOption.allWithNormalizing,
        KiwiMatchOption.all | KiwiMatchOption.normalizeCoda,
      );
    });

    test('exposes v0.24.0 match option constants and composite masks', () {
      expect(KiwiMatchOption.none, 0);
      expect(KiwiMatchOption.emoji, 1 << 5);
      expect(KiwiMatchOption.oovRuleOnly, 0 << 8);
      expect(KiwiMatchOption.oovChrModel, 1 << 8);
      expect(KiwiMatchOption.oovChrFreqModel, 2 << 8);
      expect(KiwiMatchOption.oovChrFreqBranchModel, 3 << 8);
      expect(KiwiMatchOption.oovMask, 3 << 8);
      expect(
        KiwiMatchOption.joinVSuffix,
        KiwiMatchOption.joinVerbSuffix | KiwiMatchOption.joinAdjSuffix,
      );
      expect(
        KiwiMatchOption.joinAffix,
        KiwiMatchOption.joinNounPrefix |
            KiwiMatchOption.joinNounSuffix |
            KiwiMatchOption.joinVSuffix |
            KiwiMatchOption.joinAdvSuffix,
      );
      expect(KiwiMatchOption.joinParticleYo, 1 << 27);
      expect(KiwiMatchOption.useOldSplitter, 1 << 30);
    });
  });

  group('KiwiAnalyzeOptions', () {
    test('uses defaults', () {
      const KiwiAnalyzeOptions options = KiwiAnalyzeOptions();

      expect(options.topN, 1);
      expect(options.matchOptions, KiwiMatchOption.allWithNormalizing);
    });

    test('allows custom values', () {
      const KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
        topN: 5,
        matchOptions: KiwiMatchOption.email | KiwiMatchOption.hashtag,
      );

      expect(options.topN, 5);
      expect(
        options.matchOptions,
        KiwiMatchOption.email | KiwiMatchOption.hashtag,
      );
    });
  });
}
