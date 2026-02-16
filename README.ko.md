# flutter_kiwi_nlp (한국어)

Kiwi 기반 한국어 형태소 분석 Flutter 플러그인입니다.

## 패키지명 안내

현재 `pubspec.yaml`의 패키지명은 `flutter_kiwi_ffi`입니다.
패키지명 변경이 완료되기 전까지 의존성과 import는 `flutter_kiwi_ffi`를 사용하세요.

## 지원 플랫폼

| 플랫폼 | 상태 | 비고 |
| --- | --- | --- |
| Android | 지원 | `libkiwi.so`가 없으면 Android `preBuild` 단계에서 자동 빌드합니다. |
| iOS | 지원 | `Kiwi.xcframework`가 없으면 `pod install` 단계에서 자동 생성합니다. |
| macOS | 지원 | `macos/Frameworks/libkiwi.dylib` 또는 프레임워크 후보 경로를 사용합니다. |
| Linux | 지원 | `linux/prebuilt/libkiwi.so`를 사용합니다. |
| Windows | 지원 | `windows/prebuilt/kiwi.dll`을 사용합니다. |
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

## 설치

```yaml
dependencies:
  flutter_kiwi_ffi:
    path: ../flutter_kiwi_nlp
```

```bash
flutter pub get
```

## 빠른 시작

```dart
import 'package:flutter_kiwi_ffi/flutter_kiwi_ffi.dart';

Future<void> runDemo() async {
  final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();
  final KiwiAnalyzeResult result = await analyzer.analyze(
    '왜 그리 부아가 나서 트집잡느냐?',
    options: const KiwiAnalyzeOptions(topN: 1),
  );
  for (final KiwiCandidate c in result.candidates) {
    for (final KiwiToken t in c.tokens) {
      print('${t.form}/${t.tag}');
    }
  }
  await analyzer.close();
}
```

## 모델 경로 해석 순서

### 네이티브 (`dart:io`)

`KiwiAnalyzer.create()` 기준:

1. `modelPath` 인자
2. `assetModelPath` 인자
3. `FLUTTER_KIWI_FFI_MODEL_PATH` (환경변수)
4. `FLUTTER_KIWI_FFI_ASSET_MODEL_PATH` (`--dart-define`)
5. 내장 에셋 후보 경로
6. 기본 모델 아카이브 다운로드/압축 해제

기본 아카이브 URL:

- `https://github.com/bab2min/Kiwi/releases/download/v0.22.2/kiwi_model_v0.22.2_base.tgz`

### 웹

웹 모델 로딩 우선순위:

1. `modelPath` / `assetModelPath` 인자
2. `FLUTTER_KIWI_FFI_WEB_MODEL_BASE_URL`
3. `assets/packages/flutter_kiwi_ffi/assets/kiwi-models/cong/base`

에셋 URL 방식이 실패하면 아카이브 다운로드로 fallback합니다.

## Android 자동 빌드

플러그인은 `android/build.gradle`의 `preBuild`에서 `tool/build_android_libkiwi.sh`를 호출합니다.

- 기본적으로 기존 ABI 출력 파일이 있으면 skip
- 강제 재빌드: `--rebuild`
- 한 번만 자동 빌드 비활성화:
  - `-Pflutter.kiwi.skipAndroidLibBuild=true`

## iOS 자동 준비

플러그인은 `ios/flutter_kiwi_ffi.podspec`의 `prepare_command`에서 `tool/build_ios_kiwi_xcframework.sh`를 호출합니다.

- `ios/Frameworks/Kiwi.xcframework`가 없으면 `pod install` 단계에서 자동 생성
- 필요 도구: macOS, Xcode(및 Command Line Tools), `cmake`, `git`
- 한 번만 자동 빌드 비활성화:
  - `FLUTTER_KIWI_SKIP_IOS_FRAMEWORK_BUILD=true flutter run -d ios`
- 강제 재빌드:
  - `FLUTTER_KIWI_IOS_REBUILD=true flutter run -d ios`

## 자주 발생하는 문제

- `Failed to load Kiwi dynamic library`
  - 플랫폼별 네이티브 라이브러리 존재 여부 확인
  - 필요 시 `FLUTTER_KIWI_FFI_LIBRARY_PATH` 지정
- Android 자동 빌드 실패 (`cmake`/`git`/NDK 누락)
  - `ANDROID_NDK_HOME` 또는 `ANDROID_NDK_ROOT` 설정
  - `cmake`, `git` PATH 확인
- iOS 자동 빌드 실패 (`xcodebuild`/`cmake`/`git` 누락)
  - Xcode 실행 후 라이선스/초기 구성 완료
  - `xcode-select --install` 확인
  - `cmake`, `git` PATH 확인
- 모델 경로 관련 오류
  - `modelPath`/`assetModelPath` 전달 또는 `FLUTTER_KIWI_FFI_MODEL_PATH` 설정

## 라이선스

`LICENSE`를 참고하세요.
