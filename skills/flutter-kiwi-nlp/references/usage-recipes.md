# Flutter Kiwi NLP Usage Recipes (for AI Agents)

Use these patterns when integrating `flutter_kiwi_nlp` into a Flutter app or
generating Korean NLP code on Android, iOS, macOS, Linux, Windows, or Web.

## 1. Installation & Import

Add the dependency:

```bash
flutter pub add flutter_kiwi_nlp
```

Single public entrypoint import:

```dart
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';
```

> Do NOT import internal files under `package:flutter_kiwi_nlp/src/...`.

## 2. Analyzer Lifecycle & Reuse Rules

`KiwiAnalyzer.create()` loads and initializes the Kiwi morphological model
(extracting bundled assets on native or loading WASM + model archives on web).

- **Create once and reuse**: Never call `KiwiAnalyzer.create()` inside a
  widget's `build()` method or per keystroke.
- **Always call `close()`**: Release native FFI handles / web WASM memory when
  the owner (`State`, `ChangeNotifier`, or service) is disposed.

### Minimal Service / ChangeNotifier Pattern

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

class KoreanNlpController extends ChangeNotifier {
  KiwiAnalyzer? _analyzer;
  bool _isReady = false;
  String? _errorMessage;

  bool get isReady => _isReady;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_analyzer != null) return;
    try {
      _analyzer = await KiwiAnalyzer.create();
      _isReady = true;
      _errorMessage = null;
    } on KiwiException catch (e) {
      _errorMessage = e.message;
    } finally {
      notifyListeners();
    }
  }

  Future<KiwiAnalyzeResult> analyzeText(String text, {int topN = 1}) async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null) {
      throw const KiwiException('KiwiAnalyzer is not initialized.');
    }
    return analyzer.analyze(
      text,
      options: KiwiAnalyzeOptions(topN: topN),
    );
  }

  @override
  void dispose() {
    final KiwiAnalyzer? analyzer = _analyzer;
    _analyzer = null;
    if (analyzer != null) {
      analyzer.close();
    }
    super.dispose();
  }
}
```

## 3. Core NLP Operations

### A. Morphological Analysis (`analyze` & `analyzeBatch`)

```dart
final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();

// Single sentence analysis
final KiwiAnalyzeResult result = await analyzer.analyze(
  '아버지가방에들어가신다.',
  options: const KiwiAnalyzeOptions(
    topN: 1,
    matchOptions: KiwiMatchOption.allWithNormalizing,
  ),
);

if (result.candidates.isNotEmpty) {
  for (final KiwiToken token in result.candidates.first.tokens) {
    // token.form: surface form (e.g. '아버지')
    // token.tag: POS tag (e.g. 'NNG', 'JKS', 'VV', 'EF')
    // token.start, token.length: UTF-16 character offset and length
    // token.wordPosition, token.sentPosition: word and sentence index
    debugPrint('${token.form}/${token.tag} (${token.start}..${token.start + token.length})');
  }
}

// Batch analysis (preserves input order, faster for multiple sentences on native)
final List<KiwiAnalyzeResult> batchResults = await analyzer.analyzeBatch(
  <String>[
    '첫 번째 문장입니다.',
    '두 번째 문장도 빠르게 분석합니다.',
  ],
);
```

### B. Runtime User Dictionary (`addUserWord`)

Add domain-specific nouns, brand names, or neologisms at runtime before
analyzing:

```dart
await analyzer.addUserWord(
  '플러터키위',
  tag: 'NNP', // Proper noun (default: 'NNP')
  score: 3.0,
);
```

### C. Spacing Correction (`space`)

Correct Korean spacing errors automatically:

```dart
// Preserves existing whitespace while inserting missing spaces
final String spaced = await analyzer.space('띄어쓰기없이작성된텍스트네이것을교정해줘.');
// -> '띄어쓰기 없이 작성된 텍스트네 이것을 교정해 줘.'

// Reset existing whitespace before re-spacing
final String resetSpaced = await analyzer.space(
  '띄어 쓰기 가 이상 한 문장',
  resetWhitespace: true,
);
```

### D. Context-Aware Chunk Joining (`glue`)

Join text chunks or line-broken OCR/LLM segments while automatically deciding
whether a space is needed between adjacent chunks:

```dart
final KiwiGlueResult glued = await analyzer.glue(<String>[
  '그러나  알고보니 그 봉',
  '투 안에 있던 것은 바로',
  ' 레몬이었던 것이다.',
]);

debugPrint(glued.text);
// -> '그러나 알고보니 그 봉투 안에 있던 것은 바로 레몬이었던 것이다.'
debugPrint('${glued.spaceInsertions}');
// -> [false, true] (length is chunks.length - 1)

// Optional newline control per chunk boundary (length must be chunks.length - 1)
final KiwiGlueResult gluedWithNewline = await analyzer.glue(
  <String>['첫째 줄', '둘째 줄'],
  insertNewLines: <bool>[true],
);
```

## 4. Customizing Match & Build Options

Combine bit flags with `|`:

```dart
final int matchOptions = KiwiMatchOption.allWithNormalizing |
    KiwiMatchOption.splitSaisiot |
    KiwiMatchOption.joinParticleYo;

final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
  buildOptions: KiwiBuildOption.defaultOption,
  matchOptions: matchOptions,
);
```

Common `KiwiMatchOption` flags:
- `KiwiMatchOption.allWithNormalizing` (default)
- `KiwiMatchOption.url`, `email`, `hashtag`, `mention`, `serial`, `emoji`
- `KiwiMatchOption.normalizeCoda`
- `KiwiMatchOption.splitComplex`, `zCoda`, `compatibleJamo`
- `KiwiMatchOption.splitSaisiot`, `mergeSaisiot`
- `KiwiMatchOption.joinParticleYo`, `useOldSplitter`
- OOV handling: `oovRuleOnly`, `oovChrModel`, `oovChrFreqModel`,
  `oovChrFreqBranchModel`

## 5. Custom Model Paths

By default, `KiwiAnalyzer.create()` uses the built-in `assets/kiwi-models/cong/base`
model automatically. Only pass `modelPath` or `assetModelPath` when using a
custom model:

```dart
// From Flutter asset bundle
final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
  assetModelPath: 'assets/my_custom_kiwi_model',
);

// From local filesystem directory (native) or base URL (web)
final KiwiAnalyzer customAnalyzer = await KiwiAnalyzer.create(
  modelPath: '/path/to/kiwi/model',
);
```
