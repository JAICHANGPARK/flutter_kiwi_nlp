import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

const String _corpusAssetDefine = String.fromEnvironment(
  'KIWI_BENCH_CORPUS_ASSET',
  defaultValue: 'assets/benchmark_corpus_ko.txt',
);
const String _modelPathDefine = String.fromEnvironment(
  'KIWI_BENCH_MODEL_PATH',
  defaultValue: '',
);
const String _outputPathDefine = String.fromEnvironment(
  'KIWI_BENCH_OUTPUT_PATH',
  defaultValue: '',
);
const String _warmupRunsDefine = String.fromEnvironment(
  'KIWI_BENCH_WARMUP_RUNS',
  defaultValue: '3',
);
const String _measureRunsDefine = String.fromEnvironment(
  'KIWI_BENCH_MEASURE_RUNS',
  defaultValue: '15',
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
  // 1039 = KiwiBuildOption.defaultOption with modelTypeCong.
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
    // 8454175 = KiwiMatchOption.allWithNormalizing.
    defaultValue: '8454175',
  ),
);
const String _trialIdDefine = String.fromEnvironment(
  'KIWI_BENCH_TRIAL_ID',
  defaultValue: '0',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final _BenchmarkConfig config = _BenchmarkConfig.fromDefines();
  try {
    final _BenchmarkResult result = await _runBenchmark(config);
    final Map<String, Object> payload = result.toJson();
    final String encoded = jsonEncode(payload);
    final String marker = 'KIWI_BENCHMARK_JSON=$encoded';
    // stdout is reliable on desktop, while print is more reliable on
    // mobile/web device logs consumed by `flutter run`.
    // ignore: avoid_print
    print(marker);
    stdout.writeln(marker);

    if (config.outputPath.isNotEmpty) {
      await _tryWritePayload(config.outputPath, payload);
    }

    exit(0);
  } catch (error, stackTrace) {
    final String marker = 'KIWI_BENCHMARK_ERROR=$error';
    // ignore: avoid_print
    print(marker);
    stderr.writeln(marker);
    stderr.writeln(stackTrace);
    exitCode = 1;
    exit(1);
  }
}

class _BenchmarkConfig {
  const _BenchmarkConfig({
    required this.corpusAssetPath,
    required this.modelPath,
    required this.outputPath,
    required this.warmupRuns,
    required this.measureRuns,
    required this.topN,
    required this.numThreads,
    required this.buildOptions,
    required this.createMatchOptions,
    required this.analyzeMatchOptions,
    required this.trialId,
  });

  final String corpusAssetPath;
  final String modelPath;
  final String outputPath;
  final int warmupRuns;
  final int measureRuns;
  final int topN;
  final int numThreads;
  final int buildOptions;
  final int createMatchOptions;
  final int analyzeMatchOptions;
  final int trialId;

  factory _BenchmarkConfig.fromDefines() {
    return _BenchmarkConfig(
      corpusAssetPath: _corpusAssetDefine,
      modelPath: _modelPathDefine,
      outputPath: _outputPathDefine,
      warmupRuns: _parseInt(_warmupRunsDefine, fallback: 3, minimum: 0),
      measureRuns: _parseInt(_measureRunsDefine, fallback: 15, minimum: 1),
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
      trialId: _parseInt(_trialIdDefine, fallback: 0, minimum: 0),
    );
  }
}

class _RunStats {
  const _RunStats({
    required this.elapsedMs,
    required this.totalAnalyses,
    required this.totalChars,
    required this.totalTokens,
  });

  final double elapsedMs;
  final int totalAnalyses;
  final int totalChars;
  final int totalTokens;
}

class _BenchmarkResult {
  const _BenchmarkResult({
    required this.platform,
    required this.warmupRuns,
    required this.measureRuns,
    required this.topN,
    required this.numThreads,
    required this.buildOptions,
    required this.createMatchOptions,
    required this.analyzeMatchOptions,
    required this.trialId,
    required this.sentenceCount,
    required this.initMs,
    required this.elapsedMs,
    required this.totalAnalyses,
    required this.totalChars,
    required this.totalTokens,
  });

  final String platform;
  final int warmupRuns;
  final int measureRuns;
  final int topN;
  final int numThreads;
  final int buildOptions;
  final int createMatchOptions;
  final int analyzeMatchOptions;
  final int trialId;
  final int sentenceCount;
  final double initMs;
  final double elapsedMs;
  final int totalAnalyses;
  final int totalChars;
  final int totalTokens;

