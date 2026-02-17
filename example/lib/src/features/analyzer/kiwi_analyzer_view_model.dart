import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

import '../../default_model_path_stub.dart'
    if (dart.library.io) '../../default_model_path_io.dart'
    if (dart.library.js_interop) '../../default_model_path_web.dart';
import 'kiwi_demo_data.dart';
import 'kiwi_result_row.dart';

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
      _analyzer = null;
      await current?.close();

      final String modelPath = modelPathController.text.trim();
      final bool useAssetModel = modelPath.startsWith('assets/');
      final Future<KiwiAnalyzer> createFuture = KiwiAnalyzer.create(
        modelPath: modelPath.isEmpty || useAssetModel ? null : modelPath,
        assetModelPath: useAssetModel ? modelPath : null,
      );
      final KiwiAnalyzer created = await createFuture.timeout(
        kIsWeb ? const Duration(minutes: 8) : const Duration(minutes: 2),
        onTimeout: () => throw KiwiException(
          kIsWeb
              ? '초기화가 8분 동안 완료되지 않았습니다. 웹 디버그 모드에서는 첫 로딩이 오래 걸릴 수 있습니다. '
                    '모델 경로/네트워크를 확인한 뒤 다시 시도하세요.'
              : '초기화가 2분 동안 완료되지 않았습니다. 네트워크/모델 경로를 확인 후 다시 시도하세요.',
        ),
      );
      _analyzer = created;
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

      final List<KiwiResultRow> nextRows = <KiwiResultRow>[];
      for (int index = 0; index < lines.length; index++) {
        final KiwiAnalyzeResult result = await analyzer.analyze(
          lines[index],
          options: options,
        );

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
      userWordController.clear();
      notifyListeners();
    } catch (error, stackTrace) {
      _reportError('addUserWord', error, stackTrace);
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
    _analyzer = null;
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
