class KiwiPosTagEntry {
  final String majorCategory;
  final String tag;
  final String description;
  final bool customTag;

  const KiwiPosTagEntry({
    required this.majorCategory,
    required this.tag,
    required this.description,
    this.customTag = false,
  });
}

class KiwiResolvedTag {
  final String rawTag;
  final String normalizedTag;
  final String baseTag;
  final String? inflectionSuffix;
  final String? inflectionDescription;
  final KiwiPosTagEntry? entry;

  const KiwiResolvedTag({
    required this.rawTag,
    required this.normalizedTag,
    required this.baseTag,
    required this.inflectionSuffix,
    required this.inflectionDescription,
    required this.entry,
  });

  bool get isKnown => entry != null;
  String get majorCategory => entry?.majorCategory ?? '미분류';
  String get description => entry?.description ?? '사전에 없는 태그입니다.';
}

const List<String> kiwiPosTagCategoryOrder = <String>[
  '체언(N)',
  '용언(V)',
  '관형사',
  '부사(MA)',
  '감탄사',
  '조사(J)',
  '어미(E)',
  '접두사',
  '접미사(XS)',
  '어근',
  '부호, 외국어, 특수문자(S)',
  '분석 불능',
  '웹(W)',
  '기타',
];

const KiwiPosTagEntry _userTagRangeEntry = KiwiPosTagEntry(
  majorCategory: '기타',
  tag: 'USER0~4',
  description: '사용자 정의 태그',
  customTag: true,
);

const List<KiwiPosTagEntry> kiwiPosTagEntries = <KiwiPosTagEntry>[
  KiwiPosTagEntry(majorCategory: '체언(N)', tag: 'NNG', description: '일반 명사'),
  KiwiPosTagEntry(majorCategory: '체언(N)', tag: 'NNP', description: '고유 명사'),
  KiwiPosTagEntry(majorCategory: '체언(N)', tag: 'NNB', description: '의존 명사'),
  KiwiPosTagEntry(majorCategory: '체언(N)', tag: 'NR', description: '수사'),
  KiwiPosTagEntry(majorCategory: '체언(N)', tag: 'NP', description: '대명사'),

  KiwiPosTagEntry(majorCategory: '용언(V)', tag: 'VV', description: '동사'),
  KiwiPosTagEntry(majorCategory: '용언(V)', tag: 'VA', description: '형용사'),
  KiwiPosTagEntry(majorCategory: '용언(V)', tag: 'VX', description: '보조 용언'),
  KiwiPosTagEntry(
    majorCategory: '용언(V)',
    tag: 'VCP',
    description: '긍정 지정사(이다)',
  ),
  KiwiPosTagEntry(
    majorCategory: '용언(V)',
    tag: 'VCN',
    description: '부정 지정사(아니다)',
  ),

  KiwiPosTagEntry(majorCategory: '관형사', tag: 'MM', description: '관형사'),

  KiwiPosTagEntry(majorCategory: '부사(MA)', tag: 'MAG', description: '일반 부사'),
  KiwiPosTagEntry(majorCategory: '부사(MA)', tag: 'MAJ', description: '접속 부사'),

  KiwiPosTagEntry(majorCategory: '감탄사', tag: 'IC', description: '감탄사'),

  KiwiPosTagEntry(majorCategory: '조사(J)', tag: 'JKS', description: '주격 조사'),
  KiwiPosTagEntry(majorCategory: '조사(J)', tag: 'JKC', description: '보격 조사'),
  KiwiPosTagEntry(majorCategory: '조사(J)', tag: 'JKG', description: '관형격 조사'),
  KiwiPosTagEntry(majorCategory: '조사(J)', tag: 'JKO', description: '목적격 조사'),
  KiwiPosTagEntry(majorCategory: '조사(J)', tag: 'JKB', description: '부사격 조사'),
  KiwiPosTagEntry(majorCategory: '조사(J)', tag: 'JKV', description: '호격 조사'),
  KiwiPosTagEntry(majorCategory: '조사(J)', tag: 'JKQ', description: '인용격 조사'),
  KiwiPosTagEntry(majorCategory: '조사(J)', tag: 'JX', description: '보조사'),
  KiwiPosTagEntry(majorCategory: '조사(J)', tag: 'JC', description: '접속 조사'),

  KiwiPosTagEntry(majorCategory: '어미(E)', tag: 'EP', description: '선어말 어미'),
  KiwiPosTagEntry(majorCategory: '어미(E)', tag: 'EF', description: '종결 어미'),
  KiwiPosTagEntry(majorCategory: '어미(E)', tag: 'EC', description: '연결 어미'),
  KiwiPosTagEntry(majorCategory: '어미(E)', tag: 'ETN', description: '명사형 전성 어미'),
  KiwiPosTagEntry(majorCategory: '어미(E)', tag: 'ETM', description: '관형형 전성 어미'),

  KiwiPosTagEntry(majorCategory: '접두사', tag: 'XPN', description: '체언 접두사'),

  KiwiPosTagEntry(
    majorCategory: '접미사(XS)',
    tag: 'XSN',
    description: '명사 파생 접미사',
  ),
  KiwiPosTagEntry(
    majorCategory: '접미사(XS)',
    tag: 'XSV',
    description: '동사 파생 접미사',
  ),
  KiwiPosTagEntry(
    majorCategory: '접미사(XS)',
    tag: 'XSA',
    description: '형용사 파생 접미사',
  ),
  KiwiPosTagEntry(
    majorCategory: '접미사(XS)',
    tag: 'XSM',
    description: '부사 파생 접미사',
    customTag: true,
  ),

  KiwiPosTagEntry(majorCategory: '어근', tag: 'XR', description: '어근'),

  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SF',
    description: '종결 부호(. ! ?)',
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SP',
    description: '구분 부호(, / : ;)',
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SS',
    description: '인용 부호 및 괄호(\' " ( ) [ ] < > { } 등)',
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SSO',
    description: 'SS 중 여는 부호',
    customTag: true,
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SSC',
    description: 'SS 중 닫는 부호',
    customTag: true,
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SE',
    description: '줄임표(…)',
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SO',
    description: '붙임표(- ~)',
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SW',
    description: '기타 특수 문자',
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SL',
    description: '알파벳(A-Z a-z)',
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SH',
    description: '한자',
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SN',
    description: '숫자(0-9)',
  ),
  KiwiPosTagEntry(
    majorCategory: '부호, 외국어, 특수문자(S)',
    tag: 'SB',
    description: '순서 있는 글머리(가. 나. 1. 2. 등)',
    customTag: true,
  ),

  KiwiPosTagEntry(
    majorCategory: '분석 불능',
    tag: 'UN',
    description: '분석 불능',
    customTag: true,
  ),

  KiwiPosTagEntry(
    majorCategory: '웹(W)',
    tag: 'W_URL',
    description: 'URL 주소',
    customTag: true,
  ),
  KiwiPosTagEntry(
    majorCategory: '웹(W)',
    tag: 'W_EMAIL',
    description: '이메일 주소',
    customTag: true,
  ),
  KiwiPosTagEntry(
    majorCategory: '웹(W)',
    tag: 'W_HASHTAG',
    description: '해시태그(#abcd)',
    customTag: true,
  ),
  KiwiPosTagEntry(
    majorCategory: '웹(W)',
    tag: 'W_MENTION',
    description: '멘션(@abcd)',
    customTag: true,
  ),
  KiwiPosTagEntry(
    majorCategory: '웹(W)',
    tag: 'W_SERIAL',
    description: '일련번호(전화번호, 통장번호, IP주소 등)',
    customTag: true,
  ),
  KiwiPosTagEntry(
    majorCategory: '웹(W)',
    tag: 'W_EMOJI',
    description: '이모지',
    customTag: true,
  ),

  KiwiPosTagEntry(
    majorCategory: '기타',
    tag: 'Z_CODA',
    description: '덧붙은 받침',
    customTag: true,
  ),
  KiwiPosTagEntry(
    majorCategory: '기타',
    tag: 'Z_SIOT',
    description: '사이시옷',
    customTag: true,
  ),
  _userTagRangeEntry,
];

