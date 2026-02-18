// Verifies unsupported-platform behavior of the stub analyzer backend.
import 'package:flutter_kiwi_nlp/src/kiwi_analyzer_stub.dart';
import 'package:flutter_kiwi_nlp/src/kiwi_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String unsupportedMessage =
      'flutter_kiwi_nlp native backend is not available on this platform yet.';

  // Matches the exact unsupported-platform message emitted by the stub.
  Matcher hasUnsupportedMessage() {
    return isA<KiwiException>().having(
      (KiwiException error) => error.message,
      'message',
      unsupportedMessage,
    );
  }

  test('create throws unsupported exception on stub backend', () async {
    await expectLater(
      KiwiAnalyzer.create(
        modelPath: 'dummy',
        assetModelPath: 'dummy_asset',
        numThreads: 2,
        buildOptions: 0,
        matchOptions: 0,
      ),
      throwsA(hasUnsupportedMessage()),
    );
  });

  test('instance members throw unsupported exception', () async {
    final KiwiAnalyzer analyzer = KiwiAnalyzer();

    expect(analyzer.nativeVersion, unsupportedMessage);
    await expectLater(
      analyzer.analyze('테스트'),
      throwsA(hasUnsupportedMessage()),
    );
    await expectLater(
      analyzer.analyzeBatch(<String>['테스트']),
      throwsA(hasUnsupportedMessage()),
    );
    await expectLater(
      analyzer.analyzeTokenCount('테스트'),
      throwsA(hasUnsupportedMessage()),
    );
    await expectLater(
      analyzer.analyzeTokenCountBatch(<String>['테스트']),
      throwsA(hasUnsupportedMessage()),
    );
    await expectLater(
      analyzer.analyzeTokenCountBatchRepeated(<String>['테스트']),
      throwsA(hasUnsupportedMessage()),
    );
    await expectLater(
      analyzer.addUserWord('사용자사전'),
      throwsA(hasUnsupportedMessage()),
    );
    await expectLater(analyzer.close(), throwsA(hasUnsupportedMessage()));
  });
}
