# flutter_kiwi_nlp (한국어)

Kiwi 기반 한국어 형태소 분석 Flutter 플러그인입니다.

## 패키지명 안내

현재 `pubspec.yaml`의 패키지명은 `flutter_kiwi_nlp`입니다.
의존성과 import는 `flutter_kiwi_nlp`를 사용하세요.

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

기준일: `2026-02-17`

| 항목 | 기준 | 크기(대략) | 비고 |
| --- | --- | --- | --- |
| `flutter_kiwi_nlp` 기본 모델 | 압축 해제 모델 디렉터리 (`assets/kiwi-models/cong/base`) | `95MB` | 앱 에셋으로 포함될 수 있는 실제 모델 파일 집합 |
| `flutter_kiwi_nlp` 기본 모델 (tgz) | 동일 디렉터리를 로컬에서 tar.gz 압축 (`/tmp/flutter_kiwi_model_base.tgz`) | `76MB` | 압축 기준 비교용 로컬 측정치 |
| `kiwipiepy_model 0.22.1` | PyPI source distribution (`.tar.gz`) | `79.5MB` | PyPI에 게시된 압축 배포 파일 크기 |
| Android `libkiwi.so` (참고) | 이 저장소 워크스페이스 빌드 산출물 | `159MB (arm64-v8a)`, `191MB (x86_64)` | 현재 파일은 `with debug_info`, `not stripped` 상태 |

왜 숫자가 달라 보이나요?

- 비교 기준이 다르면 숫자가 크게 달라집니다.
- `76MB`/`79.5MB`는 압축본(`.tgz`) 크기이고, `95MB`는 압축 해제된
  모델 파일 총합입니다.
- Android 네이티브 라이브러리는 ABI별 파일이 따로 있고, 디버그 심볼이
  포함되면 크기가 크게 증가합니다.
- 실제 스토어 배포 시에는 플랫폼별 strip/compress/split 적용으로
  다운로드 크기가 더 작아질 수 있습니다.

참고 링크:

- https://pypi.org/project/kiwipiepy-model/
- https://pypi.org/project/kiwipiepy/

## 설치

### 1) pub.dev에서 설치 (권장)

```bash
flutter pub add flutter_kiwi_nlp
```

또는 `pubspec.yaml`에 직접 추가:

```yaml
dependencies:
  flutter_kiwi_nlp: ^0.0.1
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
  modelPath: '/absolute/path/to/kiwi-models/cong/base',
);
```

데스크톱/CI에서는 환경변수 방식도 가능합니다.

```bash
FLUTTER_KIWI_NLP_MODEL_PATH=/absolute/path/to/model flutter run -d macos
```

PowerShell:

```powershell
$env:FLUTTER_KIWI_NLP_MODEL_PATH='C:\kiwi\model\cong\base'
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
