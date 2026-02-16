import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kiwi_analyzer_view_model.dart';
import 'kiwi_demo_data.dart';
import 'kiwi_pos_tag_dictionary_sheet.dart';
import 'kiwi_pos_tags.dart';
import 'kiwi_result_row.dart';
import 'kiwi_settings_sheet.dart';

class KiwiAnalyzerPage extends StatefulWidget {
  const KiwiAnalyzerPage({super.key});

  @override
  State<KiwiAnalyzerPage> createState() => _KiwiAnalyzerPageState();
}

class _KiwiAnalyzerPageState extends State<KiwiAnalyzerPage>
    with SingleTickerProviderStateMixin {
  static const double _compactBreakpoint = 900;

  late final KiwiAnalyzerViewModel _viewModel;
  late final TabController _compactTabController;

  @override
  void initState() {
    super.initState();
    _viewModel = KiwiAnalyzerViewModel();
    _compactTabController = TabController(length: 2, vsync: this);
    unawaited(_viewModel.initAnalyzer());
  }

  @override
  void dispose() {
    _compactTabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return KiwiSettingsSheet(viewModel: _viewModel);
      },
    );
  }

  Future<void> _openPosTagDictionarySheet({String initialQuery = ''}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return KiwiPosTagDictionarySheet(initialQuery: initialQuery);
      },
    );
  }

  Future<void> _openTagDetailSheet(KiwiTokenCell token) async {
    final KiwiResolvedTag resolved = resolveKiwiPosTag(token.tag);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '토큰 상세',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${token.form} / ${token.tag}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                _detailRow('기본 태그', resolved.baseTag),
                _detailRow('대분류', resolved.majorCategory),
                _detailRow('설명', resolved.description),
                if (resolved.inflectionDescription != null)
                  _detailRow('활용 정보', resolved.inflectionDescription!),
                if (!resolved.isKnown)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '사전에 등록되지 않은 태그입니다. 품사 사전에서 전체 목록을 확인해 주세요.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          unawaited(
                            _openPosTagDictionarySheet(
                              initialQuery: resolved.baseTag,
                            ),
                          );
                        },
                        icon: const Icon(Icons.menu_book),
                        label: const Text('사전에서 보기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyResultsToClipboard() async {
    final String text = _viewModel.buildResultsAsPlainText();
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('복사할 분석 결과가 없습니다.')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('분석 결과를 클립보드에 복사했습니다.')));
  }

  bool _isCompactWidth(double width) => width < _compactBreakpoint;

  void _showInputTab() {
    if (_compactTabController.index != 0) {
      _compactTabController.animateTo(0);
    }
  }

  void _showResultsTab() {
    if (_compactTabController.index != 1) {
      _compactTabController.animateTo(1);
    }
  }

  Future<void> _runAnalyze({required bool openResultsOnComplete}) async {
    await _viewModel.analyze();
    if (!mounted || !openResultsOnComplete) return;
    _showResultsTab();
  }

  Future<void> _runAnalyzeSelectedScenario({
    required bool openResultsOnComplete,
  }) async {
    await _viewModel.analyzeSelectedScenario();
    if (!mounted || !openResultsOnComplete) return;
    _showResultsTab();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (BuildContext context, _) {
        final KiwiAnalyzerViewModel vm = _viewModel;
        final bool compactForAppBar = _isCompactWidth(
          MediaQuery.sizeOf(context).width,
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('키위 형태소 분석기'),
            actions: [
              IconButton(
                tooltip: '초기화',
                onPressed: vm.loading ? null : vm.initAnalyzer,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: '설정',
                onPressed: _openSettingsSheet,
                icon: const Icon(Icons.settings_outlined),
              ),
              IconButton(
                tooltip: '품사 사전',
                onPressed: _openPosTagDictionarySheet,
                icon: const Icon(Icons.menu_book_outlined),
              ),
              if (compactForAppBar)
                IconButton(
                  tooltip: '결과 보기',
                  onPressed: vm.rows.isEmpty ? null : _showResultsTab,
                  icon: const Icon(Icons.insights_outlined),
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  if (_isCompactWidth(constraints.maxWidth)) {
                    return _buildCompactLayout(context, vm);
                  }
                  return _buildWideLayout(context, vm, constraints.maxWidth);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactLayout(BuildContext context, KiwiAnalyzerViewModel vm) {
    return Column(
      children: [
        if (vm.errorMessage != null)
          _buildErrorBanner(context, vm.errorMessage!),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: TabBar(
            controller: _compactTabController,
            tabs: const [
              Tab(icon: Icon(Icons.edit_note), text: '입력'),
              Tab(icon: Icon(Icons.analytics_outlined), text: '결과'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _compactTabController,
            children: [
              ListView(
                children: [_buildInputCard(context, vm, compactLayout: true)],
              ),
              _buildResultPane(context, vm, compactLayout: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    KiwiAnalyzerViewModel vm,
    double width,
  ) {
    final double inputWidth = width >= 1300
        ? 520
        : (width * 0.42).clamp(420, 560);

    return Column(
      children: [
        if (vm.errorMessage != null)
          _buildErrorBanner(context, vm.errorMessage!),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: inputWidth,
                child: SingleChildScrollView(
                  child: _buildInputCard(context, vm, compactLayout: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultPane(context, vm, compactLayout: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(
    BuildContext context,
    KiwiAnalyzerViewModel vm, {
    required bool compactLayout,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: vm.inputController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '분석할 문장을 줄 단위로 입력하세요.',
              ),
            ),
            const SizedBox(height: 12),
            Text('예제 시나리오', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildScenarioSelector(vm),
            const SizedBox(height: 8),
            Text(
              '선택: ${vm.selectedScenario.title} · ${vm.selectedScenario.summary}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey<String>('main-preset-${vm.selectedPreset.id}'),
              initialValue: vm.selectedPreset.id,
              decoration: const InputDecoration(
                labelText: '옵션 프리셋',
                border: OutlineInputBorder(),
              ),
              items: vm.optionPresets
                  .map(
                    (KiwiOptionPreset preset) => DropdownMenuItem<String>(
                      value: preset.id,
                      child: Text(preset.title),
                    ),
                  )
                  .toList(growable: false),
              onChanged: vm.loading
                  ? null
                  : (String? value) {
                      if (value == null) return;
                      vm.setSelectedPreset(value);
                    },
            ),
            const SizedBox(height: 6),
            Text(
              vm.selectedPreset.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: vm.canAnalyze
                      ? () => _runAnalyze(openResultsOnComplete: compactLayout)
                      : null,
                  icon: vm.loading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(vm.canAnalyze ? '분석 실행' : '초기화 필요'),
                ),
                FilledButton.tonalIcon(
                  onPressed: vm.loading
                      ? null
                      : () => _runAnalyzeSelectedScenario(
                          openResultsOnComplete: compactLayout,
                        ),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('선택 예제 실행'),
                ),
                OutlinedButton.icon(
                  onPressed: _openSettingsSheet,
                  icon: const Icon(Icons.tune),
                  label: const Text('상세 설정'),
                ),
                OutlinedButton.icon(
                  onPressed: _openPosTagDictionarySheet,
                  icon: const Icon(Icons.menu_book),
                  label: const Text('품사 사전'),
                ),
                if (compactLayout)
                  OutlinedButton.icon(
                    onPressed: vm.rows.isEmpty ? null : _showResultsTab,
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('결과 크게 보기'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              vm.analyzer == null
                  ? '엔진 상태: 초기화 중'
                  : '엔진: native ${vm.analyzer!.nativeVersion} · topN ${vm.topN}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPane(
    BuildContext context,
    KiwiAnalyzerViewModel vm, {
    required bool compactLayout,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('분석 결과', style: Theme.of(context).textTheme.titleMedium),
            OutlinedButton.icon(
              onPressed: vm.rows.isEmpty ? null : _copyResultsToClipboard,
              icon: const Icon(Icons.copy_all),
              label: const Text('복사'),
            ),
            OutlinedButton.icon(
              onPressed: vm.rows.isEmpty ? null : vm.clearResults,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('지우기'),
            ),
            if (compactLayout)
              OutlinedButton.icon(
                onPressed: _showInputTab,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('입력으로'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildResultList(context, vm, compactLayout: compactLayout),
        ),
      ],
    );
  }

  Widget _buildScenarioSelector(KiwiAnalyzerViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: vm.scenarios
            .map((KiwiDemoScenario scenario) {
              final bool selected = vm.selectedScenario.id == scenario.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  label: Text(scenario.title),
                  onSelected: (bool value) {
                    if (!value) return;
                    vm.setSelectedScenario(scenario.id, applyPreset: true);
                  },
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return ConstrainedBox(
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
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(title)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildResultList(
    BuildContext context,
    KiwiAnalyzerViewModel vm, {
    required bool compactLayout,
  }) {
    if (vm.rows.isEmpty) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('분석 결과가 여기에 표시됩니다.'),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: vm.loading
                      ? null
                      : () => _runAnalyzeSelectedScenario(
                          openResultsOnComplete: compactLayout,
                        ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('선택 예제 바로 실행'),
                ),
                if (compactLayout) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _showInputTab,
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('입력으로 이동'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: vm.rows.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final KiwiResultRow row = vm.rows[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row.number}. ${row.input}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (row.candidates.isEmpty)
                  Text(
                    '(결과 없음)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...row.candidates.map(
                    (KiwiCandidateRow candidate) =>
                        _buildCandidateCard(context, candidate),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCandidateCard(BuildContext context, KiwiCandidateRow candidate) {
    final ThemeData theme = Theme.of(context);
    final Color background = candidate.rank == 1
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('후보 ${candidate.rank}', style: theme.textTheme.labelLarge),
              const Spacer(),
              Text(
                'p=${candidate.probability.toStringAsFixed(6)}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (candidate.tokens.isEmpty)
            Text(
              '(토큰 없음)',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: candidate.tokens
                  .map((KiwiTokenCell token) => _buildTokenChip(context, token))
                  .toList(growable: false),
            ),
          const SizedBox(height: 8),
          SelectionArea(
            child: SelectableText(
              candidate.joined,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenChip(BuildContext context, KiwiTokenCell token) {
    final KiwiResolvedTag resolved = resolveKiwiPosTag(token.tag);
    final String suffixNote = resolved.inflectionDescription == null
        ? ''
        : ' / ${resolved.inflectionDescription}';
    final String tooltip =
        '${resolved.baseTag} (${resolved.majorCategory})\n'
        '${resolved.description}$suffixNote';

    return Tooltip(
      message: tooltip,
      child: ActionChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        onPressed: () => _openTagDetailSheet(token),
        label: Text(token.joined),
      ),
    );
  }
}
