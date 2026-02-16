import 'package:flutter/material.dart';

import 'kiwi_analyzer_view_model.dart';

class KiwiSettingsSheet extends StatelessWidget {
  final KiwiAnalyzerViewModel viewModel;

  const KiwiSettingsSheet({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (BuildContext context, _) {
        final bool controlsLocked = viewModel.loading;
        final bool canAddUserWord = viewModel.canAddUserWord;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '분석 설정',
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
                Expanded(
                  child: ListView(
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey<String>(
                          'settings-preset-${viewModel.selectedPreset.id}',
                        ),
                        initialValue: viewModel.selectedPreset.id,
                        decoration: const InputDecoration(
                          labelText: '옵션 프리셋',
                          border: OutlineInputBorder(),
                        ),
                        items: viewModel.optionPresets
                            .map(
                              (preset) => DropdownMenuItem<String>(
                                value: preset.id,
                                child: Text(preset.title),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: controlsLocked
                            ? null
                            : (String? value) {
                                if (value == null) return;
                                viewModel.setSelectedPreset(value);
                              },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        viewModel.selectedPreset.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: viewModel.modelPathController,
                        enabled: !controlsLocked,
                        decoration: const InputDecoration(
                          labelText: '모델 경로',
                          hintText: '비우면 내장 base 모델 사용',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: controlsLocked
                            ? null
                            : () => viewModel.initAnalyzer(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('분석기 초기화'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        key: ValueKey<int>(viewModel.topN),
                        initialValue: viewModel.topN,
                        decoration: const InputDecoration(
                          labelText: '결과 개수',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('결과 1개')),
                          DropdownMenuItem(value: 3, child: Text('결과 3개')),
                          DropdownMenuItem(value: 5, child: Text('결과 5개')),
                        ],
                        onChanged: controlsLocked
                            ? null
                            : (int? value) {
                                if (value == null) return;
                                viewModel.setTopN(value);
                              },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '일반 옵션',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      _optionSwitch(
                        label: '이형태 통합',
                        value: viewModel.integrateAllomorph,
                        disabled: controlsLocked,
                        onChanged: viewModel.setIntegrateAllomorph,
                      ),
                      _optionSwitch(
                        label: '종성 우선 정규화',
                        value: viewModel.normalizeCoda,
                        disabled: controlsLocked,
                        onChanged: viewModel.setNormalizeCoda,
                      ),
                      _optionSwitch(
                        label: '덧붙은 받침 분리',
                        value: viewModel.splitSaisiot,
                        disabled: controlsLocked,
                        onChanged: viewModel.setSplitSaisiot,
                      ),
                      const Divider(height: 24),
                      Text(
                        '특수 토큰 매칭',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      _optionSwitch(
                        label: 'W_URL',
                        value: viewModel.matchUrl,
                        disabled: controlsLocked,
                        onChanged: viewModel.setMatchUrl,
                      ),
                      _optionSwitch(
                        label: 'W_EMAIL',
                        value: viewModel.matchEmail,
                        disabled: controlsLocked,
                        onChanged: viewModel.setMatchEmail,
                      ),
                      _optionSwitch(
                        label: 'W_HASHTAG',
                        value: viewModel.matchHashtag,
                        disabled: controlsLocked,
                        onChanged: viewModel.setMatchHashtag,
                      ),
                      _optionSwitch(
                        label: 'W_MENTION',
                        value: viewModel.matchMention,
                        disabled: controlsLocked,
                        onChanged: viewModel.setMatchMention,
                      ),
                      _optionSwitch(
                        label: 'W_SERIAL',
                        value: viewModel.matchSerial,
                        disabled: controlsLocked,
                        onChanged: viewModel.setMatchSerial,
                      ),
                      const Divider(height: 24),
                      Text(
                        '파생 결합 옵션',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      _optionSwitch(
                        label: '명사 접두사 결합',
                        value: viewModel.joinNounPrefix,
                        disabled: controlsLocked,
                        onChanged: viewModel.setJoinNounPrefix,
                      ),
                      _optionSwitch(
                        label: '명사 접미사 결합',
                        value: viewModel.joinNounSuffix,
                        disabled: controlsLocked,
                        onChanged: viewModel.setJoinNounSuffix,
                      ),
                      _optionSwitch(
                        label: '동사 파생접사 결합',
                        value: viewModel.joinVerbSuffix,
                        disabled: controlsLocked,
                        onChanged: viewModel.setJoinVerbSuffix,
                      ),
                      _optionSwitch(
                        label: '형용사 파생접사 결합',
                        value: viewModel.joinAdjSuffix,
                        disabled: controlsLocked,
                        onChanged: viewModel.setJoinAdjSuffix,
                      ),
                      _optionSwitch(
                        label: '부사 파생접사 결합',
                        value: viewModel.joinAdvSuffix,
                        disabled: controlsLocked,
                        onChanged: viewModel.setJoinAdvSuffix,
                      ),
                      const Divider(height: 24),
                      Text(
                        '사용자 사전',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: viewModel.userWordController,
                              enabled: canAddUserWord,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '사용자 단어',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: viewModel.newUserWordTag,
                            items: KiwiAnalyzerViewModel.userWordTagOptions
                                .map(
                                  (String tag) => DropdownMenuItem<String>(
                                    value: tag,
                                    child: Text(tag),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: canAddUserWord
                                ? (String? value) {
                                    if (value == null) return;
                                    viewModel.setNewUserWordTag(value);
                                  }
                                : null,
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: canAddUserWord
                                ? () => viewModel.addUserWord()
                                : null,
                            child: const Text('추가'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optionSwitch({
    required String label,
    required bool value,
    required bool disabled,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      dense: true,
      title: Text(label),
      value: value,
      contentPadding: EdgeInsets.zero,
      onChanged: disabled ? null : onChanged,
    );
  }
}
