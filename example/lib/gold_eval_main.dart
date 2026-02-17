import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

const String _goldAssetDefine = String.fromEnvironment(
  'KIWI_GOLD_ASSET',
  defaultValue: 'assets/gold_eval_web_ko.txt',
);
const String _datasetNameDefine = String.fromEnvironment(
  'KIWI_GOLD_DATASET_NAME',
  defaultValue: '',
);
const String _modelPathDefine = String.fromEnvironment(
  'KIWI_BENCH_MODEL_PATH',
  defaultValue: '',
);
const String _outputPathDefine = String.fromEnvironment(
  'KIWI_EVAL_OUTPUT_PATH',
  defaultValue: '',
);
const String _topNDefine = String.fromEnvironment(
  'KIWI_BENCH_TOP_N',
  defaultValue: '1',
);
const String _numThreadsDefine = String.fromEnvironment(
  'KIWI_BENCH_NUM_THREADS',
  defaultValue: '-1',
);
const String _buildOptionsDefine = String.fromEnvironment(
  'KIWI_BENCH_BUILD_OPTIONS',
  defaultValue: '1039',
);
const String _createMatchOptionsDefine = String.fromEnvironment(
  'KIWI_BENCH_CREATE_MATCH_OPTIONS',
  defaultValue: String.fromEnvironment(
    'KIWI_BENCH_MATCH_OPTIONS',
    defaultValue: '8454175',
  ),
);
const String _analyzeMatchOptionsDefine = String.fromEnvironment(
  'KIWI_BENCH_ANALYZE_MATCH_OPTIONS',
  defaultValue: String.fromEnvironment(
    'KIWI_BENCH_MATCH_OPTIONS',
    defaultValue: '8454175',
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final _GoldEvalConfig config = _GoldEvalConfig.fromDefines();

  try {
    final _GoldEvalResult result = await _runGoldEval(config);
    final Map<String, Object> payload = result.toJson();
    final String encoded = jsonEncode(payload);
    final String marker = 'KIWI_GOLD_EVAL_JSON=$encoded';
    // ignore: avoid_print
    print(marker);
    stdout.writeln(marker);

    if (config.outputPath.isNotEmpty) {
      await _tryWritePayload(config.outputPath, payload);
    }

    exit(0);
  } catch (error, stackTrace) {
    final String marker = 'KIWI_GOLD_EVAL_ERROR=$error';
    // ignore: avoid_print
    print(marker);
    stderr.writeln(marker);
    stderr.writeln(stackTrace);
    exitCode = 1;
    exit(1);
  }
}

class _GoldEvalConfig {
  const _GoldEvalConfig({
    required this.goldAssetPath,
    required this.datasetName,
    required this.modelPath,
    required this.outputPath,
    required this.topN,
    required this.numThreads,
    required this.buildOptions,
    required this.createMatchOptions,
    required this.analyzeMatchOptions,
  });

  final String goldAssetPath;
  final String datasetName;
  final String modelPath;
  final String outputPath;
  final int topN;
  final int numThreads;
  final int buildOptions;
  final int createMatchOptions;
  final int analyzeMatchOptions;

  factory _GoldEvalConfig.fromDefines() {
    final String inferredName = _inferDatasetName(_goldAssetDefine);
    return _GoldEvalConfig(
      goldAssetPath: _goldAssetDefine,
      datasetName: _datasetNameDefine.isEmpty
          ? inferredName
          : _datasetNameDefine,
      modelPath: _modelPathDefine,
      outputPath: _outputPathDefine,
      topN: _parseInt(_topNDefine, fallback: 1, minimum: 1),
      numThreads: _parseInt(_numThreadsDefine, fallback: -1, minimum: -1),
      buildOptions: _parseInt(_buildOptionsDefine, fallback: 1039, minimum: 0),
      createMatchOptions: _parseInt(
        _createMatchOptionsDefine,
        fallback: 8454175,
        minimum: 0,
      ),
      analyzeMatchOptions: _parseInt(
        _analyzeMatchOptionsDefine,
        fallback: 8454175,
        minimum: 0,
      ),
    );
  }
}

class _GoldToken {
  const _GoldToken({required this.form, required this.tag});

  final String form;
  final String tag;

  String pairKey() => '$form/$tag';
}

class _GoldEntry {
  const _GoldEntry({required this.sentence, required this.tokens});

  final String sentence;
  final List<_GoldToken> tokens;
}

class _GoldEvalResult {
  const _GoldEvalResult({
    required this.platform,
    required this.datasetName,
    required this.goldAssetPath,
    required this.topN,
    required this.numThreads,
    required this.buildOptions,
    required this.createMatchOptions,
    required this.analyzeMatchOptions,
    required this.sentenceCount,
    required this.goldTokenCount,
    required this.predictedTokenCount,
    required this.initMs,
    required this.evalElapsedMs,
    required this.tokenEditDistance,
    required this.tokenEditDenominator,
    required this.posEditDistance,
    required this.posEditDenominator,
    required this.tokenExactSentenceCount,
    required this.posExactSentenceCount,
    required this.sampleMismatches,
  });

  final String platform;
  final String datasetName;
  final String goldAssetPath;
  final int topN;
  final int numThreads;
  final int buildOptions;
  final int createMatchOptions;
  final int analyzeMatchOptions;
  final int sentenceCount;
  final int goldTokenCount;
  final int predictedTokenCount;
  final double initMs;
  final double evalElapsedMs;
  final int tokenEditDistance;
  final int tokenEditDenominator;
  final int posEditDistance;
  final int posEditDenominator;
  final int tokenExactSentenceCount;
  final int posExactSentenceCount;
  final List<Map<String, Object>> sampleMismatches;

  Map<String, Object> toJson() {
    return <String, Object>{
      'task': 'gold_eval',
      'runtime': 'flutter_kiwi_nlp',
      'platform': platform,
      'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
      'dataset_name': datasetName,
      'gold_asset': goldAssetPath,
      'top_n': topN,
      'num_threads': numThreads,
      'build_options': buildOptions,
      'create_match_options': createMatchOptions,
      'analyze_match_options': analyzeMatchOptions,
      'sentence_count': sentenceCount,
      'gold_token_count': goldTokenCount,
      'predicted_token_count': predictedTokenCount,
      'init_ms': initMs,
      'eval_elapsed_ms': evalElapsedMs,
      'token_edit_distance': tokenEditDistance,
      'token_edit_denominator': tokenEditDenominator,
      'token_agreement': _safeAgreement(
        distance: tokenEditDistance,
        denominator: tokenEditDenominator,
      ),
      'pos_edit_distance': posEditDistance,
      'pos_edit_denominator': posEditDenominator,
      'pos_agreement': _safeAgreement(
        distance: posEditDistance,
        denominator: posEditDenominator,
      ),
      'token_sequence_exact_count': tokenExactSentenceCount,
      'token_sequence_exact_match': _safeDivide(
        tokenExactSentenceCount,
        sentenceCount,
      ),
      'sentence_exact_count': posExactSentenceCount,
      'sentence_exact_match': _safeDivide(posExactSentenceCount, sentenceCount),
      'sample_mismatches': sampleMismatches,
    };
  }
}

Future<_GoldEvalResult> _runGoldEval(_GoldEvalConfig config) async {
  final List<_GoldEntry> entries = await _loadGoldEntries(config.goldAssetPath);

  final Stopwatch initStopwatch = Stopwatch()..start();
  final KiwiAnalyzer analyzer = await _createAnalyzer(config);
  initStopwatch.stop();

  int goldTokenCount = 0;
  int predictedTokenCount = 0;
  int tokenEditDistance = 0;
  int tokenEditDenominator = 0;
  int posEditDistance = 0;
  int posEditDenominator = 0;
  int tokenExactSentenceCount = 0;
  int posExactSentenceCount = 0;
  final List<Map<String, Object>> sampleMismatches = <Map<String, Object>>[];

  final KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
    topN: config.topN,
    matchOptions: config.analyzeMatchOptions,
  );

  final Stopwatch evalStopwatch = Stopwatch()..start();
  try {
    for (final _GoldEntry entry in entries) {
      final KiwiAnalyzeResult result = await analyzer.analyze(
        entry.sentence,
        options: options,
      );
      final List<_GoldToken> predicted = _bestCandidateTokens(result);

      final List<String> goldForms = entry.tokens
          .map((final _GoldToken token) => token.form)
          .toList(growable: false);
      final List<String> predictedForms = predicted
          .map((final _GoldToken token) => token.form)
          .toList(growable: false);
      final List<String> goldPairs = entry.tokens
          .map((final _GoldToken token) => token.pairKey())
          .toList(growable: false);
      final List<String> predictedPairs = predicted
          .map((final _GoldToken token) => token.pairKey())
          .toList(growable: false);

      final int tokenDenominator = _maxInt(
        goldForms.length,
        predictedForms.length,
      );
      final int posDenominator = _maxInt(
        goldPairs.length,
        predictedPairs.length,
      );
      final int tokenDistance = _levenshteinDistance(goldForms, predictedForms);
      final int posDistance = _levenshteinDistance(goldPairs, predictedPairs);

      goldTokenCount += goldForms.length;
      predictedTokenCount += predictedForms.length;
      tokenEditDistance += tokenDistance;
      tokenEditDenominator += tokenDenominator;
      posEditDistance += posDistance;
      posEditDenominator += posDenominator;

      final bool tokenExact = _listEquals(goldForms, predictedForms);
      final bool posExact = _listEquals(goldPairs, predictedPairs);
      if (tokenExact) {
        tokenExactSentenceCount += 1;
      }
      if (posExact) {
        posExactSentenceCount += 1;
      }

      if (!posExact && sampleMismatches.length < 5) {
        sampleMismatches.add(<String, Object>{
          'sentence': entry.sentence,
          'gold': goldPairs.join(' '),
          'predicted': predictedPairs.join(' '),
        });
      }
    }
  } finally {
    evalStopwatch.stop();
    await analyzer.close();
  }

  return _GoldEvalResult(
    platform: Platform.operatingSystem,
    datasetName: config.datasetName,
    goldAssetPath: config.goldAssetPath,
    topN: config.topN,
    numThreads: config.numThreads,
    buildOptions: config.buildOptions,
    createMatchOptions: config.createMatchOptions,
    analyzeMatchOptions: config.analyzeMatchOptions,
    sentenceCount: entries.length,
    goldTokenCount: goldTokenCount,
    predictedTokenCount: predictedTokenCount,
    initMs: initStopwatch.elapsedMicroseconds / 1000.0,
    evalElapsedMs: evalStopwatch.elapsedMicroseconds / 1000.0,
    tokenEditDistance: tokenEditDistance,
    tokenEditDenominator: tokenEditDenominator,
    posEditDistance: posEditDistance,
    posEditDenominator: posEditDenominator,
    tokenExactSentenceCount: tokenExactSentenceCount,
    posExactSentenceCount: posExactSentenceCount,
    sampleMismatches: sampleMismatches,
  );
}

