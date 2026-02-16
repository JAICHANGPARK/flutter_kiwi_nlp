import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_kiwi_ffi/flutter_kiwi_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'src/default_model_path_stub.dart'
    if (dart.library.io) 'src/default_model_path_io.dart'
    if (dart.library.js_interop) 'src/default_model_path_web.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[KiwiDemo][flutter] ${details.exception}');
    final StackTrace? stack = details.stack;
    if (stack != null) {
      debugPrintStack(label: '[KiwiDemo][flutter]', stackTrace: stack);
    }
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    debugPrint('[KiwiDemo][platform] $error');
    debugPrintStack(label: '[KiwiDemo][platform]', stackTrace: stackTrace);
    return false;
  };
  runZonedGuarded(() => runApp(const KiwiDemoApp()), (
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[KiwiDemo][zone] $error');
    debugPrintStack(label: '[KiwiDemo][zone]', stackTrace: stackTrace);
  });
}

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

class KiwiAnalyzerPage extends StatefulWidget {
  const KiwiAnalyzerPage({super.key});

  @override
  State<KiwiAnalyzerPage> createState() => _KiwiAnalyzerPageState();
}

class _KiwiAnalyzerPageState extends State<KiwiAnalyzerPage> {
  final TextEditingController _modelPathController = TextEditingController(
    text: defaultModelPath(),
  );
  final TextEditingController _inputController = TextEditingController(
    text: '왜 그리 부아가 나서 트집잡느냐?\n무사 경 부에 낭 밍겡이헴시니?',
  );
  final TextEditingController _userWordController = TextEditingController();

  KiwiAnalyzer? _analyzer;
  String? _errorMessage;
  bool _loading = false;

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
  String _newUserWordTag = 'NNP';

  List<_ResultRow> _rows = const <_ResultRow>[];

  @override
  void initState() {
    super.initState();
    _initAnalyzer();
  }

  @override
  void dispose() {
    _modelPathController.dispose();
    _inputController.dispose();
    _userWordController.dispose();
    _analyzer?.close();
    super.dispose();
  }

