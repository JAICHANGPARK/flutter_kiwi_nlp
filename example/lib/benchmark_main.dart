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
const String _analyzeImplDefine = String.fromEnvironment(
  'KIWI_BENCH_ANALYZE_IMPL',
  defaultValue: 'json',
);
const String _sampleCountDefine = String.fromEnvironment(
  'KIWI_BENCH_SAMPLE_COUNT',
  defaultValue: '10',
);
const String _trialIdDefine = String.fromEnvironment(
  'KIWI_BENCH_TRIAL_ID',
  defaultValue: '0',
);
const String _jsonMarker = 'KIWI_BENCHMARK_JSON=';
const String _jsonChunkMarker = 'KIWI_BENCHMARK_JSON_B64_CHUNK=';
const int _jsonChunkSize = 512;
const String _analyzeImplJson = 'json';
const String _analyzeImplTokenCount = 'token_count';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final _BenchmarkConfig config = _BenchmarkConfig.fromDefines();
  try {
    final _BenchmarkResult result = await _runBenchmark(config);
    final Map<String, Object> payload = result.toJson();
    final String encoded = jsonEncode(payload);
    final String marker = '$_jsonMarker$encoded';
    // stdout is reliable on desktop, while print is more reliable on
    // mobile/web device logs consumed by `flutter run`.
    // ignore: avoid_print
    print(marker);
    stdout.writeln(marker);
    _emitChunkedPayload(encoded);

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

void _emitChunkedPayload(String jsonPayload) {
  final String encodedB64 = base64Encode(utf8.encode(jsonPayload));
  if (encodedB64.isEmpty) {
    return;
  }

  final int chunkCount =
      (encodedB64.length + _jsonChunkSize - 1) ~/ _jsonChunkSize;
  for (int chunkIndex = 0; chunkIndex < chunkCount; chunkIndex += 1) {
    final int start = chunkIndex * _jsonChunkSize;
    int end = start + _jsonChunkSize;
    if (end > encodedB64.length) {
      end = encodedB64.length;
    }
    final String chunk = encodedB64.substring(start, end);
    final String marker =
        '$_jsonChunkMarker${chunkIndex + 1}/$chunkCount:$chunk';
    // ignore: avoid_print
    print(marker);
    stdout.writeln(marker);
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
    required this.analyzeImpl,
    required this.sampleCount,
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
  final String analyzeImpl;
  final int sampleCount;
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
      analyzeImpl: _parseAnalyzeImpl(_analyzeImplDefine),
      sampleCount: _parseInt(_sampleCountDefine, fallback: 10, minimum: 0),
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

class _BenchmarkSentence {
  const _BenchmarkSentence({required this.text, required this.runeLength});

  final String text;
  final int runeLength;
}

class _BenchmarkSampleOutput {
  const _BenchmarkSampleOutput({
    required this.sentence,
    required this.top1Text,
    required this.top1TokenCount,
  });

  final String sentence;
  final String top1Text;
  final int top1TokenCount;

  Map<String, Object> toJson() {
    return <String, Object>{
      'sentence': sentence,
      'top1_text': top1Text,
      'top1_token_count': top1TokenCount,
    };
  }
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
    required this.analyzeImpl,
    required this.trialId,
    required this.sentenceCount,
    required this.initMs,
    required this.elapsedMs,
    required this.totalAnalyses,
    required this.totalChars,
    required this.totalTokens,
    required this.pureElapsedMs,
    required this.fullElapsedMs,
    required this.sampleOutputs,
  });

  final String platform;
  final int warmupRuns;
  final int measureRuns;
  final int topN;
  final int numThreads;
  final int buildOptions;
  final int createMatchOptions;
  final int analyzeMatchOptions;
  final String analyzeImpl;
  final int trialId;
  final int sentenceCount;
  final double initMs;
  final double elapsedMs;
  final int totalAnalyses;
  final int totalChars;
  final int totalTokens;
  final double pureElapsedMs;
  final double fullElapsedMs;
  final List<_BenchmarkSampleOutput> sampleOutputs;

  double get _jsonOverheadMs {
    final double value = fullElapsedMs - pureElapsedMs;
    return value > 0 ? value : 0;
  }

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
    final double pureAnalysesPerSec = _safeDivide(
      totalAnalyses,
      pureElapsedMs / 1000.0,
    );
    final double fullAnalysesPerSec = _safeDivide(
      totalAnalyses,
      fullElapsedMs / 1000.0,
    );
    final double jsonOverheadMs = _jsonOverheadMs;
    final double jsonOverheadRatio = _safeDivide(jsonOverheadMs, fullElapsedMs);
    final double jsonOverheadPerAnalysisMs = _safeDivide(
      jsonOverheadMs,
      totalAnalyses,
    );
    final double jsonOverheadPerTokenUs = _safeDivide(
      jsonOverheadMs * 1000.0,
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
      'analyze_impl': analyzeImpl,
      'trial_id': trialId,
      'sentence_count': sentenceCount,
      'sample_count': sampleOutputs.length,
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
      'pure_elapsed_ms': pureElapsedMs,
      'full_elapsed_ms': fullElapsedMs,
      'pure_analyses_per_sec': pureAnalysesPerSec,
      'full_analyses_per_sec': fullAnalysesPerSec,
      'json_overhead_ms': jsonOverheadMs,
      'json_overhead_ratio': jsonOverheadRatio,
      'json_overhead_percent': jsonOverheadRatio * 100.0,
      'json_overhead_per_analysis_ms': jsonOverheadPerAnalysisMs,
      'json_overhead_per_token_us': jsonOverheadPerTokenUs,
      'sample_outputs': sampleOutputs
          .map((final _BenchmarkSampleOutput sample) => sample.toJson())
          .toList(growable: false),
    };
  }
}

