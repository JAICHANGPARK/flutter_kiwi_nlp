# Flutter + Kiwi 한국어 형태소 분석 플러그인 개발기: 온디바이스 구현, 코드 예제, 벤치마크까지

부제: `flutter_kiwi_nlp` 아키텍처, API 사용법, 성능 벤치마크, 운영 팁까지 한 번에 정리

---

한국어 NLP를 모바일/데스크톱 앱에 붙일 때 가장 많이 겪는 문제는 크게 세 가지입니다.

1. 서버 의존성 때문에 지연 시간과 비용이 증가한다.
2. 오프라인 환경이나 네트워크 품질 저하 상황에서 품질이 급격히 떨어진다.
3. 플랫폼(Android, iOS, macOS, Windows, Linux, Web)별로 구현이 갈라진다.

`flutter_kiwi_nlp`는 이 문제를 꽤 현실적인 방식으로 해결합니다.  
핵심은 **같은 Dart API로 네이티브(FFI)와 웹(WASM)을 모두 지원**하고, 한국어 형태소 분석기 Kiwi를 온디바이스로 실행한다는 점입니다.

이 글에서는 단순 사용법을 넘어서 아래를 다룹니다.

- 왜 이 접근이 실무에서 유리한지
- 코드 레벨에서 어떻게 구성하면 유지보수가 쉬운지
- 벤치마크를 어떻게 공정하게 측정해야 하는지
- 실제 측정 결과(실행 로그 기반)와 해석

---

## TL;DR

- `KiwiAnalyzer.create()`로 분석기 인스턴스를 만들고 `analyze()`를 호출하면 된다.
- API는 `Future` 기반 비동기 모델이라 UI 스레드를 막지 않는다.
- 사용자 사전(`addUserWord`)을 런타임에 추가할 수 있다.
- 동일 코퍼스/동일 조건에서 비교한 실측 결과(2026-02-17, macOS arm64) 기준:
  - 처리량(analyses/s): `flutter_kiwi_nlp` 2512.32, `kiwipiepy` 4061.90
  - 평균 지연(ms): `flutter_kiwi_nlp` 0.40, `kiwipiepy` 0.25
- 결론: Python 레퍼런스 대비 느린 구간이 있지만, 앱 내 직접 탑재와 단일 Flutter API라는 장점이 크다.

---

## 왜 이 플러그인을 만들었는가

처음 이 플러그인을 만든 이유는 단순했습니다.
"Flutter 앱에서 한국어 형태소 분석을 쓰고 싶은데, 실무에서 바로 쓸 수 있는
경로가 생각보다 불편하다"는 문제를 줄이고 싶었습니다.
온디바이스 AI 구현에 필요한 한국어 형태소 분석기가 필요했습니다.
그리고 더 직접적인 이유도 있었습니다.
플러터로 Kiwi 한국어 형태소 분석기를 활용할 수 있는 패키지가 사실상 없었습니다.
그래서 전 플랫폼 지원이 가능한 플러그인 개발을 하기로 했습니다.

현장에서 반복해서 마주친 불편은 아래와 같았습니다.

- Python 생태계 중심 예제가 많아 Flutter 앱에 직접 이식하기 어렵다.
- Android/iOS/desktop/web을 같이 지원하려면 플랫폼별 구현 부담이 급격히 커진다.
- 모델 파일 경로/배포/초기화 실패 같은 운영 이슈가 개발 속도를 크게 낮춘다.
- 팀마다 분석 옵션/사전 관리 방식이 달라 재현 가능한 검증 체계를 만들기 어렵다.

그래서 목표를 이렇게 잡았습니다.

1. 앱 개발자가 `KiwiAnalyzer.create()`만 호출해도 동작하는 기본 경로 제공
2. 네이티브와 웹에서 동일 API 유지
3. 모델 경로/다운로드/에셋 fallback까지 포함한 운영 친화적 설계
4. 성능 비교를 "감"이 아니라 데이터로 말할 수 있게 벤치마크 자동화

---

## AI 사용자 활용 가이드 (LLM + Skills)

이 프로젝트는 AI 코딩 도우미와 함께 사용할 때 생산성이 크게 올라갑니다.
핵심은 모델에게 "레포 구조 + 스킬 + 검증 루틴"을 함께 주는 것입니다.
현 시점 AI 활용 사용자들을 위해 패키지를 용이하게 활용할 수 있도록
`skills`를 만들어 제공했습니다.

