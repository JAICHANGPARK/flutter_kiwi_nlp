import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';
import 'package:flutter_kiwi_nlp/src/kiwi_analyzer_native.dart' as native;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'macOS ffi runtime path: create, path probe, analyze, close',
    (WidgetTester tester) async {
      expect(Platform.isMacOS, isTrue);

      final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();
      addTearDown(() async {
        try {
          await analyzer.close();
        } catch (_) {
          // Ignore secondary close errors from teardown.
        }
      });

      final List<String> candidates = native
          .debugKiwiNativeLibraryCandidatesForTest();
      final String? loadedCandidate = native
          .debugKiwiNativeLoadedLibraryCandidateForTest();

      expect(candidates, isNotEmpty);
      expect(loadedCandidate, isNotNull);
      expect(candidates, contains(loadedCandidate));
      expect(
        candidates,
        contains('flutter_kiwi_nlp.framework/flutter_kiwi_nlp'),
      );
      expect(
        candidates,
        contains('flutter_kiwi_ffi.framework/flutter_kiwi_ffi'),
      );

      debugPrint('[runtime/native] candidates=$candidates');
      debugPrint('[runtime/native] loadedCandidate=$loadedCandidate');

      final KiwiAnalyzeResult result = await analyzer.analyze(
        '안녕하세요. macOS FFI 경로 확인 테스트입니다.',
      );
      expect(result.candidates, isNotEmpty);
      expect(result.candidates.first.tokens, isNotEmpty);

      await analyzer.close();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
