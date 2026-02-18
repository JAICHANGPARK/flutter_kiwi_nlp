import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

import '../../default_model_path_stub.dart'
    if (dart.library.io) '../../default_model_path_io.dart'
    if (dart.library.js_interop) '../../default_model_path_web.dart';
import 'kiwi_benchmark_model_materializer_stub.dart'
    if (dart.library.io) 'kiwi_benchmark_model_materializer_io.dart';
import 'kiwi_demo_data.dart';
import 'kiwi_result_row.dart';

const String _benchmarkCorpusAssetPath = 'assets/benchmark_corpus_ko.txt';
const String _benchmarkAnalyzeImplJson = 'json';
const String _benchmarkAnalyzeImplTokenCount = 'token_count';
const int _benchmarkDefaultSampleCount = 10;
const String _defaultAssetModelPath = 'assets/kiwi-models/cong/base';
const String _defaultPackageAssetModelPath =
    'packages/flutter_kiwi_nlp/assets/kiwi-models/cong/base';
const List<String> _benchmarkModelFileNames = <String>[
  'combiningRule.txt',
  'cong.mdl',
  'default.dict',
  'dialect.dict',
  'extract.mdl',
  'multi.dict',
  'sj.morph',
  'typo.dict',
];

class KiwiBenchmarkResult {
  const KiwiBenchmarkResult({
    required this.generatedAtUtc,
    required this.nativeVersion,
    required this.sentenceCount,
    required this.warmupRuns,
    required this.measureRuns,
    required this.topN,
    required this.analyzeImpl,
    required this.initMs,
    required this.elapsedMs,
    required this.pureElapsedMs,
    required this.fullElapsedMs,
    required this.totalAnalyses,
    required this.totalChars,
    required this.totalTokens,
    required this.sampleOutputs,
  });

  final DateTime generatedAtUtc;
  final String nativeVersion;
  final int sentenceCount;
  final int warmupRuns;
  final int measureRuns;
  final int topN;
  final String analyzeImpl;
  final double initMs;
  final double elapsedMs;
  final double pureElapsedMs;
  final double fullElapsedMs;
  final int totalAnalyses;
  final int totalChars;
  final int totalTokens;
  final List<KiwiBenchmarkSampleOutput> sampleOutputs;

  double get analysesPerSec =>
      _safeDivide(totalAnalyses, elapsedMs / Duration.millisecondsPerSecond);
  double get charsPerSec =>
      _safeDivide(totalChars, elapsedMs / Duration.millisecondsPerSecond);
  double get tokensPerSec =>
      _safeDivide(totalTokens, elapsedMs / Duration.millisecondsPerSecond);
  double get avgLatencyMs => _safeDivide(elapsedMs, totalAnalyses);
  double get avgTokenLatencyUs => _safeDivide(elapsedMs * 1000.0, totalTokens);
  bool get isTokenCountBenchmark =>
      analyzeImpl == _benchmarkAnalyzeImplTokenCount;

  double get jsonOverheadMs {
    final double value = fullElapsedMs - pureElapsedMs;
    return value > 0 ? value : 0;
  }

  double get jsonOverheadRatio => _safeDivide(jsonOverheadMs, fullElapsedMs);

  double get jsonOverheadPerAnalysisMs =>
      _safeDivide(jsonOverheadMs, totalAnalyses);

  double get jsonOverheadPerTokenUs =>
      _safeDivide(jsonOverheadMs * 1000.0, totalTokens);

  double get pureAnalysesPerSec =>
      _safeDivide(totalAnalyses, pureElapsedMs / 1000.0);
  double get fullAnalysesPerSec =>
      _safeDivide(totalAnalyses, fullElapsedMs / 1000.0);
}

class KiwiBenchmarkSampleOutput {
  const KiwiBenchmarkSampleOutput({
    required this.sentence,
    required this.appTop1Text,
    required this.top1TokenCount,
  });

  final String sentence;
  final String appTop1Text;
  final int top1TokenCount;
}

class _BenchmarkSentenceInBackground {
  const _BenchmarkSentenceInBackground({
    required this.text,
    required this.runeLength,
  });

  final String text;
  final int runeLength;

  factory _BenchmarkSentenceInBackground.fromText(String text) {
    return _BenchmarkSentenceInBackground(
      text: text,
      runeLength: text.runes.length,
    );
  }
}

class KiwiAnalyzerViewModel extends ChangeNotifier {
  static const List<String> userWordTagOptions = <String>[
    'NNP',
    'NNG',
    'MAG',
    'SL',
  ];

  final TextEditingController modelPathController;
  final TextEditingController inputController;
  final TextEditingController userWordController;

  KiwiAnalyzer? _analyzer;
  _KiwiAnalyzeWorker? _analysisWorker;
  bool _loading = false;
  String? _errorMessage;
  List<KiwiResultRow> _rows = const <KiwiResultRow>[];

  int _topN = 1;
  bool _integrateAllomorph = true;
  bool _normalizeCoda = false;
  bool _splitSaisiot = true;
  bool _joinNounPrefix = false;
  bool _joinNounSuffix = false;
  bool _joinVerbSuffix = false;
  bool _joinAdjSuffix = false;
  bool _joinAdvSuffix = false;
  bool _matchUrl = false;
  bool _matchEmail = false;
  bool _matchHashtag = false;
  bool _matchMention = false;
  bool _matchSerial = false;
  String _newUserWordTag = userWordTagOptions.first;

  String _selectedPresetId = kiwiOptionPresets.first.id;
  String _selectedScenarioId = kiwiDemoScenarios.first.id;