권장 레퍼런스:

- LLM 인덱스: `llms.txt`
- 저장소 스킬: `skills/flutter-kiwi-nlp/SKILL.md`
- API 표면 참조: `skills/flutter-kiwi-nlp/references/api-surface.md`
- 런타임/빌드 참조:
  `skills/flutter-kiwi-nlp/references/runtime-and-build.md`
- 검증 스크립트: `skills/flutter-kiwi-nlp/scripts/verify_plugin.sh`

### 이 워크스페이스 Skills 사용법

이 워크스페이스에서는 아래 순서로 쓰는 것이 가장 안정적입니다.

1. 프롬프트 첫 줄에서 스킬을 명시 호출
2. 목표(무엇을 바꿀지)와 제약(무엇은 깨지면 안 되는지)을 함께 전달
3. 검증 범위(analyze/test/benchmark)를 명시
4. 결과 보고 형식(수정 파일, 핵심 diff, 검증 결과)을 지정

가장 기본 호출 패턴:

```text
Use $flutter-kiwi-nlp to implement and validate this change.
```

기능 추가 요청 템플릿:

```text
Use $flutter-kiwi-nlp to implement and validate this change.

Task:
- Add [feature name] to the plugin/example app.
- Keep native/web API parity.

Constraints:
- Do not break existing benchmark scripts under tool/benchmark.
- Keep public API backward compatible unless explicitly noted.

Validation:
- Run flutter analyze (root + example).
- Run example tests.
- Run ./skills/flutter-kiwi-nlp/scripts/verify_plugin.sh.
```

문서/벤치마크 갱신 요청 템플릿:

```text
Use $flutter-kiwi-nlp to update docs and benchmark artifacts.

Task:
- Re-run benchmark comparison and refresh markdown/json outputs.
- Update README sections that reference benchmark workflow.

Report:
- List updated files.
- Include benchmark delta summary.
```

추가 팁:

- 스킬 본문은 `skills/flutter-kiwi-nlp/SKILL.md`에 있으므로,
  AI가 해당 파일을 먼저 읽고 작업하게 유도하면 정확도가 올라갑니다.
- API 변경 작업은 `skills/flutter-kiwi-nlp/references/api-surface.md`를
  근거로 하게 하면 회귀를 줄일 수 있습니다.
- 런타임/빌드 이슈는
  `skills/flutter-kiwi-nlp/references/runtime-and-build.md`를
  함께 참조하게 하면 해결 속도가 빨라집니다.

AI에게 바로 쓸 수 있는 프롬프트 예시:

```text
Use $flutter-kiwi-nlp to implement and validate this change.

Goal:
- Add a domain dictionary bootstrap for ecommerce terms.
- Keep native/web API parity.
- Do not break benchmark scripts.

Validation:
- Run analyze/lint/tests used in this repo.
- Run ./skills/flutter-kiwi-nlp/scripts/verify_plugin.sh.
- Summarize behavioral changes and benchmark impact.
```

활용 팁:

- 작업 요청 시 목표와 제약을 같이 적기
- "어떤 파일을 근거로 판단했는지"를 반드시 보고받기
- 기능 변경 후 벤치마크 경로(`tool/benchmark/`)까지 검증시키기
- PR 설명에 생성된 산출물(`benchmark/results/*.json`, `comparison.md`) 첨부하기

---

## 개발기: 실제로 어떤 문제를 어떻게 풀었나

이 글이 단순 사용법 요약으로 보이지 않도록, 실제 개발 흐름을 간단히 남깁니다.
아래는 기능을 확장할 때 반복된 "문제 → 결정 → 결과" 패턴입니다.

### 1) 시작: Flutter에서 Korean NLP를 같은 API로 쓰고 싶었다

초기 버전의 핵심 과제는 API 표면을 간결하게 유지하는 것이었습니다.

- `create`, `analyze`, `addUserWord`, `close`에 집중
- 결과는 `KiwiAnalyzeResult`, `KiwiCandidate`, `KiwiToken`로 타입화
- 지원되지 않는 플랫폼은 조용히 실패하지 않고 `KiwiException`으로 명시 처리