final Map<String, KiwiPosTagEntry> _posTagByTag = <String, KiwiPosTagEntry>{
  for (final KiwiPosTagEntry entry in kiwiPosTagEntries)
    if (entry.tag != _userTagRangeEntry.tag) entry.tag: entry,
};

const Set<String> _inflectionSuffixSupportedBaseTags = <String>{
  'VV',
  'VA',
  'VX',
  'XSA',
};

bool _isUserTag(String value) {
  return RegExp(r'^USER[0-4]$').hasMatch(value);
}

KiwiResolvedTag resolveKiwiPosTag(String rawTag) {
  final String normalized = rawTag.trim().toUpperCase();
  String baseTag = normalized;
  String? inflectionSuffix;
  String? inflectionDescription;

  final RegExpMatch? suffixMatch = RegExp(
    r'^([A-Z0-9_]+)-(R|I)$',
  ).firstMatch(normalized);
  if (suffixMatch != null) {
    baseTag = suffixMatch.group(1)!;
    inflectionSuffix = suffixMatch.group(2);
    if (_inflectionSuffixSupportedBaseTags.contains(baseTag)) {
      inflectionDescription = inflectionSuffix == 'R'
          ? '규칙 활용(-R)'
          : '불규칙 활용(-I)';
    } else {
      inflectionDescription = '접미 활용 정보가 포함된 태그';
    }
  }

  final KiwiPosTagEntry? entry =
      _posTagByTag[baseTag] ??
      (_isUserTag(baseTag) ? _userTagRangeEntry : null);

  return KiwiResolvedTag(
    rawTag: rawTag,
    normalizedTag: normalized,
    baseTag: baseTag,
    inflectionSuffix: inflectionSuffix,
    inflectionDescription: inflectionDescription,
    entry: entry,
  );
}

List<KiwiPosTagEntry> filterKiwiPosTagEntries(String query) {
  final String normalized = query.trim();
  if (normalized.isEmpty) {
    return kiwiPosTagEntries;
  }
  final String upper = normalized.toUpperCase();
  final String lower = normalized.toLowerCase();
  return kiwiPosTagEntries
      .where((KiwiPosTagEntry entry) {
        return entry.tag.contains(upper) ||
            entry.description.toLowerCase().contains(lower) ||
            entry.majorCategory.toLowerCase().contains(lower);
      })
      .toList(growable: false);
}