  KiwiAnalyzerViewModel()
    : modelPathController = TextEditingController(text: defaultModelPath()),
      inputController = TextEditingController(
        text: kiwiDemoScenarios.first.text,
      ),
      userWordController = TextEditingController() {
    _applyPreset(_presetById(_selectedPresetId), notify: false);
  }

  KiwiAnalyzer? get analyzer => _analyzer;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  List<KiwiResultRow> get rows => _rows;
  bool get canAnalyze => !_loading && _analyzer != null;
  bool get canAddUserWord => !_loading && _analyzer != null;

  int get topN => _topN;
  bool get integrateAllomorph => _integrateAllomorph;
  bool get normalizeCoda => _normalizeCoda;
  bool get splitSaisiot => _splitSaisiot;
  bool get joinNounPrefix => _joinNounPrefix;
  bool get joinNounSuffix => _joinNounSuffix;
  bool get joinVerbSuffix => _joinVerbSuffix;
  bool get joinAdjSuffix => _joinAdjSuffix;
  bool get joinAdvSuffix => _joinAdvSuffix;
  bool get matchUrl => _matchUrl;
  bool get matchEmail => _matchEmail;
  bool get matchHashtag => _matchHashtag;
  bool get matchMention => _matchMention;
  bool get matchSerial => _matchSerial;
  String get newUserWordTag => _newUserWordTag;

  List<KiwiOptionPreset> get optionPresets => kiwiOptionPresets;
  List<KiwiDemoScenario> get scenarios => kiwiDemoScenarios;

  KiwiOptionPreset get selectedPreset => _presetById(_selectedPresetId);
  KiwiDemoScenario get selectedScenario => _scenarioById(_selectedScenarioId);

  void setSelectedPreset(String presetId) {
    final KiwiOptionPreset preset = _presetById(presetId);
    _selectedPresetId = preset.id;
    _applyPreset(preset);
  }

  void setSelectedScenario(String scenarioId, {bool applyPreset = true}) {
    final KiwiDemoScenario scenario = _scenarioById(scenarioId);
    _selectedScenarioId = scenario.id;
    inputController.text = scenario.text;
    if (scenario.suggestedUserWord != null &&
        scenario.suggestedUserWord!.trim().isNotEmpty) {
      userWordController.text = scenario.suggestedUserWord!.trim();
      _newUserWordTag = scenario.suggestedUserWordTag;
    }
    if (applyPreset) {
      final KiwiOptionPreset preset = _presetById(scenario.presetId);
      _selectedPresetId = preset.id;
      _applyPreset(preset, notify: false);
    }
    notifyListeners();
  }

  Future<void> analyzeSelectedScenario() async {
    setSelectedScenario(_selectedScenarioId, applyPreset: true);
    await analyze();
  }

  void setTopN(int value) => _update(() => _topN = value);
  void setIntegrateAllomorph(bool value) =>
      _update(() => _integrateAllomorph = value);
  void setNormalizeCoda(bool value) => _update(() => _normalizeCoda = value);
  void setSplitSaisiot(bool value) => _update(() => _splitSaisiot = value);
  void setJoinNounPrefix(bool value) => _update(() => _joinNounPrefix = value);
  void setJoinNounSuffix(bool value) => _update(() => _joinNounSuffix = value);
  void setJoinVerbSuffix(bool value) => _update(() => _joinVerbSuffix = value);
  void setJoinAdjSuffix(bool value) => _update(() => _joinAdjSuffix = value);
  void setJoinAdvSuffix(bool value) => _update(() => _joinAdvSuffix = value);
  void setMatchUrl(bool value) => _update(() => _matchUrl = value);
  void setMatchEmail(bool value) => _update(() => _matchEmail = value);
  void setMatchHashtag(bool value) => _update(() => _matchHashtag = value);
  void setMatchMention(bool value) => _update(() => _matchMention = value);
  void setMatchSerial(bool value) => _update(() => _matchSerial = value);
  void setNewUserWordTag(String value) =>
      _update(() => _newUserWordTag = value);

