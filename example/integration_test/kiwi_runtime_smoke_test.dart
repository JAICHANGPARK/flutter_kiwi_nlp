// Verifies basic analyzer create-analyze-close flow on real runtime targets.
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Kiwi runtime smoke: create, analyze, close',
    (WidgetTester tester) async {
      final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();
      addTearDown(() async {
        try {
          await analyzer.close();
        } catch (_) {
          // Ignore secondary close errors in teardown.
        }
      });

      final KiwiAnalyzeResult result = await analyzer.analyze(
        '안녕하세요. 형태소 분석 스모크 테스트입니다.',
      );

      expect(result.candidates, isNotEmpty);
      expect(result.candidates.first.tokens, isNotEmpty);
      expect(result.candidates.first.tokens.first.form, isNotEmpty);

      await analyzer.close();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
