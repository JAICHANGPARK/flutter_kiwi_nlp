class KiwiOptionPreset {
  final String id;
  final String title;
  final String description;
  final int topN;
  final bool integrateAllomorph;
  final bool normalizeCoda;
  final bool splitSaisiot;
  final bool joinNounPrefix;
  final bool joinNounSuffix;
  final bool joinVerbSuffix;
  final bool joinAdjSuffix;
  final bool joinAdvSuffix;
  final bool matchUrl;
  final bool matchEmail;
  final bool matchHashtag;
  final bool matchMention;
  final bool matchSerial;

  const KiwiOptionPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.topN,
    required this.integrateAllomorph,
    required this.normalizeCoda,
    required this.splitSaisiot,
    required this.joinNounPrefix,
    required this.joinNounSuffix,
    required this.joinVerbSuffix,
    required this.joinAdjSuffix,
    required this.joinAdvSuffix,
    required this.matchUrl,
    required this.matchEmail,
    required this.matchHashtag,
    required this.matchMention,
    required this.matchSerial,
  });
}

class KiwiDemoScenario {
  final String id;
  final String title;
  final String summary;
  final String text;
  final String presetId;
  final String? suggestedUserWord;
  final String suggestedUserWordTag;

  const KiwiDemoScenario({
    required this.id,
    required this.title,
    required this.summary,
    required this.text,
    required this.presetId,
    this.suggestedUserWord,
    this.suggestedUserWordTag = 'NNP',
  });
}

const List<KiwiOptionPreset> kiwiOptionPresets = <KiwiOptionPreset>[
  KiwiOptionPreset(
    id: 'default',
    title: '기본',
    description: '일반 문장 분석용 기본 설정',
    topN: 1,
    integrateAllomorph: true,
    normalizeCoda: false,
    splitSaisiot: true,
    joinNounPrefix: false,
    joinNounSuffix: false,
    joinVerbSuffix: false,
    joinAdjSuffix: false,
    joinAdvSuffix: false,
    matchUrl: false,
    matchEmail: false,
    matchHashtag: false,
    matchMention: false,
    matchSerial: false,
  ),
  KiwiOptionPreset(
    id: 'social',
    title: '소셜 텍스트',
    description: 'URL/메일/해시태그/멘션 탐지 예제',
    topN: 3,
    integrateAllomorph: true,
    normalizeCoda: false,
    splitSaisiot: true,
    joinNounPrefix: false,
    joinNounSuffix: false,
    joinVerbSuffix: false,
    joinAdjSuffix: false,
    joinAdvSuffix: false,
    matchUrl: true,
    matchEmail: true,
    matchHashtag: true,
    matchMention: true,
    matchSerial: false,
  ),
  KiwiOptionPreset(
    id: 'serial',
    title: '식별자 탐지',
    description: '시리얼/식별자 패턴 강조',
    topN: 3,
    integrateAllomorph: true,
    normalizeCoda: true,
    splitSaisiot: true,
    joinNounPrefix: false,
    joinNounSuffix: false,
    joinVerbSuffix: false,
    joinAdjSuffix: false,
    joinAdvSuffix: false,
    matchUrl: false,
    matchEmail: false,
    matchHashtag: false,
    matchMention: false,
    matchSerial: true,
  ),
  KiwiOptionPreset(
    id: 'compound',
    title: '복합어 결합',
    description: '파생 결합 옵션 중심',
    topN: 3,
    integrateAllomorph: true,
    normalizeCoda: true,
    splitSaisiot: false,
    joinNounPrefix: true,
    joinNounSuffix: true,
    joinVerbSuffix: true,
    joinAdjSuffix: true,
    joinAdvSuffix: true,
    matchUrl: false,
    matchEmail: false,
    matchHashtag: false,
    matchMention: false,
    matchSerial: false,
  ),
  KiwiOptionPreset(
    id: 'explore',
    title: '탐색 모드',
    description: '후보 5개 + 주요 매칭 옵션 전체',
    topN: 5,
    integrateAllomorph: true,
    normalizeCoda: true,
    splitSaisiot: true,
    joinNounPrefix: true,
    joinNounSuffix: true,
    joinVerbSuffix: true,
    joinAdjSuffix: true,
    joinAdvSuffix: true,
    matchUrl: true,
    matchEmail: true,
    matchHashtag: true,
    matchMention: true,
    matchSerial: true,
  ),
];

const List<KiwiDemoScenario> kiwiDemoScenarios = <KiwiDemoScenario>[
  KiwiDemoScenario(
    id: 'basic_dialog',
    title: '유명 구절',
    summary: '잘 알려진 시 구절 형태소 분석',
    presetId: 'default',
    text: '하늘을 우러러 한 점 부끄럼이 없기를,\n잎새에 이는 바람에도 나는 괴로워했다.',
  ),
  KiwiDemoScenario(
    id: 'social_text',
    title: '소셜/링크',
    summary: 'URL, 해시태그, 멘션 포함 문장',
    presetId: 'social',
    text: 'OpenAI 업데이트는 https://openai.com 에서 확인해줘.\n#AI #Flutter @kiwi_demo',
  ),
  KiwiDemoScenario(
    id: 'contact_text',
    title: '메일/문의',
    summary: '이메일과 멘션 중심',
    presetId: 'social',
    text: '문의는 support@example.com 으로 보내주세요.\n@product-team 확인 부탁드립니다.',
  ),
  KiwiDemoScenario(
    id: 'serial_text',
    title: '주문/시리얼',
    summary: '주문번호, 제품코드 분석',
    presetId: 'serial',
    text: '주문번호 ORD-2026-000139 의 배송 상태 알려줘.\n시리얼 SN-AX92-11C 도 확인해줘.',
  ),
  KiwiDemoScenario(
    id: 'spacing',
    title: '구어체/띄어쓰기',
    summary: '띄어쓰기 혼합 문장',
    presetId: 'explore',
    text: '오늘진짜날씨좋다 근데퇴근길엔비올수도있대.\n그냥 우산 챙겨가는게 좋을까?',
  ),
  KiwiDemoScenario(
    id: 'compound_words',
    title: '복합 명사',
    summary: '파생 결합 옵션 데모',
    presetId: 'compound',
    text: '초고속대용량데이터처리파이프라인을 재설계했다.\n실시간추천시스템정확도를 높였다.',
  ),
  KiwiDemoScenario(
    id: 'news_style',
    title: '뉴스 스타일',
    summary: '긴 문장, 후보 비교',
    presetId: 'explore',
    text:
        '정부는 오늘 디지털 인프라 고도화 계획을 발표했으며, 관련 예산은 단계적으로 확대될 예정이다.\n'
        '전문가들은 이번 정책이 중소기업의 AI 도입 속도를 높일 것으로 전망했다.',
  ),
  KiwiDemoScenario(
    id: 'custom_word',
    title: '사용자 사전',
    summary: '도메인 고유어 추가',
    presetId: 'default',
    text: '온디바이스NLP 성능을 비교해보자.\n키위플러그인 초기화 시간을 측정했다.',
    suggestedUserWord: '온디바이스NLP',
    suggestedUserWordTag: 'NNP',
  ),
];