이 선택 덕분에 앱 코드에서는 플랫폼 분기보다 도메인 로직에 집중할 수 있었습니다.

### 2) 가장 컸던 난점: "모델 경로 문제"를 사용자에게 떠넘기지 않기

형태소 분석기에서 실전 장애를 많이 만드는 지점이 모델 파일입니다.
경로가 조금만 어긋나도 초기화가 실패하고, 팀마다 환경이 달라 재현이 어렵습니다.

그래서 모델 로딩을 다단계 fallback으로 설계했습니다.

- 명시 `modelPath`가 있으면 우선 사용
- 번들된 에셋 경로를 자동 탐색
- 필요하면 기본 모델을 다운로드/캐시해 재사용

즉, "앱 개발자가 경로를 다 맞춰야만 동작"하는 구조를 피하고, 기본값이 동작하는
경험을 우선했습니다.

### 3) 멀티플랫폼 현실: 기능보다 배포 자동화가 먼저 막힌다

실제로는 분석 로직보다 플랫폼 준비 단계에서 시간이 더 많이 들었습니다.

- macOS: `pod install` 단계에서 필요한 아티팩트 준비
- Linux/Windows: 빌드 시점에 네이티브 라이브러리 준비
- Android: ABI별 라이브러리와 빌드 경로 정리
- Web: WASM 모듈/모델 파일 로딩 실패 시 fallback 경로 필요

이 부분은 문서화만으로 해결이 안 되기 때문에, 스크립트/빌드 훅/자동 준비
경로를 코드로 넣어 "실패할 때 덜 아프게" 만드는 쪽으로 정리했습니다.

### 4) AI 협업 관점에서의 개선

패키지 기능이 늘수록 "AI가 무엇을 읽고 어떻게 검증해야 하는지"가 중요해졌습니다.
그래서 문서뿐 아니라 스킬을 함께 제공합니다.

- 레포 맥락을 빠르게 주입하는 `llms.txt`
- 작업 절차를 표준화하는 `skills/flutter-kiwi-nlp/SKILL.md`
- API/런타임 참조 문서와 검증 스크립트

핵심은 AI 사용자가 한 번의 프롬프트로 "구현 + 검증 + 보고"까지
일관되게 수행할 수 있게 만드는 것입니다.

### 5) 성능 논의를 데이터 중심으로 바꾸기

"체감상 빠르다/느리다"만으로는 협업이 어렵습니다.
그래서 동일 코퍼스/동일 파라미터 비교를 자동화하는 벤치마크 스크립트를 추가했습니다.

- Flutter 실행 결과 JSON 생성
- `kiwipiepy` 실행 결과 JSON 생성
- 최종 비교표 markdown 자동 생성

이제 PR에서 성능 이야기를 할 때, 재현 가능한 파일을 근거로 얘기할 수 있습니다.

---

## 1) 왜 온디바이스 한국어 NLP인가

서버 기반 NLP는 강력하지만, 모바일/클라이언트 앱 입장에서는 아래 비용이 숨어 있습니다.

- 네트워크 왕복 지연(RTT) + 혼잡 구간에서 tail latency 증가
- API 호출 비용 누적
- 텍스트 데이터 외부 전송에 따른 개인정보/보안 이슈
- 오프라인 모드 부재

반면 온디바이스 분석은 다음이 강점입니다.

- 입력 즉시 응답(특히 짧은 문장 반복 분석에서 체감 큼)
- 오프라인 대응
- 프라이버시 친화적 아키텍처
- 기능 개발 속도(서버 스펙 변경 없이 앱 레벨 반복 가능)

`flutter_kiwi_nlp`는 여기에 더해, 앱 개발자가 흔히 원하는 두 가지를 제공합니다.

- 공통 API: 네이티브/웹에서 동일한 `KiwiAnalyzer` 인터페이스
- 런타임 사용자 사전: 도메인 용어를 즉시 반영

---

## 2) 최소 동작 코드: 10분 안에 붙이기

먼저 의존성을 추가합니다.

```bash
flutter pub add flutter_kiwi_nlp
```

기본 형태소 분석 흐름은 아래와 같습니다.