Future<KiwiAnalyzer> _createAnalyzer(_GoldEvalConfig config) {
  if (config.modelPath.isEmpty) {
    return KiwiAnalyzer.create(
      numThreads: config.numThreads,
      buildOptions: config.buildOptions,
      matchOptions: config.createMatchOptions,
    );
  }

  return KiwiAnalyzer.create(
    modelPath: config.modelPath,
    numThreads: config.numThreads,
    buildOptions: config.buildOptions,
    matchOptions: config.createMatchOptions,
  );
}

Future<List<_GoldEntry>> _loadGoldEntries(String assetPath) async {
  final String text = await rootBundle.loadString(assetPath);
  final List<_GoldEntry> entries = <_GoldEntry>[];

  for (final String rawLine in text.split('\n')) {
    final String line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }

    final int tabIndex = line.indexOf('\t');
    if (tabIndex <= 0 || tabIndex == line.length - 1) {
      continue;
    }

    final String sentence = line.substring(0, tabIndex).trim();
    final String goldRaw = line.substring(tabIndex + 1).trim();
    if (sentence.isEmpty || goldRaw.isEmpty) {
      continue;
    }

    entries.add(
      _GoldEntry(sentence: sentence, tokens: _parseGoldTokens(goldRaw)),
    );
  }

  if (entries.isEmpty) {
    throw StateError('Gold corpus is empty or malformed: $assetPath');
  }

  return entries;
}

