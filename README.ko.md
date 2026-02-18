# flutter_kiwi_nlp (한국어)

Kiwi 기반 한국어 형태소 분석 Flutter 플러그인입니다.

## 목차

- [패키지명 안내](#패키지명-안내)
- [기술 보고서](#기술-보고서)
- [AI 활용 가이드](#ai-활용-가이드)
- [지원 플랫폼](#지원-플랫폼)
- [미지원 플랫폼](#미지원-플랫폼)
- [주요 기능](#주요-기능)
- [스크린샷](#스크린샷)
- [사용 가능한 API (요약 테이블)](#사용-가능한-api-요약-테이블)
- [용량 영향 (대략) 및 `kiwipiepy` 비교](#용량-영향-대략-및-kiwipiepy-비교)
- [성능 벤치마크 (`kiwipiepy` 비교)](#성능-벤치마크-kiwipiepy-비교)
- [설치](#설치)
- [Flutter 앱에 붙이기 (실전 예시)](#flutter-앱에-붙이기-실전-예시)
- [자주 쓰는 사용 패턴](#자주-쓰는-사용-패턴)
- [모델 경로 설정 가이드](#모델-경로-설정-가이드)
- [모델 경로 해석 순서](#모델-경로-해석-순서)
- [Android 자동 빌드](#android-자동-빌드)
- [iOS 자동 준비](#ios-자동-준비)
- [macOS 자동 준비](#macos-자동-준비)
- [Linux 자동 준비](#linux-자동-준비)
- [Windows 자동 준비](#windows-자동-준비)
- [자주 발생하는 문제](#자주-발생하는-문제)
- [라이선스](#라이선스)

## 패키지명 안내

현재 `pubspec.yaml`의 패키지명은 `flutter_kiwi_nlp`입니다.
의존성과 import는 `flutter_kiwi_nlp`를 사용하세요.

## 기술 보고서

- PDF: [`doc/technical_report_arxiv.pdf`](doc/technical_report_arxiv.pdf)
- arXiv 스타일 LaTeX 원문:
  [`doc/technical_report_arxiv.tex`](doc/technical_report_arxiv.tex)

## AI 활용 가이드

이 플러그인을 AI 코딩 도우미와 함께 사용할 때는 아래 순서가
가장 안정적입니다.

- LLM 인덱스: [`llms.txt`](llms.txt)
- 저장소 전용 스킬:
  [`skills/flutter-kiwi-nlp/SKILL.md`](skills/flutter-kiwi-nlp/SKILL.md)
- 스킬 API 참조:
  [`skills/flutter-kiwi-nlp/references/api-surface.md`](skills/flutter-kiwi-nlp/references/api-surface.md)
- 스킬 런타임/빌드 참조:
  [`skills/flutter-kiwi-nlp/references/runtime-and-build.md`](skills/flutter-kiwi-nlp/references/runtime-and-build.md)
- 스킬 검증 스크립트:
  [`skills/flutter-kiwi-nlp/scripts/verify_plugin.sh`](skills/flutter-kiwi-nlp/scripts/verify_plugin.sh)

Codex에서 스킬을 명시 호출하려면 프롬프트에 다음처럼 작성하세요.

```text
Use $flutter-kiwi-nlp to implement and validate this change.
```

변경 후 기본 검증:

```bash
./skills/flutter-kiwi-nlp/scripts/verify_plugin.sh
```

## 지원 플랫폼

| 플랫폼 | 상태 | 비고 |
| --- | --- | --- |
| Android | 지원 | `libkiwi.so`가 없으면 Android `preBuild` 단계에서 자동 빌드합니다. |
| iOS | 지원 | `Kiwi.xcframework`가 없으면 `pod install` 단계에서 자동 생성합니다. |
| macOS | 지원 | `libkiwi.dylib`가 없으면 `pod install` 단계에서 자동 생성합니다. |
| Linux | 지원 | `libkiwi.so`가 없으면 Linux 빌드 단계에서 생성합니다. |
| Windows | 지원 | `kiwi.dll`이 없으면 Windows 빌드 단계에서 생성합니다. |
| Web | 지원 | `kiwi-nlp` WASM 백엔드를 사용합니다. |

## 미지원 플랫폼

| 플랫폼 | 상태 | 비고 |
| --- | --- | --- |
| Fuchsia | 미지원 | Fuchsia 백엔드가 구현되어 있지 않습니다. |

## 주요 기능

- 네이티브(FFI)와 웹(WASM)에서 동일한 `KiwiAnalyzer` API 제공
- 타입 안전 결과 모델: `KiwiAnalyzeResult`, `KiwiCandidate`, `KiwiToken`
- `addUserWord`를 통한 런타임 사용자 사전 추가
- 기본 모델 에셋 내장 (`assets/kiwi-models/cong/base`)
- 네이티브: 기본 모델 자동 다운로드/캐시 fallback
- 웹: 동일 출처 에셋 URL 실패 시 아카이브 다운로드 fallback

## 스크린샷

| Web | macOS |
| --- | --- |
| ![Web 데모](doc/web.png) | ![macOS 데모](doc/macos.png) |

| Android (화면 1) | Android (화면 2) |
| --- | --- |
| ![Android 데모 1](doc/android_0.png) | ![Android 데모 2](doc/android_1.png) |

## 사용 가능한 API (요약 테이블)

### 핵심 API

| API | 시그니처 | 설명 |
| --- | --- | --- |
| `KiwiAnalyzer.create` | `Future<KiwiAnalyzer> create({String? modelPath, String? assetModelPath, int numThreads = -1, int buildOptions = KiwiBuildOption.defaultOption, int matchOptions = KiwiMatchOption.allWithNormalizing})` | 분석기 인스턴스를 생성합니다. 모델 경로/빌드 옵션/매치 옵션을 지정할 수 있습니다. |
| `KiwiAnalyzer.nativeVersion` | `String get nativeVersion` | 현재 백엔드 버전 문자열을 반환합니다. (예: native 버전, web/wasm 버전) |
| `KiwiAnalyzer.analyze` | `Future<KiwiAnalyzeResult> analyze(String text, {KiwiAnalyzeOptions options = const KiwiAnalyzeOptions()})` | 입력 문장을 형태소 분석하고 후보 목록을 반환합니다. |
| `KiwiAnalyzer.analyzeTokenCount` | `Future<int> analyzeTokenCount(String text, {KiwiAnalyzeOptions options = const KiwiAnalyzeOptions()})` | 분석 결과에서 첫 번째 후보의 토큰 수만 반환합니다. (토크나이저 중심 벤치마크에 유용) |
| `KiwiAnalyzer.addUserWord` | `Future<void> addUserWord(String word, {String tag = 'NNP', double score = 0.0})` | 런타임 사용자 사전에 단어를 추가합니다. |
| `KiwiAnalyzer.close` | `Future<void> close()` | 분석기를 종료하고 리소스를 정리합니다. |

지원되지 않는 플랫폼에서 `KiwiAnalyzer`를 생성/호출하면 `KiwiException`이 발생합니다.

### 옵션/상수 API

| API | 타입 | 설명 |
| --- | --- | --- |
| `KiwiAnalyzeOptions(topN, matchOptions)` | 클래스 | `analyze` 호출 시 사용할 옵션 객체입니다. 기본값은 `topN = 1`, `matchOptions = KiwiMatchOption.allWithNormalizing`입니다. |
| `KiwiBuildOption.integrateAllomorph` | `int` 비트 플래그 | 이형태 통합 옵션입니다. |
| `KiwiBuildOption.loadDefaultDict` | `int` 비트 플래그 | 기본 사전 로드 옵션입니다. |
| `KiwiBuildOption.loadTypoDict` | `int` 비트 플래그 | 오타 사전 로드 옵션입니다. |
| `KiwiBuildOption.loadMultiDict` | `int` 비트 플래그 | 복합어 사전 로드 옵션입니다. |
| `KiwiBuildOption.modelTypeDefault` | `int` | 모델 타입 상수입니다. |
| `KiwiBuildOption.modelTypeLargest` | `int` | 모델 타입 상수입니다. |
| `KiwiBuildOption.modelTypeKnlm` | `int` | 모델 타입 상수입니다. |
| `KiwiBuildOption.modelTypeSbg` | `int` | 모델 타입 상수입니다. |
| `KiwiBuildOption.modelTypeCong` | `int` | 모델 타입 상수입니다. |
| `KiwiBuildOption.modelTypeCongGlobal` | `int` | 모델 타입 상수입니다. |
| `KiwiBuildOption.defaultOption` | `int` | 권장 기본 빌드 옵션 조합입니다. |
| `KiwiMatchOption.url`/`email`/`hashtag`/`mention`/`serial` | `int` 비트 플래그 | URL/이메일/해시태그/멘션/일련번호 인식 옵션입니다. |
| `KiwiMatchOption.normalizeCoda` | `int` 비트 플래그 | 종성 정규화 옵션입니다. |
| `KiwiMatchOption.joinNounPrefix`/`joinNounSuffix` | `int` 비트 플래그 | 명사 접두/접미 결합 옵션입니다. |
| `KiwiMatchOption.joinVerbSuffix`/`joinAdjSuffix`/`joinAdvSuffix` | `int` 비트 플래그 | 용언/형용사/부사 접미 결합 옵션입니다. |
| `KiwiMatchOption.splitComplex` | `int` 비트 플래그 | 복합 형태 분리 옵션입니다. |
| `KiwiMatchOption.zCoda` | `int` 비트 플래그 | coda 처리 관련 옵션입니다. |
| `KiwiMatchOption.compatibleJamo` | `int` 비트 플래그 | 호환 자모 처리 옵션입니다. |
| `KiwiMatchOption.splitSaisiot`/`mergeSaisiot` | `int` 비트 플래그 | 사이시옷 분리/병합 옵션입니다. |
| `KiwiMatchOption.all` | `int` | 기본 매치 옵션 묶음입니다. |
| `KiwiMatchOption.allWithNormalizing` | `int` | `all + normalizeCoda` 조합입니다. |

### 결과/예외 모델 API

| API | 타입 | 설명 |
| --- | --- | --- |
| `KiwiAnalyzeResult.candidates` | `List<KiwiCandidate>` | 분석 후보 목록입니다. |
| `KiwiCandidate.probability` | `double` | 후보 점수(확률)입니다. |
| `KiwiCandidate.tokens` | `List<KiwiToken>` | 후보의 토큰 목록입니다. |
| `KiwiToken.form` | `String` | 토큰 원형 문자열입니다. |
| `KiwiToken.tag` | `String` | 품사 태그입니다. |
| `KiwiToken.start`/`length` | `int` | 원문 기준 시작 위치/길이입니다. |
| `KiwiToken.wordPosition`/`sentPosition` | `int` | 단어/문장 내 위치 인덱스입니다. |
| `KiwiToken.score`/`typoCost` | `double` | 토큰 점수/오타 비용입니다. |
| `KiwiException` | `Exception` | 플러그인 오류 타입입니다. `message` 필드로 상세 원인을 확인할 수 있습니다. |

## 용량 영향 (대략) 및 `kiwipiepy` 비교

기준일: `2026-02-18` (워크스페이스 스냅샷)

### A. 소스 아티팩트 기준 크기 (앱 패키징 전)

| 항목 | 기준 | 크기 | 비고 |
| --- | --- | --- | --- |
| `flutter_kiwi_nlp` 기본 모델 | 압축 해제 모델 디렉터리 (`assets/kiwi-models/cong/base`) | `99,308,057 bytes` (`94.71 MiB`) | 앱에 포함되는 모델 원본 총량 기준 |
| `flutter_kiwi_nlp` 기본 모델 (tgz) | 동일 디렉터리를 로컬에서 `.tgz` 압축 | `79,494,329 bytes` (`75.81 MiB`) | 로컬 압축 기준 비교값 |
| `kiwipiepy_model 0.22.1` | PyPI source distribution (`.tar.gz`) | `79.5 MB` (게시값) | PyPI 게시 압축 파일 크기 |
| Android `libkiwi.so` (소스 아티팩트, arm64-v8a) | `android/src/main/jniLibs/arm64-v8a/libkiwi.so` | `166,229,088 bytes` (`158.53 MiB`) | `with debug_info`, `not stripped` |
| Android `libkiwi.so` (소스 아티팩트, x86_64) | `android/src/main/jniLibs/x86_64/libkiwi.so` | `200,071,656 bytes` (`190.80 MiB`) | `with debug_info`, `not stripped` |

### B. Example 앱 패키지 결과 (debug vs release)

| 항목 | 기준 | 크기 | 비고 |
| --- | --- | --- | --- |
| `app-debug.apk` | `example/build/app/outputs/flutter-apk/app-debug.apk` | `178,454,872 bytes` (`170.19 MiB`) | Example 앱 빌드 결과 |
| `app-release.apk` | `example/build/app/outputs/flutter-apk/app-release.apk` | `113,030,559 bytes` (`107.80 MiB`) | Example 앱 빌드 결과 |
| APK 내부 `libkiwi.so` (arm64-v8a) | APK `lib/arm64-v8a/libkiwi.so` 엔트리 | `7,613,192 bytes` | Android 패키징 단계에서 strip 적용 |
| APK 내부 `libkiwi.so` (x86_64) | APK `lib/x86_64/libkiwi.so` 엔트리 | `11,381,344 bytes` | Android 패키징 단계에서 strip 적용 |
| release APK 내부 모델 파일 | `assets/.../kiwi-models/cong/base/*` 엔트리 합계 | 압축 `79,574,759 bytes` (원본 `99,308,057 bytes`) | APK ZIP 압축 적용 |

왜 숫자가 달라 보이나요?

- 비교 기준이 다르면 숫자가 크게 달라집니다.
- 소스 아티팩트 크기와 앱 패키지 결과 크기는 파이프라인 단계가 다릅니다.
- Android 패키징에서 네이티브 라이브러리 debug 심볼 strip이 적용됩니다.
- 모델 파일은 APK 내부에서 ZIP 압축되고, 소스 디렉터리는 비압축입니다.
- 현재 APK는 두 ABI(`arm64-v8a`, `x86_64`)를 함께 포함합니다.
  ABI split 배포를 쓰면 기기별 다운로드 크기를 더 줄일 수 있습니다.
- 최종 스토어 배포 크기는 app bundle split/배포 압축 정책에 따라
  추가로 달라질 수 있습니다.

참고 링크:

- https://pypi.org/project/kiwipiepy-model/
- https://pypi.org/project/kiwipiepy/

## 성능 벤치마크 (`kiwipiepy` 비교)

`flutter_kiwi_nlp` 성능을 `kiwipiepy`와 공정하게 비교하려면,
동일 코퍼스/동일 `top_n`/동일 워밍업 횟수로 측정해야 합니다.

이 저장소에는 비교 자동화를 위한 스크립트가 포함되어 있습니다.

1. 의존성 준비

```bash
uv venv
source .venv/bin/activate
cd example
flutter pub get
cd ..
uv pip install kiwipiepy
```

2. 벤치마크 실행 (예: macOS)

```bash
uv run python tool/benchmark/run_compare.py --device macos

# 논문용 반복 측정 + 옵션 동등화 예시
uv run python tool/benchmark/run_compare.py \
  --device macos \
  --trials 5 \
  --warmup-runs 3 \
  --measure-runs 15 \
  --num-threads -1 \
  --num-workers -1 \
  --build-options 1039 \
  --create-match-options 8454175 \
  --analyze-match-options 8454175

# 토크나이저 중심 비교 (Flutter token_count vs Python tokenize)
uv run python tool/benchmark/run_compare.py \
  --device macos \
  --flutter-analyze-impl token_count \
  --kiwi-analyze-impl tokenize
```

3. 결과 확인

```bash
cat benchmark/results/comparison.md
```

생성 파일:

- `benchmark/results/flutter_kiwi_benchmark_trials.json`
- `benchmark/results/kiwipiepy_benchmark_trials.json`
- `benchmark/results/flutter_kiwi_benchmark_trial_XX.json`
- `benchmark/results/kiwipiepy_benchmark_trial_XX.json`
- `benchmark/results/flutter_kiwi_benchmark.json` (호환용 단일 결과: 마지막 trial)
- `benchmark/results/kiwipiepy_benchmark.json` (호환용 단일 결과: 마지막 trial)
- `benchmark/results/comparison.md`

`run_compare.py` 옵션:

- `--trials`
- `--warmup-runs` / `--measure-runs` / `--top-n`
- `--num-threads` (Flutter 쪽)
- `--num-workers` (Python 쪽)
- `--build-options`
- `--create-match-options`
- `--analyze-match-options` (또는 `--match-options`)
- `--flutter-analyze-impl` (`json` 또는 `token_count`)
- `--kiwi-analyze-impl` (`analyze` 또는 `tokenize`)
- `--sample-count` (품사 비교에 포함할 샘플 문장 수)
- `--model-path` (양쪽 동일 모델 경로 강제)

Flutter 경로에서 JSON 직렬화/역직렬화 오버헤드를 제외한 토크나이저
핵심 처리량만 보고 싶다면 `--flutter-analyze-impl token_count`를 사용하세요.
Python 측에서도 토크나이저 중심 비교를 하려면
`--kiwi-analyze-impl tokenize`를 사용하세요.

생성 리포트에는 다음이 추가됩니다.

- 샘플 문장 품사 결과 비교 (`flutter_kiwi_nlp` vs `kiwipiepy`)
- Flutter JSON 직렬화/파싱 오버헤드 지표 (순수 경로 vs 전체 경로)

모바일 타깃(`ios`/`android`)에서는 `kiwipiepy`가 여전히 호스트 Python
런타임에서 실행됩니다. 동일 디바이스 Python 환경이 없다면 모바일 행은
cross-runtime 참고값으로 해석하세요.

표기 예시:

| 지표 | flutter_kiwi_nlp (평균 ± 표준편차) | kiwipiepy (평균 ± 표준편차) | 비율 (Flutter 평균 / Kiwi 평균) |
| --- | ---: | ---: | ---: |
| 초기화 시간 (ms, 낮을수록 좋음) | 120.40 ± 3.20 | 98.10 ± 2.80 | 1.23x (slower) |
| 처리량 (analyses/s, 높을수록 좋음) | 650.20 ± 12.30 | 702.90 ± 8.10 | 0.93x (slower) |
| 처리량 (chars/s, 높을수록 좋음) | 192004.11 ± 4102.30 | 200441.00 ± 2310.10 | 0.96x (slower) |
| 처리량 (tokens/s, 높을수록 좋음) | 94000.00 ± 2011.30 | 101200.00 ± 1188.40 | 0.93x (slower) |
| 평균 지연 (ms, 낮을수록 좋음) | 1.54 ± 0.03 | 1.42 ± 0.02 | 1.08x (slower) |
| 토큰당 지연 (us/token, 낮을수록 좋음) | 16.20 ± 0.25 | 14.75 ± 0.19 | 1.10x (slower) |

## 설치

### 1) pub.dev에서 설치 (권장)

```bash
flutter pub add flutter_kiwi_nlp
```

또는 `pubspec.yaml`에 직접 추가:

```yaml
dependencies:
  flutter_kiwi_nlp: ^0.1.1
```

```bash
flutter pub get
```

### 2) 로컬 경로로 설치 (플러그인 개발/테스트)

```yaml
dependencies:
  flutter_kiwi_nlp:
    path: ../flutter_kiwi_nlp
```

```bash
flutter pub get
```

## Flutter 앱에 붙이기 (실전 예시)

### 1) import

```dart
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';
```

### 2) `StatefulWidget`에서 안전하게 초기화/해제

```dart
import 'package:flutter/material.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

class KiwiDemoPage extends StatefulWidget {
  const KiwiDemoPage({super.key});

  @override
  State<KiwiDemoPage> createState() => _KiwiDemoPageState();
}

class _KiwiDemoPageState extends State<KiwiDemoPage> {
  KiwiAnalyzer? _analyzer;
  bool _loading = false;
  String? _error;
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _initializeAnalyzer();
  }

  Future<void> _initializeAnalyzer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();
      if (!mounted) {
        await analyzer.close();
        return;
      }
      setState(() => _analyzer = analyzer);
    } on KiwiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _analyzeSample() async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final KiwiAnalyzeResult result = await analyzer.analyze(
        '왜 그리 부아가 나서 트집잡느냐?',
        options: const KiwiAnalyzeOptions(
          topN: 1,
          matchOptions: KiwiMatchOption.allWithNormalizing,
        ),
      );

      final String line = result.candidates.first.tokens
          .map((KiwiToken token) => '${token.form}/${token.tag}')
          .join(' ');

      if (!mounted) return;
      setState(() => _resultText = line);
    } on KiwiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _analyzer?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FilledButton(
          onPressed: _loading ? null : _analyzeSample,
          child: const Text('분석 실행'),
        ),
        if (_error != null) Text('오류: $_error'),
        if (_resultText.isNotEmpty) Text(_resultText),
      ],
    );
  }
}
```

Dart/Flutter 포인트:

- `KiwiAnalyzer.create()`와 `analyze()`는 `Future`를 반환하므로 `await`
  + `try-catch`로 처리해야 합니다.
- `_analyzer` 타입이 `KiwiAnalyzer?`인 이유는 null-safety 때문입니다.
  초기화 전에는 `null`일 수 있습니다.
- `await` 뒤에 `setState`를 호출할 때는 `mounted`를 확인해야 안전합니다.

## 자주 쓰는 사용 패턴

### 사용자 사전 추가

```dart
await analyzer.addUserWord(
  '플러터키위',
  tag: 'NNP',
  score: 2.0,
);
```

### 분석 옵션 튜닝

```dart
const KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
  topN: 3,
  matchOptions: KiwiMatchOption.url |
      KiwiMatchOption.email |
      KiwiMatchOption.hashtag |
      KiwiMatchOption.normalizeCoda,
);
```

`matchOptions`는 비트 OR(`|`)로 조합합니다.

### 결과 순회

```dart
final KiwiAnalyzeResult result = await analyzer.analyze('문장을 입력하세요.');
for (final KiwiCandidate candidate in result.candidates) {
  debugPrint('candidate p=${candidate.probability}');
  for (final KiwiToken token in candidate.tokens) {
    debugPrint('${token.form}\t${token.tag}');
  }
}
```

## 모델 경로 설정 가이드

### A. 기본 내장 모델 사용 (가장 간단)

아무 설정 없이 아래처럼 생성하면 플러그인 기본 경로를 순서대로 탐색합니다.

```dart
final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();
```

### B. 앱 에셋 모델 사용

앱이 자체 모델 파일을 갖고 있다면 앱 `pubspec.yaml`에 선언 후
`assetModelPath`를 넘깁니다.

```yaml
flutter:
  assets:
    - assets/kiwi-models/cong/base/
```

```dart
final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
  assetModelPath: 'assets/kiwi-models/cong/base',
);
```

### C. 파일 시스템 모델 경로 사용

```dart
final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
  modelPath: '<MODEL_DIR>/kiwi-models/cong/base',
);
```

데스크톱/CI에서는 환경변수 방식도 가능합니다.

```bash
FLUTTER_KIWI_NLP_MODEL_PATH=<MODEL_DIR> flutter run -d macos
```

PowerShell:

```powershell
$env:FLUTTER_KIWI_NLP_MODEL_PATH='<MODEL_DIR>\kiwi\model\cong\base'
flutter run -d windows
```

### D. `--dart-define`로 기본값 지정

```bash
flutter run \
  --dart-define=FLUTTER_KIWI_NLP_ASSET_MODEL_PATH=assets/kiwi-models/cong/base
```

웹에서 모델 base URL을 고정하려면:

```bash
flutter run -d chrome \
  --dart-define=FLUTTER_KIWI_NLP_WEB_MODEL_BASE_URL=/assets/kiwi-models/cong/base
```

## 모델 경로 해석 순서

### 네이티브 (`dart:io`)

`KiwiAnalyzer.create()` 기준:

1. `modelPath` 인자
2. `assetModelPath` 인자
3. `FLUTTER_KIWI_NLP_MODEL_PATH` (환경변수)
4. `FLUTTER_KIWI_NLP_ASSET_MODEL_PATH` (`--dart-define`)
5. 내장 에셋 후보 경로
6. 기본 모델 아카이브 다운로드/압축 해제

기본 아카이브 URL:

- `https://github.com/bab2min/Kiwi/releases/download/v0.22.2/kiwi_model_v0.22.2_base.tgz`

### 웹

웹 모델 로딩 우선순위:

1. `modelPath` / `assetModelPath` 인자
2. `FLUTTER_KIWI_NLP_WEB_MODEL_BASE_URL`
3. `assets/packages/flutter_kiwi_nlp/assets/kiwi-models/cong/base`

에셋 URL 방식이 실패하면 아카이브 다운로드로 fallback합니다.

## Android 자동 빌드

플러그인은 `android/build.gradle`의 `preBuild`에서
`tool/build_android_libkiwi.sh`를 호출합니다.

- 기본적으로 기존 ABI 출력 파일이 있으면 skip
- 강제 재빌드: `--rebuild`
- 한 번만 자동 빌드 비활성화:
  - `-Pflutter.kiwi.skipAndroidLibBuild=true`

## iOS 자동 준비

플러그인은 `ios/flutter_kiwi_nlp.podspec`의 `prepare_command`에서
`tool/build_ios_kiwi_xcframework.sh`를 호출합니다.

- `ios/Frameworks/Kiwi.xcframework`가 없으면 `pod install` 단계에서 자동 생성
- 필요 도구: macOS, Xcode(및 Command Line Tools), `cmake`, `git`
- 한 번만 자동 빌드 비활성화:
  - `FLUTTER_KIWI_SKIP_IOS_FRAMEWORK_BUILD=true flutter run -d ios`
- 강제 재빌드:
  - `FLUTTER_KIWI_IOS_REBUILD=true flutter run -d ios`

## macOS 자동 준비

플러그인은 `macos/flutter_kiwi_nlp.podspec`의 `prepare_command`에서
`tool/build_macos_kiwi_dylib.sh`를 호출합니다.

- `macos/Frameworks/libkiwi.dylib`가 없으면 `pod install` 단계에서 자동 생성
- 기본 타깃 아키텍처: `arm64,x86_64` (`lipo`로 유니버설 바이너리 생성)
- 필요 도구: macOS, Xcode(및 Command Line Tools), `cmake`, `git`
- 한 번만 자동 빌드 비활성화:
  - `FLUTTER_KIWI_SKIP_MACOS_LIBRARY_BUILD=true flutter run -d macos`
- 강제 재빌드:
  - `FLUTTER_KIWI_MACOS_REBUILD=true flutter run -d macos`
- 타깃 아키텍처 강제 지정:
  - `FLUTTER_KIWI_MACOS_ARCHS=arm64 flutter run -d macos`

## Linux 자동 준비

플러그인은 `linux/CMakeLists.txt`의 커스텀 타깃에서
`tool/build_linux_libkiwi.sh`를 호출합니다.

- `linux/prebuilt/libkiwi.so`가 없으면 Linux 빌드 단계에서 자동 생성
- 기본 타깃 아키텍처: 현재 호스트 아키텍처(`x86_64`, `arm64` 등)
- 가능하면 Kiwi 공식 릴리스 prebuilt를 먼저 사용하고,
  불가능하면 소스 빌드로 fallback
- 필요 도구: Linux 호스트, `cmake`, `git`, C/C++ 빌드 도구
- 한 번만 자동 빌드 비활성화:
  - `FLUTTER_KIWI_SKIP_LINUX_LIBRARY_BUILD=true flutter run -d linux`
- 강제 재빌드:
  - `FLUTTER_KIWI_LINUX_REBUILD=true flutter run -d linux`
- 타깃 아키텍처 강제 지정:
  - `FLUTTER_KIWI_LINUX_ARCH=x86_64 flutter run -d linux`

## Windows 자동 준비

플러그인은 `windows/CMakeLists.txt`의 커스텀 타깃에서
`tool/build_windows_kiwi_dll.ps1`를 호출합니다.

- `windows/prebuilt/kiwi.dll`이 없으면 Windows 빌드 단계에서 자동 생성
- 기본 타깃 아키텍처: CMake generator platform(`x64`, `Win32`, `arm64`)
- 가능하면 Kiwi 공식 릴리스 prebuilt를 먼저 사용하고,
  불가능하면 소스 빌드로 fallback
- 필요 도구: Windows 호스트, PowerShell, Visual Studio C++ 툴체인,
  `cmake`, `git`
- 한 번만 자동 빌드 비활성화:
  - `$env:FLUTTER_KIWI_SKIP_WINDOWS_LIBRARY_BUILD='true'; flutter run -d windows`
- 강제 재빌드:
  - `$env:FLUTTER_KIWI_WINDOWS_REBUILD='true'; flutter run -d windows`
- 타깃 아키텍처 강제 지정:
  - `$env:FLUTTER_KIWI_WINDOWS_ARCH='x64'; flutter run -d windows`

## 자주 발생하는 문제

- `Failed to load Kiwi dynamic library`
  - 플랫폼별 네이티브 라이브러리 존재 여부 확인
  - 필요 시 `FLUTTER_KIWI_NLP_LIBRARY_PATH` 지정
- Android 자동 빌드 실패 (`cmake`/`git`/NDK 누락)
  - `ANDROID_NDK_HOME` 또는 `ANDROID_NDK_ROOT` 설정
  - `cmake`, `git` PATH 확인
- iOS 자동 빌드 실패 (`xcodebuild`/`cmake`/`git` 누락)
  - Xcode 실행 후 라이선스/초기 구성 완료
  - `xcode-select --install` 확인
  - `cmake`, `git` PATH 확인
- macOS 자동 빌드 실패 (`xcrun`/`cmake`/`git` 누락)
  - Xcode 실행 후 라이선스/초기 구성 완료
  - `xcode-select --install` 확인
  - `cmake`, `git` PATH 확인
- Linux 자동 빌드 실패 (`cmake`/`git`/컴파일러 누락)
  - `build-essential`(또는 동등 패키지), `cmake`, `git` 설치
  - 필요한 명령이 PATH에 있는지 확인
- Windows 자동 빌드 실패 (`powershell`/`cmake`/`git`/MSVC 누락)
  - Visual Studio C++ 빌드 도구(Desktop development with C++) 설치
  - `cmake`, `git`, MSVC 툴체인을 인식하는 셸에서 실행
- 모델 경로 관련 오류
  - `modelPath`/`assetModelPath` 전달 또는
    `FLUTTER_KIWI_NLP_MODEL_PATH` 설정

## 라이선스

`LICENSE`를 참고하세요.
