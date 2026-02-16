import 'package:flutter/material.dart';

import 'features/analyzer/kiwi_analyzer_page.dart';

class KiwiDemoApp extends StatelessWidget {
  const KiwiDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiwi Morph Analyzer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4D7C0F)),
        useMaterial3: true,
      ),
      home: const KiwiAnalyzerPage(),
    );
  }
}