```dart
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

Future<void> runBasicAnalysis() async {
  final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
    numThreads: -1,
    matchOptions: KiwiMatchOption.allWithNormalizing,
  );

  try {
    final KiwiAnalyzeResult result = await analyzer.analyze(
      '온디바이스 NLP는 지연 시간과 비용을 동시에 줄일 수 있습니다.',
      options: const KiwiAnalyzeOptions(topN: 1),
    );

    for (final KiwiToken token in result.candidates.first.tokens) {
      // 예: 온디바이스/NNG, NLP/SL ...
      print('${token.form}/${token.tag}');
    }
  } finally {
    await analyzer.close();
  }
}
```

### 코드 설명

- `Future`/`async`/`await`
  - 모델 로딩과 분석은 I/O/연산이 포함되므로 비동기입니다.
  - `await`를 사용하면 콜백 체인보다 읽기 쉽고 에러 처리(`try/catch`)가 명확합니다.
- Null safety
  - `result.candidates.first`를 사용하기 전에 후보가 비어 있는지 확인하는 방어 코드가 실무에서는 더 안전합니다.
- 리소스 정리
  - `analyzer.close()`를 반드시 호출해 네이티브 리소스 누수를 방지합니다.

---

## 3) 실무형 래퍼: 서비스 계층으로 격리하기

앱 규모가 커질수록 `KiwiAnalyzer`를 UI에 직접 노출하지 않는 것이 좋습니다.  
아래처럼 서비스 계층을 두면 테스트와 교체가 쉬워집니다.

```dart
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

class KiwiNlpService {
  KiwiAnalyzer? _analyzer;

  bool get isReady => _analyzer != null;

  Future<void> initialize({
    String? modelPath,
    String? assetModelPath,
    int numThreads = -1,
  }) async {
    await dispose();
    _analyzer = await KiwiAnalyzer.create(
      modelPath: modelPath,
      assetModelPath: assetModelPath,
      numThreads: numThreads,
      matchOptions: KiwiMatchOption.allWithNormalizing,
    );
  }

  Future<List<KiwiToken>> tokenize(
    String sentence, {
    int topN = 1,
    int matchOptions = KiwiMatchOption.allWithNormalizing,
  }) async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null) {
      throw const KiwiException('Analyzer is not initialized.');
    }

    final KiwiAnalyzeResult result = await analyzer.analyze(
      sentence,
      options: KiwiAnalyzeOptions(
        topN: topN,
        matchOptions: matchOptions,
      ),
    );

    if (result.candidates.isEmpty) {
      return const <KiwiToken>[];
    }
    return result.candidates.first.tokens;
  }

  Future<void> addDomainWord(String word, {String tag = 'NNP'}) async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null) {
      throw const KiwiException('Analyzer is not initialized.');
    }
    await analyzer.addUserWord(word, tag: tag);
  }

  Future<void> dispose() async {
    final KiwiAnalyzer? analyzer = _analyzer;
    _analyzer = null;
    if (analyzer != null) {
      await analyzer.close();
    }
  }
}
```

### 왜 이 구조가 중요한가

- UI와 도메인 로직 분리
  - 화면 코드는 입력/출력에 집중하고, NLP 수명주기는 서비스에서 관리합니다.
- 테스트 용이성
  - 나중에 fake service를 주입하면 UI 테스트가 쉬워집니다.
- 운영 안전성
  - 재초기화, 종료, 예외 처리 포인트가 한 곳으로 모입니다.

---

## 4) 사용자 사전은 품질 개선의 지름길

한국어 서비스에서 실무 성능(체감 정확도)을 끌어올리는 가장 빠른 방법은 대개 사용자 사전입니다.

```dart
await analyzer.addUserWord('온디바이스NLP', tag: 'NNP');
```

도메인별 예시:

- 커머스: 상품명, 브랜드명, SKU 패턴
- 핀테크: 계좌/카드 도메인 용어
- B2B SaaS: 사내 제품명, 기능명, 약어

포인트는 복잡한 모델 재학습 없이도 앱 런타임에서 즉시 튜닝이 가능하다는 점입니다.

---

## 5) 옵션 설계: 정확도와 속도의 트레이드오프를 코드로 노출하기

`KiwiAnalyzeOptions`와 `KiwiMatchOption` 조합으로 분석 동작을 세밀하게 조절할 수 있습니다.