  void _reportError(String context, Object error, [StackTrace? stackTrace]) {
    final String message = error.toString();
    final String logPrefix = '[KiwiDemo][$context]';
    debugPrint('$logPrefix $message');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: logPrefix,
        context: ErrorDescription('while handling Kiwi demo action'),
      ),
    );
    if (stackTrace != null) {
      debugPrintStack(label: logPrefix, stackTrace: stackTrace);
    }
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _initAnalyzer() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final KiwiAnalyzer? current = _analyzer;
      _analyzer = null;
      await current?.close();

      final String modelPath = _modelPathController.text.trim();
      final bool useAssetModel = modelPath.startsWith('assets/');
      final Future<KiwiAnalyzer> createFuture = KiwiAnalyzer.create(
        modelPath: modelPath.isEmpty || useAssetModel ? null : modelPath,
        assetModelPath: useAssetModel ? modelPath : null,
      );
      final KiwiAnalyzer analyzer = await createFuture.timeout(
        kIsWeb ? const Duration(minutes: 8) : const Duration(minutes: 2),
        onTimeout: () => throw KiwiException(
          kIsWeb
              ? '초기화가 8분 동안 완료되지 않았습니다. 웹 디버그 모드에서는 첫 로딩이 오래 걸릴 수 있습니다. '
                    '모델 경로/네트워크를 확인한 뒤 다시 시도하세요.'
              : '초기화가 2분 동안 완료되지 않았습니다. 네트워크/모델 경로를 확인 후 다시 시도하세요.',
        ),
      );
      if (!mounted) return;
      setState(() {
        _analyzer = analyzer;
      });
    } catch (error, stackTrace) {
      _reportError('init', error, stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _analyze() async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null || _loading) return;

    final List<String> lines = _inputController.text
        .split('\n')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      setState(() {
        _rows = const <_ResultRow>[];
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final int matchOptions = _buildMatchOptions();
      final KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
        topN: _topN,
        matchOptions: matchOptions,
      );

      final List<_ResultRow> nextRows = <_ResultRow>[];
      for (int index = 0; index < lines.length; index++) {
        final KiwiAnalyzeResult result = await analyzer.analyze(
          lines[index],
          options: options,
        );
        final KiwiCandidate? candidate = result.candidates.isEmpty
            ? null
            : result.candidates.first;
        final String joined = candidate == null || candidate.tokens.isEmpty
            ? '(결과 없음)'
            : candidate.tokens
                  .map((KiwiToken token) => '${token.form}/${token.tag}')
                  .join(' + ');
        nextRows.add(
          _ResultRow(number: index + 1, input: lines[index], result: joined),
        );
      }

      if (!mounted) return;
      setState(() {
        _rows = nextRows;
      });
    } catch (error, stackTrace) {
      _reportError('analyze', error, stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _addUserWord() async {
    final KiwiAnalyzer? analyzer = _analyzer;
    final String word = _userWordController.text.trim();
    if (analyzer == null || word.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await analyzer.addUserWord(word, tag: _newUserWordTag);
      if (!mounted) return;
      _userWordController.clear();
      setState(() {});
    } catch (error, stackTrace) {
      _reportError('addUserWord', error, stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
      // integrate_allomorph is a build option in Kiwi, but we keep this UI switch
      // to mirror the desktop tool and apply it in future native integration.
    }
    return match;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('키위 형태소 분석기'),
        actions: [
          if (_analyzer != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'native ${_analyzer!.nativeVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_errorMessage != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectionArea(
                      child: SelectableText(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool horizontal = constraints.maxWidth > 980;
                  final Widget inputPane = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _inputController,
                        minLines: 8,
                        maxLines: null,
                        expands: false,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '분석할 문장을 줄 단위로 입력하세요.',
                        ),
                      ),
                    ),
                  );
                  final Widget controlPane = _buildControlPane();

                  if (horizontal) {
                    return Row(
                      children: [
                        Expanded(child: inputPane),
                        const SizedBox(width: 12),
                        SizedBox(width: 360, child: controlPane),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Expanded(flex: 3, child: inputPane),
                      const SizedBox(height: 12),
                      Expanded(flex: 2, child: controlPane),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: Card(child: _buildResultTable())),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPane() {
    final bool disabled = _loading || _analyzer == null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _modelPathController,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: '모델 경로',
                        hintText: '비우면 내장 base 모델 사용',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.tonal(
                    onPressed: _loading ? null : _initAnalyzer,
                    child: const Text('초기화'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: disabled ? null : _analyze,
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('분석'),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _topN,
                decoration: const InputDecoration(
                  labelText: '결과 개수',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('결과 1개')),
                  DropdownMenuItem(value: 3, child: Text('결과 3개')),
                  DropdownMenuItem(value: 5, child: Text('결과 5개')),
                ],
                onChanged: disabled
                    ? null
                    : (int? value) {
                        if (value == null) return;
                        setState(() {
                          _topN = value;
                        });
                      },
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  CheckboxListTile(
                    title: const Text('이형태 통합'),
                    value: _integrateAllomorph,
                    contentPadding: EdgeInsets.zero,
                    onChanged: disabled
                        ? null
                        : (bool? value) {
                            setState(() {
                              _integrateAllomorph = value ?? false;
                            });
                          },
                  ),
                  CheckboxListTile(
                    title: const Text('종성 우선 정규화'),
                    value: _normalizeCoda,
                    contentPadding: EdgeInsets.zero,
                    onChanged: disabled
                        ? null
                        : (bool? value) {
                            setState(() {
                              _normalizeCoda = value ?? false;
                            });
                          },
                  ),
                  CheckboxListTile(
                    title: const Text('덧붙은 받침 분리'),
                    value: _splitSaisiot,
                    contentPadding: EdgeInsets.zero,
                    onChanged: disabled
                        ? null
                        : (bool? value) {
                            setState(() {
                              _splitSaisiot = value ?? false;
                            });
                          },
                  ),
                  const Divider(height: 8),
                  _boolOption('W_URL', _matchUrl, disabled, (bool value) {
                    setState(() => _matchUrl = value);
                  }),
                  _boolOption('W_EMAIL', _matchEmail, disabled, (bool value) {
                    setState(() => _matchEmail = value);
                  }),
                  _boolOption('W_HASHTAG', _matchHashtag, disabled, (
                    bool value,
                  ) {
                    setState(() => _matchHashtag = value);
                  }),
                  _boolOption('W_MENTION', _matchMention, disabled, (
                    bool value,
                  ) {
                    setState(() => _matchMention = value);
                  }),
                  _boolOption('W_SERIAL', _matchSerial, disabled, (bool value) {
                    setState(() => _matchSerial = value);
                  }),
                  const Divider(height: 8),
                  _boolOption('명사 접두사 결합', _joinNounPrefix, disabled, (
                    bool value,
                  ) {
                    setState(() => _joinNounPrefix = value);
                  }),
                  _boolOption('명사 접미사 결합', _joinNounSuffix, disabled, (
                    bool value,
                  ) {
                    setState(() => _joinNounSuffix = value);
                  }),
                  _boolOption('동사 파생접사 결합', _joinVerbSuffix, disabled, (
                    bool value,
                  ) {
                    setState(() => _joinVerbSuffix = value);
                  }),
                  _boolOption('형용사 파생접사 결합', _joinAdjSuffix, disabled, (
                    bool value,
                  ) {
                    setState(() => _joinAdjSuffix = value);
                  }),
                  _boolOption('부사 파생접사 결합', _joinAdvSuffix, disabled, (
                    bool value,
                  ) {
                    setState(() => _joinAdvSuffix = value);
                  }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _userWordController,
                          enabled: !disabled,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '사용자 단어',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      DropdownButton<String>(
                        value: _newUserWordTag,
                        items: const [
                          DropdownMenuItem(value: 'NNP', child: Text('NNP')),
                          DropdownMenuItem(value: 'NNG', child: Text('NNG')),
                          DropdownMenuItem(value: 'MAG', child: Text('MAG')),
                        ],
                        onChanged: disabled
                            ? null
                            : (String? value) {
                                if (value == null) return;
                                setState(() => _newUserWordTag = value);
                              },
                      ),
                      const SizedBox(width: 6),
                      FilledButton.tonal(
                        onPressed: disabled ? null : _addUserWord,
                        child: const Text('추가'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boolOption(
    String label,
    bool value,
    bool disabled,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      dense: true,
      title: Text(label),
      value: value,
      contentPadding: EdgeInsets.zero,
      onChanged: disabled ? null : onChanged,
    );
  }

  Widget _buildResultTable() {
    if (_rows.isEmpty) {
      return const Center(child: Text('분석 결과가 여기에 표시됩니다.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: DataTable(
        headingRowHeight: 34,
        dataRowMinHeight: 46,
        dataRowMaxHeight: 110,
        columns: const [
          DataColumn(label: Text('번호')),
          DataColumn(label: Text('입력')),
          DataColumn(label: Text('결과')),
        ],
        rows: _rows
            .map(
              (_ResultRow row) => DataRow(
                cells: [
                  DataCell(Text('${row.number}')),
                  DataCell(Text(row.input)),
                  DataCell(
                    SizedBox(
                      width: 800,
                      child: Text(row.result, softWrap: true),
                    ),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ResultRow {
  final int number;
  final String input;
  final String result;

  const _ResultRow({
    required this.number,
    required this.input,
    required this.result,
  });
}
