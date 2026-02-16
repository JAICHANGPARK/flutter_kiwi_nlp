import 'package:flutter/material.dart';

import 'kiwi_pos_tags.dart';

class KiwiPosTagDictionarySheet extends StatefulWidget {
  final String initialQuery;

  const KiwiPosTagDictionarySheet({super.key, this.initialQuery = ''});

  @override
  State<KiwiPosTagDictionarySheet> createState() =>
      _KiwiPosTagDictionarySheetState();
}

class _KiwiPosTagDictionarySheetState extends State<KiwiPosTagDictionarySheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<KiwiPosTagEntry> filtered = filterKiwiPosTagEntries(_query);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('품사 태그 사전', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              '세종 품사 태그 기반 + Kiwi 확장 태그를 포함합니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'VV/VA/VX/XSA 태그는 -R(규칙), -I(불규칙) 접미사가 붙을 수 있습니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: '태그/설명 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (String value) {
                setState(() => _query = value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              '검색 결과 ${filtered.length}개',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다.'))
                  : ListView(
                      children: _buildGroupedSections(context, filtered),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedSections(
    BuildContext context,
    List<KiwiPosTagEntry> entries,
  ) {
    final Map<String, List<KiwiPosTagEntry>> grouped =
        <String, List<KiwiPosTagEntry>>{
          for (final String category in kiwiPosTagCategoryOrder)
            category: <KiwiPosTagEntry>[],
        };
    for (final KiwiPosTagEntry entry in entries) {
      grouped.putIfAbsent(entry.majorCategory, () => <KiwiPosTagEntry>[]);
      grouped[entry.majorCategory]!.add(entry);
    }

    final List<Widget> widgets = <Widget>[];
    for (final String category in kiwiPosTagCategoryOrder) {
      final List<KiwiPosTagEntry> categoryEntries = grouped[category]!;
      if (categoryEntries.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(category, style: Theme.of(context).textTheme.titleMedium),
        ),
      );
      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: categoryEntries
                .map((KiwiPosTagEntry entry) => _buildTagTile(context, entry))
                .toList(growable: false),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildTagTile(BuildContext context, KiwiPosTagEntry entry) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      title: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(entry.tag, style: theme.textTheme.titleSmall),
          ),
          Expanded(child: Text(entry.description)),
        ],
      ),
      trailing: entry.customTag
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '확장',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            )
          : null,
    );
  }
}