List<_GoldToken> _bestCandidateTokens(KiwiAnalyzeResult result) {
  if (result.candidates.isEmpty) {
    return const <_GoldToken>[];
  }

  final List<KiwiToken> tokens = result.candidates.first.tokens;
  return tokens
      .map(
        (final KiwiToken token) => _GoldToken(form: token.form, tag: token.tag),
      )
      .toList(growable: false);
}

List<_GoldToken> _parseGoldTokens(String raw) {
  final List<_GoldToken> tokens = <_GoldToken>[];
  for (final String segment in raw.split(RegExp(r'\s+'))) {
    if (segment.isEmpty) {
      continue;
    }

    final int splitIndex = segment.lastIndexOf('/');
    if (splitIndex <= 0 || splitIndex >= segment.length - 1) {
      tokens.add(_GoldToken(form: segment, tag: 'UNK'));
      continue;
    }

    final String form = segment.substring(0, splitIndex);
    final String tag = segment.substring(splitIndex + 1);
    tokens.add(_GoldToken(form: form, tag: tag));
  }
  return tokens;
}

int _levenshteinDistance(List<String> left, List<String> right) {
  if (left.isEmpty) {
    return right.length;
  }
  if (right.isEmpty) {
    return left.length;
  }

  List<int> previous = List<int>.generate(
    right.length + 1,
    (final int index) => index,
  );

  for (int i = 1; i <= left.length; i += 1) {
    final List<int> current = List<int>.filled(right.length + 1, 0);
    current[0] = i;
    for (int j = 1; j <= right.length; j += 1) {
      final int substitutionCost = left[i - 1] == right[j - 1] ? 0 : 1;
      final int deletion = previous[j] + 1;
      final int insertion = current[j - 1] + 1;
      final int substitution = previous[j - 1] + substitutionCost;
      current[j] = _minInt(_minInt(deletion, insertion), substitution);
    }
    previous = current;
  }

  return previous[right.length];
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

String _inferDatasetName(String assetPath) {
  final int slashIndex = assetPath.lastIndexOf('/');
  final String fileName = slashIndex >= 0
      ? assetPath.substring(slashIndex + 1)
      : assetPath;
  final int dotIndex = fileName.lastIndexOf('.');
  if (dotIndex <= 0) {
    return fileName;
  }
  return fileName.substring(0, dotIndex);
}

int _minInt(int left, int right) => left < right ? left : right;

int _maxInt(int left, int right) => left > right ? left : right;

double _safeDivide(num numerator, num denominator) {
  if (denominator <= 0) {
    return 0;
  }
  return numerator / denominator;
}

double _safeAgreement({required int distance, required int denominator}) {
  if (denominator <= 0) {
    return 0;
  }
  return 1.0 - (distance / denominator);
}

int _parseInt(String rawValue, {required int fallback, required int minimum}) {
  final int? parsed = int.tryParse(rawValue);
  if (parsed == null || parsed < minimum) {
    return fallback;
  }
  return parsed;
}

Future<void> _tryWritePayload(
  String outputPath,
  Map<String, Object> payload,
) async {
  try {
    final File file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  } on FileSystemException catch (error) {
    stderr.writeln('KIWI_GOLD_EVAL_WARN=Failed to write output: $error');
  }
}
