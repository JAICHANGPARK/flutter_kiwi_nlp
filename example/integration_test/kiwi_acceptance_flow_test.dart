import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_kiwi_nlp_example/src/app.dart';

// Verifies a mobile-sized end-to-end user flow in the analyzer demo app.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 90),
  Duration step = const Duration(milliseconds: 200),
}) async {
  // Poll with small pumps instead of fixed sleeps to keep the test stable on
  // both simulator and emulator builds.
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (condition()) {
      return;
    }
  }
  throw TestFailure('Timed out while waiting for UI to reach expected state.');
}

Future<void> _openCompactResultTabIfPresent(WidgetTester tester) async {
  // The compact layout splits input/result panes behind tabs.
  final Finder resultTab = find.descendant(
    of: find.byType(TabBar),
    matching: find.text('결과'),
  );
  if (resultTab.evaluate().isEmpty) {
    return;
  }
  await tester.tap(resultTab.first);
  await tester.pumpAndSettle();
}

Future<void> _tapVisibleRunButton(WidgetTester tester) async {
  // The same action uses different labels depending on where the CTA is shown.
  final Finder runSelected = find.widgetWithText(FilledButton, '선택 예제 실행');
  if (runSelected.evaluate().isNotEmpty) {
    await tester.tap(runSelected.first);
    await tester.pump();
    return;
  }

  final Finder runQuick = find.widgetWithText(FilledButton, '선택 예제 바로 실행');
  expect(runQuick, findsOneWidget);
  await tester.tap(runQuick);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'acceptance flow: analyze scenario, clear results, open helper sheets',
    (WidgetTester tester) async {
      // Force a phone viewport to exercise the same UI density as iOS/Android.
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const KiwiDemoApp());
      await tester.pump();

      // Wait until analyzer initialization finishes before asserting UI state.
      await _pumpUntil(
        tester,
        () => find.textContaining('엔진: native').evaluate().isNotEmpty,
      );

      await _openCompactResultTabIfPresent(tester);
      expect(find.text('분석 결과가 여기에 표시됩니다.'), findsOneWidget);

      await _tapVisibleRunButton(tester);

      await _pumpUntil(
        tester,
        () =>
            find.text('분석 결과가 여기에 표시됩니다.').evaluate().isEmpty &&
            (find.byType(ActionChip).evaluate().isNotEmpty ||
                find.text('(결과 없음)').evaluate().isNotEmpty),
      );
      expect(find.text('분석 결과가 여기에 표시됩니다.'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, '지우기'));
      await tester.pumpAndSettle();
      expect(find.text('분석 결과가 여기에 표시됩니다.'), findsOneWidget);

      await tester.tap(find.byTooltip('설정'));
      await tester.pumpAndSettle();
      expect(find.text('분석 설정'), findsOneWidget);
      expect(find.text('모델 경로'), findsOneWidget);

      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('분석 설정'), findsNothing);

      await tester.tap(find.byTooltip('품사 사전'));
      await tester.pumpAndSettle();
      expect(find.text('품사 태그 사전'), findsOneWidget);
      expect(find.text('태그/설명 검색'), findsOneWidget);

      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('품사 태그 사전'), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