  Future<void> initAnalyzer() async {
    if (_loading) return;
    _setLoading(true, clearError: true);
    try {
      final KiwiAnalyzer? current = _analyzer;
      final _KiwiAnalyzeWorker? currentWorker = _analysisWorker;
      _analyzer = null;
      _analysisWorker = null;
      await current?.close();
      await currentWorker?.dispose();

      final KiwiAnalyzer created = await _createAnalyzerFromModelPath();
      _analyzer = created;
      _analysisWorker = await _maybeCreateAnalysisWorker(
        createMatchOptions: _buildMatchOptions(),
      );
      notifyListeners();
    } catch (error, stackTrace) {
      _reportError('init', error, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> analyze() async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null || _loading) return;

    final List<String> lines = inputController.text
        .split('\n')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      _rows = const <KiwiResultRow>[];
      notifyListeners();
      return;
    }

    _setLoading(true, clearError: true);
    try {
      final KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
        topN: _topN,
        matchOptions: _buildMatchOptions(),
      );
      final _KiwiAnalyzeWorker? worker = _analysisWorker;
      final List<KiwiResultRow> nextRows = worker == null
          ? await _analyzeWithMainIsolate(analyzer, lines, options)
          : await _analyzeWithWorker(worker, lines, options);

      _rows = nextRows;
      notifyListeners();
    } catch (error, stackTrace) {
      _reportError('analyze', error, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addUserWord() async {
    final KiwiAnalyzer? analyzer = _analyzer;
    final String word = userWordController.text.trim();
    if (analyzer == null || word.isEmpty || _loading) return;

    _setLoading(true, clearError: true);
    try {
      await analyzer.addUserWord(word, tag: _newUserWordTag);
      final _KiwiAnalyzeWorker? worker = _analysisWorker;
      if (worker != null) {
        await worker.addUserWord(word, tag: _newUserWordTag);
      }
      userWordController.clear();
      notifyListeners();
    } catch (error, stackTrace) {
      _reportError('addUserWord', error, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<List<KiwiResultRow>> _analyzeWithMainIsolate(
    KiwiAnalyzer analyzer,
    List<String> lines,
    KiwiAnalyzeOptions options,
  ) async {
    final List<KiwiAnalyzeResult> results = await analyzer.analyzeBatch(
      lines,
      options: options,
    );
    return _buildRowsFromAnalyzeResults(lines, results);
  }

  Future<List<KiwiResultRow>> _analyzeWithWorker(
    _KiwiAnalyzeWorker worker,
    List<String> lines,
    KiwiAnalyzeOptions options,
  ) async {
    final List<List<Map<String, Object?>>> payload = await worker.analyzeBatch(
      lines,
      options: options,
    );
    return _buildRowsFromWorkerPayload(lines, payload);
  }

  List<KiwiResultRow> _buildRowsFromAnalyzeResults(
    List<String> lines,
    List<KiwiAnalyzeResult> results,
  ) {
    if (results.length != lines.length) {
      throw const KiwiException('예상과 다른 분석 결과 개수가 반환되었습니다.');
    }

    final List<KiwiResultRow> nextRows = <KiwiResultRow>[];
    for (int index = 0; index < lines.length; index += 1) {
      final KiwiAnalyzeResult result = results[index];
      final List<KiwiCandidateRow> candidates = result.candidates
          .asMap()
          .entries
          .map((MapEntry<int, KiwiCandidate> entry) {
            final KiwiCandidate candidate = entry.value;
            final List<KiwiTokenCell> tokens = candidate.tokens
                .map(
                  (KiwiToken token) =>
                      KiwiTokenCell(form: token.form, tag: token.tag),
                )
                .toList(growable: false);
            return KiwiCandidateRow(
              rank: entry.key + 1,
              probability: candidate.probability,
              tokens: tokens,
            );
          })
          .toList(growable: false);
      nextRows.add(
        KiwiResultRow(
          number: index + 1,
          input: lines[index],
          candidates: candidates,
        ),
      );
    }
    return nextRows;
  }

  List<KiwiResultRow> _buildRowsFromWorkerPayload(
    List<String> lines,
    List<List<Map<String, Object?>>> payload,
  ) {
    if (payload.length != lines.length) {
      throw const KiwiException('예상과 다른 분석 결과 개수가 반환되었습니다.');
    }

    final List<KiwiResultRow> nextRows = <KiwiResultRow>[];
    for (int index = 0; index < lines.length; index += 1) {
      final List<Map<String, Object?>> candidatesPayload = payload[index];
      final List<KiwiCandidateRow> candidates = candidatesPayload
          .asMap()
          .entries
          .map((MapEntry<int, Map<String, Object?>> entry) {
            final Map<String, Object?> candidatePayload = entry.value;
            final Object? rawTokens = candidatePayload['tokens'];
            final List<KiwiTokenCell> tokens = rawTokens is List<Object?>
                ? rawTokens
                      .whereType<Map<Object?, Object?>>()
                      .map((Map<Object?, Object?> tokenPayload) {
                        return KiwiTokenCell(
                          form: '${tokenPayload['form'] ?? ''}',
                          tag: '${tokenPayload['tag'] ?? 'UNK'}',
                        );
                      })
                      .toList(growable: false)
                : const <KiwiTokenCell>[];
            final Object? rawProbability = candidatePayload['probability'];
            final double probability = rawProbability is num
                ? rawProbability.toDouble()
                : 0.0;
            return KiwiCandidateRow(
              rank: entry.key + 1,
              probability: probability,
              tokens: tokens,
            );
          })
          .toList(growable: false);
      nextRows.add(
        KiwiResultRow(
          number: index + 1,
          input: lines[index],
          candidates: candidates,
        ),
      );
    }
    return nextRows;
  }

  Future<_KiwiAnalyzeWorker?> _maybeCreateAnalysisWorker({
    required int createMatchOptions,
  }) async {
    if (kIsWeb) {
      return null;
    }
    try {
      final String modelPath = await _resolveBenchmarkModelPath();
      return await _KiwiAnalyzeWorker.start(
        modelPath: modelPath,
        createMatchOptions: createMatchOptions,
      );
    } catch (error, stackTrace) {
      const String logPrefix = '[KiwiDemo][analyze-worker]';
      debugPrint('$logPrefix failed to initialize worker: $error');
      debugPrintStack(label: logPrefix, stackTrace: stackTrace);
      return null;
    }
  }

  Future<KiwiBenchmarkResult> runBenchmark({
    int warmupRuns = 3,
    int measureRuns = 15,
    int? topN,
    bool useTokenCount = true,
    int sampleCount = _benchmarkDefaultSampleCount,
  }) async {
    if (_loading) {
      throw const KiwiException('다른 작업이 진행 중입니다. 현재 작업이 끝난 뒤 다시 시도하세요.');
    }

    final int resolvedWarmupRuns = warmupRuns < 0 ? 0 : warmupRuns;
    final int resolvedMeasureRuns = measureRuns < 1 ? 1 : measureRuns;
    final int resolvedTopN = (topN ?? _topN) < 1 ? 1 : (topN ?? _topN);
    final int resolvedSampleCount = sampleCount < 0 ? 0 : sampleCount;
    final int matchOptions = _buildMatchOptions();
    final String analyzeImpl = useTokenCount
        ? _benchmarkAnalyzeImplTokenCount
        : _benchmarkAnalyzeImplJson;

    _setLoading(true, clearError: true);
    try {
      final List<String> sentences = await _loadBenchmarkSentences();
      final String benchmarkModelPath = await _resolveBenchmarkModelPath();
      final Map<String, Object> payload = <String, Object>{
        'sentences': sentences,
        'modelPath': benchmarkModelPath,
        'warmupRuns': resolvedWarmupRuns,
        'measureRuns': resolvedMeasureRuns,
        'topN': resolvedTopN,
        'matchOptions': matchOptions,
        'analyzeImpl': analyzeImpl,
        'sampleCount': resolvedSampleCount,
      };
      final Map<String, Object?> rawResult = kIsWeb
          ? await _runBenchmarkInBackground(payload)
          : await compute<Map<String, Object>, Map<String, Object?>>(
              _runBenchmarkInBackground,
              payload,
              debugLabel: 'kiwi-benchmark',
            );

      return KiwiBenchmarkResult(
        generatedAtUtc: DateTime.now().toUtc(),
        nativeVersion: '${rawResult['nativeVersion'] ?? 'unknown'}',
        sentenceCount: _toInt(rawResult['sentenceCount']),
        warmupRuns: _toInt(rawResult['warmupRuns']),
        measureRuns: _toInt(rawResult['measureRuns']),
        topN: _toInt(rawResult['topN']),
        analyzeImpl: _normalizeBenchmarkAnalyzeImpl(rawResult['analyzeImpl']),
        initMs: _toDouble(rawResult['initMs']),
        elapsedMs: _toDouble(rawResult['elapsedMs']),
        pureElapsedMs: _toDouble(rawResult['pureElapsedMs']),
        fullElapsedMs: _toDouble(rawResult['fullElapsedMs']),
        totalAnalyses: _toInt(rawResult['totalAnalyses']),
        totalChars: _toInt(rawResult['totalChars']),
        totalTokens: _toInt(rawResult['totalTokens']),
        sampleOutputs: _parseBenchmarkSamples(rawResult['sampleOutputs']),
      );
    } catch (error, stackTrace) {
      _reportError('benchmark', error, stackTrace);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearResults() {
    _rows = const <KiwiResultRow>[];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String buildResultsAsPlainText() {
    if (_rows.isEmpty) return '';
    final StringBuffer buffer = StringBuffer();
    for (final KiwiResultRow row in _rows) {
      buffer.writeln('${row.number}. ${row.input}');
      if (row.candidates.isEmpty) {
        buffer.writeln('  - (결과 없음)');
      } else {
        for (final KiwiCandidateRow candidate in row.candidates) {
          buffer.writeln(
            '  - 후보 ${candidate.rank} '
            '(p=${candidate.probability.toStringAsFixed(6)}): ${candidate.joined}',
          );
        }
      }
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  @override
  void dispose() {
    modelPathController.dispose();
    inputController.dispose();
    userWordController.dispose();
    final KiwiAnalyzer? analyzer = _analyzer;
    final _KiwiAnalyzeWorker? worker = _analysisWorker;
    _analyzer = null;
    _analysisWorker = null;
    if (worker != null) {
      unawaited(worker.dispose());
    }
    if (analyzer != null) {
      unawaited(analyzer.close());
    }
    super.dispose();
  }

  KiwiOptionPreset _presetById(String presetId) {
    return kiwiOptionPresets.firstWhere(
      (KiwiOptionPreset preset) => preset.id == presetId,
      orElse: () => kiwiOptionPresets.first,
    );
  }

  KiwiDemoScenario _scenarioById(String scenarioId) {
    return kiwiDemoScenarios.firstWhere(
      (KiwiDemoScenario scenario) => scenario.id == scenarioId,
      orElse: () => kiwiDemoScenarios.first,
    );
  }

  void _applyPreset(KiwiOptionPreset preset, {bool notify = true}) {
    _topN = preset.topN;
    _integrateAllomorph = preset.integrateAllomorph;
    _normalizeCoda = preset.normalizeCoda;
    _splitSaisiot = preset.splitSaisiot;
    _joinNounPrefix = preset.joinNounPrefix;
    _joinNounSuffix = preset.joinNounSuffix;
    _joinVerbSuffix = preset.joinVerbSuffix;
    _joinAdjSuffix = preset.joinAdjSuffix;
    _joinAdvSuffix = preset.joinAdvSuffix;
    _matchUrl = preset.matchUrl;
    _matchEmail = preset.matchEmail;
    _matchHashtag = preset.matchHashtag;
    _matchMention = preset.matchMention;
    _matchSerial = preset.matchSerial;
    if (notify) {
      notifyListeners();
    }
  }

  int _buildMatchOptions() {
    int match = 0;
    if (_matchUrl) match |= KiwiMatchOption.url;
    if (_matchEmail) match |= KiwiMatchOption.email;
    if (_matchHashtag) match |= KiwiMatchOption.hashtag;
    if (_matchMention) match |= KiwiMatchOption.mention;
    if (_matchSerial) match |= KiwiMatchOption.serial;

    if (_normalizeCoda) match |= KiwiMatchOption.normalizeCoda;
    if (_joinNounPrefix) match |= KiwiMatchOption.joinNounPrefix;
    if (_joinNounSuffix) match |= KiwiMatchOption.joinNounSuffix;
    if (_joinVerbSuffix) match |= KiwiMatchOption.joinVerbSuffix;
    if (_joinAdjSuffix) match |= KiwiMatchOption.joinAdjSuffix;
    if (_joinAdvSuffix) match |= KiwiMatchOption.joinAdvSuffix;
    if (_splitSaisiot) match |= KiwiMatchOption.splitSaisiot;
    if (_integrateAllomorph) {
      // integrate_allomorph is a build option in Kiwi.
      // This flag is kept for UI parity with desktop tooling.
    }
    return match;
  }

  Future<KiwiAnalyzer> _createAnalyzerFromModelPath() async {
    final String modelPath = modelPathController.text.trim();
    final bool useAssetModel = modelPath.startsWith('assets/');
    final Future<KiwiAnalyzer> createFuture = KiwiAnalyzer.create(
      modelPath: modelPath.isEmpty || useAssetModel ? null : modelPath,
      assetModelPath: useAssetModel ? modelPath : null,
    );
    return createFuture.timeout(
      kIsWeb ? const Duration(minutes: 8) : const Duration(minutes: 2),
      onTimeout: () => throw KiwiException(
        kIsWeb
            ? '초기화가 8분 동안 완료되지 않았습니다. 웹 디버그 모드에서는 첫 로딩이 오래 걸릴 수 있습니다. '
                  '모델 경로/네트워크를 확인한 뒤 다시 시도하세요.'
            : '초기화가 2분 동안 완료되지 않았습니다. 네트워크/모델 경로를 확인 후 다시 시도하세요.',
      ),
    );
  }

  Future<List<String>> _loadBenchmarkSentences() async {
    try {
      final String raw = await rootBundle.loadString(_benchmarkCorpusAssetPath);
      final List<String> sentences = _splitNonEmptyLines(raw);
      if (sentences.isNotEmpty) {
        return sentences;
      }
    } on FlutterError {
      // Falls back to current input lines when benchmark corpus asset is absent.
    }

    final List<String> fallback = _splitNonEmptyLines(inputController.text);
    if (fallback.isNotEmpty) {
      return fallback;
    }
    throw const KiwiException(
      '벤치마크 코퍼스가 비어 있습니다. '
      'assets/benchmark_corpus_ko.txt 또는 입력 텍스트를 확인하세요.',
    );
  }

  Future<String> _resolveBenchmarkModelPath() async {
    final String configuredModelPath = modelPathController.text.trim();
    final bool assetPath = configuredModelPath.startsWith('assets/');
    final bool packageAssetPath = configuredModelPath.startsWith('packages/');
    if (configuredModelPath.isNotEmpty && !assetPath) {
      return configuredModelPath;
    }

    final List<String> candidates = _buildBenchmarkAssetPathCandidates(
      configuredModelPath: configuredModelPath,
      assetPath: assetPath,
      packageAssetPath: packageAssetPath,
    );
    Object? lastError;
    for (final String candidate in candidates) {
      try {
        final String? materializedPath =
            await materializeBenchmarkModelDirectory(
              candidate,
              _benchmarkModelFileNames,
            );
        if (materializedPath != null && materializedPath.isNotEmpty) {
          return materializedPath;
        }
      } on FlutterError catch (error) {
        lastError = error;
      }
    }

    if (kIsWeb) {
      return candidates.first;
    }

    throw KiwiException(
      '모델 에셋 복사에 실패했습니다. '
      '시도 경로: ${candidates.join(', ')}. '
      '설정에서 모델 경로를 직접 지정하거나 에셋 번들을 확인하세요. '
      '${lastError == null ? '' : '($lastError)'}',
    );
  }

  List<String> _buildBenchmarkAssetPathCandidates({
    required String configuredModelPath,
    required bool assetPath,
    required bool packageAssetPath,
  }) {
    if (assetPath && configuredModelPath.isNotEmpty) {
      return <String>[
        configuredModelPath,
        'packages/flutter_kiwi_nlp/$configuredModelPath',
      ];
    }

    if (packageAssetPath && configuredModelPath.isNotEmpty) {
      return <String>[configuredModelPath];
    }

    return <String>[_defaultPackageAssetModelPath, _defaultAssetModelPath];
  }

  List<String> _splitNonEmptyLines(String text) {
    return text
        .split('\n')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
  }

  void _reportError(String context, Object error, [StackTrace? stackTrace]) {
    final String message = error.toString();
    final String logPrefix = '[KiwiDemo][$context]';
    debugPrint('$logPrefix $message');
    if (stackTrace != null) {
      debugPrintStack(label: logPrefix, stackTrace: stackTrace);
    }
    _errorMessage = message;
    notifyListeners();
  }

  void _setLoading(bool value, {bool clearError = false}) {
    _loading = value;
    if (clearError) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _update(VoidCallback change) {
    change();
    notifyListeners();
  }
}

class _KiwiAnalyzeWorker {
  _KiwiAnalyzeWorker._({
    required Isolate isolate,
    required SendPort commandPort,
    required ReceivePort responsePort,
    required ReceivePort exitPort,
  }) : _isolate = isolate,
       _commandPort = commandPort,
       _responsePort = responsePort,
       _exitPort = exitPort;

  final Isolate _isolate;
  final SendPort _commandPort;
  final ReceivePort _responsePort;
  final ReceivePort _exitPort;
  final Map<int, Completer<Map<String, Object?>>> _pending =
      <int, Completer<Map<String, Object?>>>{};
  late final StreamSubscription<dynamic> _responseSubscription;
  late final StreamSubscription<dynamic> _exitSubscription;
  int _nextRequestId = 1;
  bool _closed = false;

  static Future<_KiwiAnalyzeWorker> start({
    required String modelPath,
    required int createMatchOptions,
  }) async {
    final ReceivePort responsePort = ReceivePort();
    final ReceivePort exitPort = ReceivePort();
    final Isolate isolate = await Isolate.spawn<Map<String, Object?>>(
      _kiwiAnalyzeWorkerEntryPoint,
      <String, Object?>{
        'replyPort': responsePort.sendPort,
        'modelPath': modelPath,
        'createMatchOptions': createMatchOptions,
      },
      onExit: exitPort.sendPort,
      errorsAreFatal: true,
    );

    final dynamic initMessage = await responsePort.first.timeout(
      const Duration(minutes: 2),
      onTimeout: () => throw const KiwiException('분석 워커 초기화 시간 초과'),
    );
    if (initMessage is! Map<Object?, Object?>) {
      responsePort.close();
      exitPort.close();
      isolate.kill(priority: Isolate.immediate);
      throw const KiwiException('분석 워커 초기화 응답이 올바르지 않습니다.');
    }
    final Map<String, Object?> parsed = _toStringObjectMap(initMessage);
    final String type = '${parsed['type'] ?? ''}';
    if (type != 'ready') {
      responsePort.close();
      exitPort.close();
      isolate.kill(priority: Isolate.immediate);
      final String error = '${parsed['error'] ?? '분석 워커 초기화 실패'}';
      throw KiwiException(error);
    }
    final Object? rawCommandPort = parsed['commandPort'];
    if (rawCommandPort is! SendPort) {
      responsePort.close();
      exitPort.close();
      isolate.kill(priority: Isolate.immediate);
      throw const KiwiException('분석 워커 command port를 받지 못했습니다.');
    }

    final _KiwiAnalyzeWorker worker = _KiwiAnalyzeWorker._(
      isolate: isolate,
      commandPort: rawCommandPort,
      responsePort: responsePort,
      exitPort: exitPort,
    );
    worker._startListening();
    return worker;
  }

  void _startListening() {
    _responseSubscription = _responsePort.listen(_handleResponse);
    _exitSubscription = _exitPort.listen(_handleExit);
  }

  void _handleResponse(dynamic message) {
    if (message is! Map<Object?, Object?>) {
      return;
    }
    final Map<String, Object?> parsed = _toStringObjectMap(message);
    final Object? rawId = parsed['id'];
    if (rawId is! int) {
      return;
    }
    final Completer<Map<String, Object?>>? completer = _pending.remove(rawId);
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete(parsed);
  }

  void _handleExit(dynamic _) {
    if (_closed) {
      return;
    }
    _closed = true;
    _failPending(const KiwiException('분석 워커가 종료되었습니다.'));
  }

  Future<Map<String, Object?>> _request(
    String command,
    Map<String, Object?> payload,
  ) async {
    if (_closed) {
      throw const KiwiException('분석 워커가 이미 종료되었습니다.');
    }
    final int id = _nextRequestId;
    _nextRequestId += 1;
    final Completer<Map<String, Object?>> completer =
        Completer<Map<String, Object?>>();
    _pending[id] = completer;
    _commandPort.send(<String, Object?>{
      'id': id,
      'command': command,
      ...payload,
    });
    late final Map<String, Object?> response;
    try {
      response = await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw const KiwiException('분석 워커 응답 시간 초과'),
      );
    } finally {
      _pending.remove(id);
    }
    final bool ok = response['ok'] == true;
    if (!ok) {
      throw KiwiException('${response['error'] ?? '분석 워커 처리 실패'}');
    }
    return response;
  }

  Future<List<List<Map<String, Object?>>>> analyzeBatch(
    List<String> texts, {
    required KiwiAnalyzeOptions options,
  }) async {
    final Map<String, Object?> response = await _request(
      'analyze_batch',
      <String, Object?>{
        'texts': texts,
        'topN': options.topN,
        'matchOptions': options.matchOptions,
      },
    );
    final Object? rawResults = response['results'];
    if (rawResults is! List<Object?>) {
      throw const KiwiException('분석 워커 응답 형식이 올바르지 않습니다.');
    }
    return rawResults
        .map((Object? sentencePayload) {
          if (sentencePayload is! List<Object?>) {
            throw const KiwiException('분석 워커 응답 형식이 올바르지 않습니다.');
          }
          return sentencePayload
              .map((Object? candidatePayload) {
                if (candidatePayload is! Map<Object?, Object?>) {
                  throw const KiwiException('분석 워커 응답 형식이 올바르지 않습니다.');
                }
                return _toStringObjectMap(candidatePayload);
              })
              .toList(growable: false);
        })
        .toList(growable: false);
  }

  Future<void> addUserWord(String word, {required String tag}) async {
    await _request('add_user_word', <String, Object?>{
      'word': word,
      'tag': tag,
    });
  }

  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    try {
      await _request('dispose', const <String, Object?>{});
    } catch (_) {
      // Falls back to isolate kill below.
    } finally {
      _closed = true;
      _isolate.kill(priority: Isolate.immediate);
      _failPending(const KiwiException('분석 워커가 종료되었습니다.'));
      await _responseSubscription.cancel();
      await _exitSubscription.cancel();
      _responsePort.close();
      _exitPort.close();
    }
  }

  void _failPending(KiwiException error) {
    for (final Completer<Map<String, Object?>> completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pending.clear();
  }
}

@pragma('vm:entry-point')
Future<void> _kiwiAnalyzeWorkerEntryPoint(Map<String, Object?> payload) async {
  final Object? rawReplyPort = payload['replyPort'];
  if (rawReplyPort is! SendPort) {
    return;
  }
  final SendPort replyPort = rawReplyPort;
  final String modelPath = '${payload['modelPath'] ?? ''}';
  final int createMatchOptions = _toInt(payload['createMatchOptions']);
  final ReceivePort commandPort = ReceivePort();

  late final KiwiAnalyzer analyzer;
  try {
    analyzer = await KiwiAnalyzer.create(
      modelPath: modelPath,
      matchOptions: createMatchOptions,
    );
    replyPort.send(<String, Object?>{
      'type': 'ready',
      'commandPort': commandPort.sendPort,
    });
  } catch (error) {
    replyPort.send(<String, Object?>{'type': 'init_error', 'error': '$error'});
    commandPort.close();
    return;
  }

  await for (final dynamic rawMessage in commandPort) {
    if (rawMessage is! Map<Object?, Object?>) {
      continue;
    }
    final Map<String, Object?> message = _toStringObjectMap(rawMessage);
    final Object? rawId = message['id'];
    final int? id = rawId is int ? rawId : null;
    final String command = '${message['command'] ?? ''}';
    if (id == null) {
      continue;
    }
    try {
      switch (command) {
        case 'analyze_batch':
          final List<String> texts = (message['texts'] as List<Object?>)
              .map((Object? item) => item.toString())
              .toList(growable: false);
          final KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
            topN: _toInt(message['topN']),
            matchOptions: _toInt(message['matchOptions']),
          );
          final List<KiwiAnalyzeResult> results = await analyzer.analyzeBatch(
            texts,
            options: options,
          );
          final List<List<Map<String, Object?>>> encoded = results
              .map((KiwiAnalyzeResult result) {
                return result.candidates
                    .map((KiwiCandidate candidate) {
                      return <String, Object?>{
                        'probability': candidate.probability,
                        'tokens': candidate.tokens
                            .map(
                              (KiwiToken token) => <String, Object?>{
                                'form': token.form,
                                'tag': token.tag,
                              },
                            )
                            .toList(growable: false),
                      };
                    })
                    .toList(growable: false);
              })
              .toList(growable: false);
          replyPort.send(<String, Object?>{
            'id': id,
            'ok': true,
            'results': encoded,
          });
          break;
        case 'add_user_word':
          await analyzer.addUserWord(
            '${message['word'] ?? ''}',
            tag: '${message['tag'] ?? 'NNP'}',
          );
          replyPort.send(<String, Object?>{'id': id, 'ok': true});
          break;
        case 'dispose':
          await analyzer.close();
          replyPort.send(<String, Object?>{'id': id, 'ok': true});
          commandPort.close();
          return;
        default:
          throw KiwiException('알 수 없는 워커 명령입니다: $command');
      }
    } catch (error) {
      replyPort.send(<String, Object?>{
        'id': id,
        'ok': false,
        'error': '$error',
      });
    }
  }
}

Map<String, Object?> _toStringObjectMap(Map<Object?, Object?> value) {
  return <String, Object?>{
    for (final MapEntry<Object?, Object?> entry in value.entries)
      '${entry.key}': entry.value,
  };
}

Future<Map<String, Object?>> _runBenchmarkInBackground(
  Map<String, Object> payload,
) async {
  final List<_BenchmarkSentenceInBackground> sentences =
      (payload['sentences'] as List<Object?>)
          .map((Object? item) => item.toString())
          .map(_BenchmarkSentenceInBackground.fromText)
          .toList(growable: false);
  final String modelPath = payload['modelPath'] as String;
  final int warmupRuns = _toInt(payload['warmupRuns']);
  final int measureRuns = _toInt(payload['measureRuns']);
  final int topN = _toInt(payload['topN']);
  final int matchOptions = _toInt(payload['matchOptions']);
  final int sampleCount = _toInt(payload['sampleCount']);
  final String analyzeImpl = _normalizeBenchmarkAnalyzeImpl(
    payload['analyzeImpl'],
  );
  final String secondaryImpl = analyzeImpl == _benchmarkAnalyzeImplJson
      ? _benchmarkAnalyzeImplTokenCount
      : _benchmarkAnalyzeImplJson;

  final Stopwatch initStopwatch = Stopwatch()..start();
  final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
    modelPath: modelPath,
    matchOptions: matchOptions,
  );
  initStopwatch.stop();

  try {
    final KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
      topN: topN,
      matchOptions: matchOptions,
    );

    await _runBenchmarkPassInBackground(
      analyzer: analyzer,
      sentences: sentences,
      runs: warmupRuns,
      options: options,
      analyzeImpl: analyzeImpl,
    );
    final Map<String, num> primaryMeasured =
        await _runBenchmarkPassInBackground(
          analyzer: analyzer,
          sentences: sentences,
          runs: measureRuns,
          options: options,
          analyzeImpl: analyzeImpl,
        );
    await _runBenchmarkPassInBackground(
      analyzer: analyzer,
      sentences: sentences,
      runs: warmupRuns,
      options: options,
      analyzeImpl: secondaryImpl,
    );
    final Map<String, num> secondaryMeasured =
        await _runBenchmarkPassInBackground(
          analyzer: analyzer,
          sentences: sentences,
          runs: measureRuns,
          options: options,
          analyzeImpl: secondaryImpl,
        );
    final Map<String, num> fullMeasured =
        analyzeImpl == _benchmarkAnalyzeImplJson
        ? primaryMeasured
        : secondaryMeasured;
    final Map<String, num> pureMeasured =
        analyzeImpl == _benchmarkAnalyzeImplTokenCount
        ? primaryMeasured
        : secondaryMeasured;
    final List<Map<String, Object?>> sampleOutputs =
        await _collectBenchmarkSamplesInBackground(
          analyzer: analyzer,
          sentences: sentences,
          options: options,
          sampleCount: sampleCount,
        );

    return <String, Object?>{
      'nativeVersion': analyzer.nativeVersion,
      'sentenceCount': sentences.length,
      'warmupRuns': warmupRuns,
      'measureRuns': measureRuns,
      'topN': topN,
      'analyzeImpl': analyzeImpl,
      'initMs': initStopwatch.elapsedMicroseconds / 1000.0,
      'elapsedMs': primaryMeasured['elapsedMs'] ?? 0.0,
      'pureElapsedMs': pureMeasured['elapsedMs'] ?? 0.0,
      'fullElapsedMs': fullMeasured['elapsedMs'] ?? 0.0,
      'totalAnalyses': primaryMeasured['totalAnalyses'] ?? 0,
      'totalChars': primaryMeasured['totalChars'] ?? 0,
      'totalTokens': primaryMeasured['totalTokens'] ?? 0,
      'sampleOutputs': sampleOutputs,
    };
  } finally {
    await analyzer.close();
  }
}

Future<Map<String, num>> _runBenchmarkPassInBackground({
  required KiwiAnalyzer analyzer,
  required List<_BenchmarkSentenceInBackground> sentences,
  required int runs,
  required KiwiAnalyzeOptions options,
  required String analyzeImpl,
}) async {
  int totalAnalyses = 0;
  int totalChars = 0;
  int totalTokens = 0;
  final bool useTokenCount = analyzeImpl == _benchmarkAnalyzeImplTokenCount;
  final int sentenceCount = sentences.length;
  final int charsPerRun = sentences.fold<int>(
    0,
    (int sum, _BenchmarkSentenceInBackground sentence) =>
        sum + sentence.runeLength,
  );
  final List<String> sentenceTexts = sentences
      .map((final _BenchmarkSentenceInBackground sentence) => sentence.text)
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
    for (int pass = 0; pass < runs; pass += 1) {
      final List<KiwiAnalyzeResult> results = await analyzer.analyzeBatch(
        sentenceTexts,
        options: options,
      );
      if (results.length != sentenceCount) {
        throw const KiwiException('예상과 다른 분석 결과 개수가 반환되었습니다.');
      }
      totalAnalyses += sentenceCount;
      totalChars += charsPerRun;
      for (final KiwiAnalyzeResult result in results) {
        totalTokens += _tokenCountFromAnalyze(result);
      }
    }
  }
  stopwatch.stop();

  return <String, num>{
    'elapsedMs': stopwatch.elapsedMicroseconds / 1000.0,
    'totalAnalyses': totalAnalyses,
    'totalChars': totalChars,
    'totalTokens': totalTokens,
  };
}

Future<List<Map<String, Object?>>> _collectBenchmarkSamplesInBackground({
  required KiwiAnalyzer analyzer,
  required List<_BenchmarkSentenceInBackground> sentences,
  required KiwiAnalyzeOptions options,
  required int sampleCount,
}) async {
  if (sampleCount <= 0 || sentences.isEmpty) {
    return const <Map<String, Object?>>[];
  }
  final int limit = sampleCount < sentences.length
      ? sampleCount
      : sentences.length;
  final List<Map<String, Object?>> outputs = <Map<String, Object?>>[];
  for (int index = 0; index < limit; index += 1) {
    final _BenchmarkSentenceInBackground sentence = sentences[index];
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
    outputs.add(<String, Object?>{
      'sentence': sentence.text,
      'top1_text': top1Text,
      'top1_token_count': tokens.length,
    });
  }
  return outputs;
}

double _safeDivide(num numerator, num denominator) {
  if (denominator <= 0) {
    return 0;
  }
  return numerator / denominator;
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

int _tokenCountFromAnalyze(KiwiAnalyzeResult result) {
  if (result.candidates.isEmpty) {
    return 0;
  }
  return result.candidates.first.tokens.length;
}

String _normalizeBenchmarkAnalyzeImpl(Object? value) {
  final String raw = value?.toString().trim().toLowerCase() ?? '';
  if (raw == _benchmarkAnalyzeImplTokenCount) {
    return _benchmarkAnalyzeImplTokenCount;
  }
  return _benchmarkAnalyzeImplJson;
}

List<KiwiBenchmarkSampleOutput> _parseBenchmarkSamples(Object? value) {
  if (value is! List<Object?>) {
    return const <KiwiBenchmarkSampleOutput>[];
  }
  final List<KiwiBenchmarkSampleOutput> samples = <KiwiBenchmarkSampleOutput>[];
  for (final Object? item in value) {
    if (item is! Map<Object?, Object?>) {
      continue;
    }
    samples.add(
      KiwiBenchmarkSampleOutput(
        sentence: '${item['sentence'] ?? ''}',
        appTop1Text: '${item['top1_text'] ?? item['top1Text'] ?? '(결과 없음)'}',
        top1TokenCount: _toInt(
          item['top1_token_count'] ?? item['top1TokenCount'],
        ),
      ),
    );
  }
  return samples;
}

double _toDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return 0;
}