```dart
final KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
  topN: 3,
  matchOptions: KiwiMatchOption.url |
      KiwiMatchOption.email |
      KiwiMatchOption.hashtag |
      KiwiMatchOption.normalizeCoda |
      KiwiMatchOption.splitSaisiot,
);

final KiwiAnalyzeResult result = await analyzer.analyze(text, options: options);
```

튜닝 가이드:

- `topN`
  - 후보를 여러 개 보고 후처리에서 재랭킹하려면 2~5로 올립니다.
  - 순수 속도가 우선이면 1이 일반적으로 유리합니다.
- `matchOptions`
  - URL/이메일/해시태그 같은 패턴 인식이 필요하면 해당 플래그를 켭니다.
  - 입력 특성에 맞지 않는 옵션은 과감히 끄고 측정합니다.

---

## 6) 벤치마크를 공정하게 측정하는 방법

형태소 분석 벤치마크는 비교 조건이 조금만 달라도 숫자가 크게 바뀝니다.  
이 프로젝트는 비교 자동화 스크립트를 제공합니다.

```bash
uv run --with kiwipiepy python tool/benchmark/run_compare.py \
  --device macos \
  --mode release
```

이 스크립트가 하는 일:

1. Flutter benchmark app 실행(`example/lib/benchmark_main.dart`)
2. 동일 코퍼스로 `kiwipiepy` 실행(`tool/benchmark/kiwipiepy_benchmark.py`)
3. 비교 리포트 생성(`tool/benchmark/compare_results.py`)

생성 파일:

- `benchmark/results/flutter_kiwi_benchmark.json`
- `benchmark/results/kiwipiepy_benchmark.json`
- `benchmark/results/comparison.md`

---

## 7) 실측 결과 (2026-02-17, macOS arm64)

실행 조건:

- 디바이스: macOS desktop (`darwin-arm64`)
- Flutter 모드: `release`
- 코퍼스: `example/assets/benchmark_corpus_ko.txt` (40문장)
- 공통 파라미터: `warmup=3`, `measure=15`, `top_n=1`

비교표:

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio (Flutter/Kiwi) |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | 1263.38 | 638.99 | 1.98x (slower) |
| Throughput (analyses/s, higher better) | 2512.32 | 4061.90 | 0.62x (slower) |
| Throughput (chars/s, higher better) | 85167.68 | 137698.25 | 0.62x (slower) |
| Throughput (tokens/s, higher better) | 40448.37 | 65294.97 | 0.62x (slower) |
| Avg latency (ms, lower better) | 0.40 | 0.25 | 1.62x (slower) |
| Avg token latency (us/token, lower better) | 24.72 | 15.32 | 1.61x (slower) |

원본 산출물:

- `benchmark/results/comparison.md`
- `benchmark/results/flutter_kiwi_benchmark.json`
- `benchmark/results/kiwipiepy_benchmark.json`

---

## 8) 결과 해석: 숫자 너머에서 봐야 할 것들

이번 측정에서는 `kiwipiepy`가 전 지표에서 앞섰습니다.  
하지만 실무 의사결정은 단순 최대 처리량 비교보다 조금 더 입체적으로 해야 합니다.

### 8-1. 왜 차이가 날 수 있나

- 런타임 경로 차이
  - Flutter 쪽은 Dart <-> FFI <-> 네이티브 경계를 반복 통과합니다.
  - 결과를 JSON으로 직렬화/역직렬화하는 구간 비용도 포함됩니다.
- 초기화 비용
  - 모델 로딩, 브리지 초기화, 런타임 세팅 비용이 포함됩니다.
- 토큰 카운트 차이
  - 이번 결과에서 total_tokens가 `9660` vs `9645`로 약간 달랐습니다.
  - 구현/집계 방식 차이(후보/토큰 처리 차이)가 미세하게 반영될 수 있습니다.

### 8-2. 그래도 Flutter 온디바이스가 갖는 가치

- 앱 코드 안에서 즉시 사용 가능한 단일 API
- 서버 호출 없이 동작
- 멀티플랫폼 동시 대응
- 사용자 사전 기반 빠른 도메인 튜닝

즉, 절대 수치 하나만으로 선택하기보다 **아키텍처 비용 전체**를 같이 봐야 합니다.

---

## 9) 성능 개선 체크리스트

아래는 앱에서 바로 적용 가능한 최적화 포인트입니다.