Future<_BenchmarkResult> _runBenchmark(_BenchmarkConfig config) async {
  final List<_BenchmarkSentence> sentences = await _loadSentences(
    config.corpusAssetPath,
  );

  final Stopwatch initStopwatch = Stopwatch()..start();
  final KiwiAnalyzer analyzer = await _createAnalyzer(config);
  initStopwatch.stop();

  try {
    final KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
      topN: config.topN,
      matchOptions: config.analyzeMatchOptions,
    );
    final String primaryImpl = config.analyzeImpl;
    final String secondaryImpl = primaryImpl == _analyzeImplJson
        ? _analyzeImplTokenCount
        : _analyzeImplJson;

    await _executeRuns(
      analyzer: analyzer,
      sentences: sentences,
      runs: config.warmupRuns,
      options: options,
      analyzeImpl: primaryImpl,
    );

    final _RunStats primaryMeasured = await _executeRuns(
      analyzer: analyzer,
      sentences: sentences,
      runs: config.measureRuns,
      options: options,
      analyzeImpl: primaryImpl,
    );
    await _executeRuns(
      analyzer: analyzer,
      sentences: sentences,
      runs: config.warmupRuns,
      options: options,
      analyzeImpl: secondaryImpl,
    );
    final _RunStats secondaryMeasured = await _executeRuns(
      analyzer: analyzer,
      sentences: sentences,
      runs: config.measureRuns,
      options: options,
      analyzeImpl: secondaryImpl,
    );

    final _RunStats measured = primaryMeasured;
    final _RunStats fullMeasured = primaryImpl == _analyzeImplJson
        ? primaryMeasured
        : secondaryMeasured;
    final _RunStats pureMeasured = primaryImpl == _analyzeImplTokenCount
        ? primaryMeasured
        : secondaryMeasured;
    final List<_BenchmarkSampleOutput> sampleOutputs =
        await _collectSampleOutputs(
          analyzer: analyzer,
          sentences: sentences,
          options: options,
          sampleCount: config.sampleCount,
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
      analyzeImpl: config.analyzeImpl,
      trialId: config.trialId,
      sentenceCount: sentences.length,
      initMs: initStopwatch.elapsedMicroseconds / 1000.0,
      elapsedMs: measured.elapsedMs,
      totalAnalyses: measured.totalAnalyses,
      totalChars: measured.totalChars,
      totalTokens: measured.totalTokens,
      pureElapsedMs: pureMeasured.elapsedMs,
      fullElapsedMs: fullMeasured.elapsedMs,
      sampleOutputs: sampleOutputs,
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

Future<List<_BenchmarkSentence>> _loadSentences(String corpusAssetPath) async {
  final String corpusText = await rootBundle.loadString(corpusAssetPath);
  final List<String> lines = corpusText
      .split('\n')
      .map((String sentence) => sentence.trim())
      .where((String sentence) => sentence.isNotEmpty)
      .toList(growable: false);

  if (lines.isEmpty) {
    throw StateError('Corpus is empty: $corpusAssetPath');
  }

  return lines
      .map(
        (final String sentence) => _BenchmarkSentence(
          text: sentence,
          runeLength: sentence.runes.length,
        ),
      )
      .toList(growable: false);
}

Future<_RunStats> _executeRuns({
  required KiwiAnalyzer analyzer,
  required List<_BenchmarkSentence> sentences,
  required int runs,
  required KiwiAnalyzeOptions options,
  required String analyzeImpl,
}) async {
  int totalAnalyses = 0;
  int totalChars = 0;
  int totalTokens = 0;
  final bool useTokenCount = analyzeImpl == _analyzeImplTokenCount;
  final int sentenceCount = sentences.length;
  final int charsPerRun = sentences.fold<int>(
    0,
    (int sum, _BenchmarkSentence sentence) => sum + sentence.runeLength,
  );
  final List<String> sentenceTexts = sentences
      .map((final _BenchmarkSentence sentence) => sentence.text)
      .toList(growable: false);

  final Stopwatch stopwatch = Stopwatch()..start();

  if (useTokenCount) {
    totalAnalyses = sentenceCount * runs;
    totalChars = charsPerRun * runs;
    totalTokens = await analyzer.analyzeTokenCountBatchRepeated(
      sentenceTexts,
      runs: runs,
      options: options,
    );
  } else {
    for (int runIndex = 0; runIndex < runs; runIndex += 1) {
      final List<KiwiAnalyzeResult> results = await analyzer.analyzeBatch(
        sentenceTexts,
        options: options,
      );
      if (results.length != sentenceCount) {
        throw StateError(
          'Unexpected analyze batch size: '
          'expected $sentenceCount, got ${results.length}.',
        );
      }
      totalAnalyses += sentenceCount;
      totalChars += charsPerRun;
      for (final KiwiAnalyzeResult result in results) {
        totalTokens += _tokenCountOfBestCandidate(result);
      }
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

Future<List<_BenchmarkSampleOutput>> _collectSampleOutputs({
  required KiwiAnalyzer analyzer,
  required List<_BenchmarkSentence> sentences,
  required KiwiAnalyzeOptions options,
  required int sampleCount,
}) async {
  if (sampleCount <= 0 || sentences.isEmpty) {
    return const <_BenchmarkSampleOutput>[];
  }
  final int limit = sampleCount < sentences.length
      ? sampleCount
      : sentences.length;
  final List<_BenchmarkSampleOutput> outputs = <_BenchmarkSampleOutput>[];
  for (int index = 0; index < limit; index += 1) {
    final _BenchmarkSentence sentence = sentences[index];
    final KiwiAnalyzeResult result = await analyzer.analyze(
      sentence.text,
      options: options,
    );
    final List<KiwiToken> tokens = result.candidates.isEmpty
        ? const <KiwiToken>[]
        : result.candidates.first.tokens;
    final String top1Text = tokens.isEmpty
        ? '(결과 없음)'
        : tokens
              .map((final KiwiToken token) => '${token.form}/${token.tag}')
              .join(' ');
    outputs.add(
      _BenchmarkSampleOutput(
        sentence: sentence.text,
        top1Text: top1Text,
        top1TokenCount: tokens.length,
      ),
    );
  }
  return outputs;
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

String _parseAnalyzeImpl(String rawValue) {
  final String normalized = rawValue.trim().toLowerCase();
  if (normalized == _analyzeImplTokenCount) {
    return _analyzeImplTokenCount;
  }
  return _analyzeImplJson;
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