  Map<String, Object> toJson() {
    final double elapsedSeconds = elapsedMs / 1000.0;
    final double analysesPerSec = _safeDivide(totalAnalyses, elapsedSeconds);
    final double charsPerSec = _safeDivide(totalChars, elapsedSeconds);
    final double tokensPerSec = _safeDivide(totalTokens, elapsedSeconds);
    final double avgLatencyMs = _safeDivide(elapsedMs, totalAnalyses);
    final double avgTokenLatencyUs = _safeDivide(
      elapsedMs * 1000.0,
      totalTokens,
    );

    return <String, Object>{
      'runtime': 'flutter_kiwi_nlp',
      'platform': platform,
      'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
      'warmup_runs': warmupRuns,
      'measure_runs': measureRuns,
      'top_n': topN,
      'num_threads': numThreads,
      'build_options': buildOptions,
      'create_match_options': createMatchOptions,
      'analyze_match_options': analyzeMatchOptions,
      'trial_id': trialId,
      'sentence_count': sentenceCount,
      'init_ms': initMs,
      'elapsed_ms': elapsedMs,
      'total_analyses': totalAnalyses,
      'total_chars': totalChars,
      'total_tokens': totalTokens,
      'analyses_per_sec': analysesPerSec,
      'chars_per_sec': charsPerSec,
      'tokens_per_sec': tokensPerSec,
      'avg_latency_ms': avgLatencyMs,
      'avg_token_latency_us': avgTokenLatencyUs,
    };
  }
}

Future<_BenchmarkResult> _runBenchmark(_BenchmarkConfig config) async {
  final List<String> sentences = await _loadSentences(config.corpusAssetPath);

  final Stopwatch initStopwatch = Stopwatch()..start();
  final KiwiAnalyzer analyzer = await _createAnalyzer(config);
  initStopwatch.stop();

  try {
    final KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
      topN: config.topN,
      matchOptions: config.analyzeMatchOptions,
    );

    await _executeRuns(
      analyzer: analyzer,
      sentences: sentences,
      runs: config.warmupRuns,
      options: options,
    );

    final _RunStats measured = await _executeRuns(
      analyzer: analyzer,
      sentences: sentences,
      runs: config.measureRuns,
      options: options,
    );

    return _BenchmarkResult(
      platform: Platform.operatingSystem,
      warmupRuns: config.warmupRuns,
      measureRuns: config.measureRuns,
      topN: config.topN,
      numThreads: config.numThreads,
      buildOptions: config.buildOptions,
      createMatchOptions: config.createMatchOptions,
      analyzeMatchOptions: config.analyzeMatchOptions,
      trialId: config.trialId,
      sentenceCount: sentences.length,
      initMs: initStopwatch.elapsedMicroseconds / 1000.0,
      elapsedMs: measured.elapsedMs,
      totalAnalyses: measured.totalAnalyses,
      totalChars: measured.totalChars,
      totalTokens: measured.totalTokens,
    );
  } finally {
    await analyzer.close();
  }
}

Future<KiwiAnalyzer> _createAnalyzer(_BenchmarkConfig config) {
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

Future<List<String>> _loadSentences(String corpusAssetPath) async {
  final String corpusText = await rootBundle.loadString(corpusAssetPath);
  final List<String> sentences = corpusText
      .split('\n')
      .map((String sentence) => sentence.trim())
      .where((String sentence) => sentence.isNotEmpty)
      .toList(growable: false);

  if (sentences.isEmpty) {
    throw StateError('Corpus is empty: $corpusAssetPath');
  }

  return sentences;
}

Future<_RunStats> _executeRuns({
  required KiwiAnalyzer analyzer,
  required List<String> sentences,
  required int runs,
  required KiwiAnalyzeOptions options,
}) async {
  int totalAnalyses = 0;
  int totalChars = 0;
  int totalTokens = 0;

  final Stopwatch stopwatch = Stopwatch()..start();

  for (int runIndex = 0; runIndex < runs; runIndex += 1) {
    for (final String sentence in sentences) {
      final KiwiAnalyzeResult result = await analyzer.analyze(
        sentence,
        options: options,
      );
      totalAnalyses += 1;
      totalChars += sentence.runes.length;
      totalTokens += _tokenCountOfBestCandidate(result);
    }
  }

  stopwatch.stop();

  return _RunStats(
    elapsedMs: stopwatch.elapsedMicroseconds / 1000.0,
    totalAnalyses: totalAnalyses,
    totalChars: totalChars,
    totalTokens: totalTokens,
  );
}

int _tokenCountOfBestCandidate(KiwiAnalyzeResult result) {
  if (result.candidates.isEmpty) {
    return 0;
  }

  return result.candidates.first.tokens.length;
}

double _safeDivide(num numerator, num denominator) {
  if (denominator <= 0) {
    return 0;
  }

  return numerator / denominator;
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
    stderr.writeln('KIWI_BENCHMARK_WARN=Failed to write output: $error');
  }
}