1. 분석기 재사용
   - 요청마다 `create()` 하지 말고, 앱 수명주기에서 재사용합니다.
2. `topN` 최소화
   - 후처리에서 여러 후보가 반드시 필요하지 않다면 `topN=1`.
3. 배치 입력 전략
   - 작은 문장을 지나치게 잘게 쪼개지 말고, 문장 단위 묶음 처리 실험.
4. 사용자 사전 설계
   - 정확도 향상으로 재분석/재시도 횟수를 줄여 전체 지연 개선.
5. isolate 활용
   - 긴 분석 루프나 대량 처리 UI 작업은 백그라운드로 분리.

---

## 10) UI 스레드 보호: `compute`로 백그라운드 실행

예제 앱은 벤치마크 루프를 분리 실행합니다.

```dart
final Map<String, Object?> rawResult = kIsWeb
    ? await _runBenchmarkInBackground(payload)
    : await compute<Map<String, Object>, Map<String, Object?>>(
        _runBenchmarkInBackground,
        payload,
        debugLabel: 'kiwi-benchmark',
      );
```

핵심 포인트:

- 메인 isolate의 프레임 드롭 위험을 줄입니다.
- 긴 반복 연산이 UI 상호작용을 막는 상황을 완화합니다.
- `kIsWeb` 분기처럼 플랫폼별 실행 모델 차이를 코드에 명시적으로 표현합니다.

---

## 11) 운영 관점에서 자주 부딪히는 이슈

### 모델 경로

- 로컬 경로, 에셋 경로, 환경 변수 등 경로 정책을 팀 내에서 통일하세요.
- 릴리스 빌드에서 번들 누락이 없는지 CI에서 검증하세요.

### 에러 처리

- `KiwiException`을 UI 메시지와 내부 로그로 분리하세요.
- 사용자에게는 간결한 메시지, 로그에는 맥락(옵션/입력 크기/경로)을 남기세요.

### 관측성

- 초기화 시간, 분석 시간, 실패율을 지표로 수집하세요.
- 릴리스마다 벤치마크를 자동 실행해 회귀를 조기 탐지하세요.

---

## 12) 재현 가능한 실험 템플릿

팀 내에서 성능 회의를 할 때는 아래 4가지를 항상 고정하세요.

1. 코퍼스
2. 파라미터(`warmup`, `measure`, `top_n`)
3. 디바이스/OS
4. 빌드 모드(debug/profile/release)

추천 커맨드:

```bash
uv run --with kiwipiepy python tool/benchmark/run_compare.py \
  --device macos \
  --mode release \
  --warmup-runs 3 \
  --measure-runs 15 \
  --top-n 1
```

결과 파일은 PR 아티팩트로 첨부하면, 리뷰에서 감정 대신 데이터로 논의할 수 있습니다.

---

## 13) 마무리

`flutter_kiwi_nlp`는 "최고 절대 성능"만을 노리는 도구라기보다,  
**Flutter 앱에서 한국어 형태소 분석을 실용적으로 운영 가능하게 만드는 도구**에 가깝습니다.

핵심은 다음입니다.

- 개발 생산성: 멀티플랫폼 공통 API
- 운영 안정성: 온디바이스 실행 + 사용자 사전
- 성능 관리: 비교 벤치마크 스크립트 내장

다음 단계로는 프로젝트 요구사항에 맞춰 아래를 진행하는 것을 권장합니다.

1. 실제 서비스 문장으로 전용 코퍼스를 구성한다.
2. `topN`/옵션 플래그 조합을 실험해 정확도-지연 곡선을 만든다.
3. 릴리스 파이프라인에 벤치마크 비교 리포트를 자동 포함한다.

---

## 부록 A) 이번 실행의 원본 로그 핵심 라인

```text
flutter_kiwi_nlp:
  init_ms=1263.382
  analyses_per_sec=2512.3208401200886
  avg_latency_ms=0.3980383333333333

kiwipiepy:
  init_ms=638.9862920041196
  analyses_per_sec=4061.895377877922
  avg_latency_ms=0.24619048669895469
```

위 값은 단일 머신 단일 실행 결과입니다.  
정확한 비교를 위해서는 동일 조건 반복 측정(최소 5회 이상)과 분산/신뢰구간 확인을 권장합니다.
