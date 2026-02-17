/// Korean morphological analysis APIs powered by Kiwi.
///
/// This library provides a single `KiwiAnalyzer` interface across native
/// backends (FFI) and web backends (WASM).
///
/// Example:
/// ```dart
/// final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();
/// final KiwiAnalyzeResult result = await analyzer.analyze('안녕하세요');
/// await analyzer.close();
/// ```
library;

export 'src/kiwi_analyzer_stub.dart'
    if (dart.library.io) 'src/kiwi_analyzer_native.dart'
    if (dart.library.js_interop) 'src/kiwi_analyzer_web.dart';
export 'src/kiwi_exception.dart';
export 'src/kiwi_options.dart';
export 'src/kiwi_types.dart';
