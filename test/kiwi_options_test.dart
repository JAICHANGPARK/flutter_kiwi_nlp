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
    test('all includes base token matching flags', () {
      const int expected =
          KiwiMatchOption.url |
          KiwiMatchOption.email |
          KiwiMatchOption.hashtag |
          KiwiMatchOption.mention |
          KiwiMatchOption.serial |
          KiwiMatchOption.zCoda;

      expect(KiwiMatchOption.all, expected);
    });

    test('allWithNormalizing adds normalizeCoda', () {
      expect(
        KiwiMatchOption.allWithNormalizing,
        KiwiMatchOption.all | KiwiMatchOption.normalizeCoda,
      );
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
