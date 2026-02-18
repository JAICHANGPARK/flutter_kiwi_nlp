import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kiwi_nlp_example/src/features/analyzer/kiwi_analyzer_view_model.dart';
import 'package:flutter_kiwi_nlp_example/src/features/analyzer/kiwi_pos_tag_dictionary_sheet.dart';
import 'package:flutter_kiwi_nlp_example/src/features/analyzer/kiwi_settings_sheet.dart';

// Verifies stable mobile snapshots for key helper sheets in the demo app.
const Size _mobileSurfaceSize = Size(390, 844);

Future<void> _setMobileSurfaceSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_mobileSurfaceSize);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Disable dynamic shadows to reduce pixel noise across host environments.
    debugDisableShadows = true;
  });

  tearDownAll(() {
    debugDisableShadows = false;
  });

  testWidgets('golden: settings sheet (mobile)', (WidgetTester tester) async {
    await _setMobileSurfaceSize(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final KiwiAnalyzerViewModel viewModel = KiwiAnalyzerViewModel();
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KiwiSettingsSheet(viewModel: viewModel)),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/kiwi_settings_sheet_mobile.png'),
    );
  });

  testWidgets('golden: settings sheet social preset (mobile)', (
    WidgetTester tester,
  ) async {
    await _setMobileSurfaceSize(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final KiwiAnalyzerViewModel viewModel = KiwiAnalyzerViewModel();
    addTearDown(viewModel.dispose);
    // Exercise a non-default preset to capture extra toggle states in baseline.
    viewModel.setSelectedPreset('social');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KiwiSettingsSheet(viewModel: viewModel)),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/kiwi_settings_sheet_social_mobile.png'),
    );
  });

  testWidgets('golden: pos tag dictionary sheet (mobile)', (
    WidgetTester tester,
  ) async {
    await _setMobileSurfaceSize(tester);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: KiwiPosTagDictionarySheet(initialQuery: 'NN')),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/kiwi_pos_tag_dictionary_sheet_mobile.png'),
    );
  });
}
