import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public export exposes options', () {
    expect(KiwiBuildOption.defaultOption, isNonZero);
    expect(KiwiMatchOption.allWithNormalizing, isNonZero);
  });

  test('create surfaces backend init error on test runtime', () async {
    await expectLater(
      KiwiAnalyzer.create(modelPath: '/definitely/not/exist/model'),
      throwsA(anyOf(isA<KiwiException>(), isA<ArgumentError>())),
    );
  });
}
