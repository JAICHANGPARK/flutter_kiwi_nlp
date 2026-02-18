import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../flutter_kiwi_ffi_bindings_generated.dart';
import 'kiwi_exception.dart';
import 'kiwi_model_assets.dart';
import 'kiwi_options.dart';
import 'kiwi_types.dart';

/// Native FFI-backed Kiwi analyzer implementation.
///
/// Import this library through `flutter_kiwi_nlp.dart`.
/// Native binding contract used by [KiwiAnalyzer].
///
/// The default implementation delegates to generated FFI bindings. Tests may
/// provide a fake implementation through [debugSetKiwiNativeBindingsFactoryForTest].
abstract interface class KiwiNativeBindings {
  Pointer<flutter_kiwi_ffi_handle_t> flutter_kiwi_ffi_init(
    Pointer<Char> modelPath,
    int numThreads,
    int buildOptions,
    int matchOptions,
  );

  int flutter_kiwi_ffi_close(Pointer<flutter_kiwi_ffi_handle_t> handle);

  Pointer<Char> flutter_kiwi_ffi_analyze_json(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Char> text,
    int topN,
    int matchOptions,
  );

  Pointer<Char> flutter_kiwi_ffi_analyze_json_batch(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Pointer<Char>> texts,
    int textCount,
    int topN,
    int matchOptions,
  );

  int flutter_kiwi_ffi_analyze_token_count(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Char> text,
    int topN,
    int matchOptions,
    Pointer<Int32> outTokenCount,
  );

  int flutter_kiwi_ffi_analyze_token_count_batch(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Pointer<Char>> texts,
    int textCount,
    int topN,
    int matchOptions,
    Pointer<Int32> outTokenCounts,
  );

  int flutter_kiwi_ffi_analyze_token_count_batch_runs(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Pointer<Char>> texts,
    int textCount,
    int runs,
    int topN,
    int matchOptions,
    Pointer<Int64> outTotalTokens,
  );

  int flutter_kiwi_ffi_add_user_word(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Char> word,
    Pointer<Char> tag,
    double score,
  );

  void flutter_kiwi_ffi_free_string(Pointer<Char> value);

  Pointer<Char> flutter_kiwi_ffi_last_error();

  Pointer<Char> flutter_kiwi_ffi_version();
}

/// Adapter that forwards calls to [FlutterKiwiFfiBindings].
class GeneratedKiwiNativeBindings implements KiwiNativeBindings {
  final FlutterKiwiFfiBindings _bindings;

  /// Creates an adapter backed by generated FFI symbols.
  GeneratedKiwiNativeBindings(this._bindings);

  @override
  Pointer<flutter_kiwi_ffi_handle_t> flutter_kiwi_ffi_init(
    Pointer<Char> modelPath,
    int numThreads,
    int buildOptions,
    int matchOptions,
  ) {
    return _bindings.flutter_kiwi_ffi_init(
      modelPath,
      numThreads,
      buildOptions,
      matchOptions,
    );
  }

  @override
  Pointer<Char> flutter_kiwi_ffi_analyze_json_batch(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Pointer<Char>> texts,
    int textCount,
    int topN,
    int matchOptions,
  ) {
    return _bindings.flutter_kiwi_ffi_analyze_json_batch(
      handle,
      texts,
      textCount,
      topN,
      matchOptions,
    );
  }

  @override
  int flutter_kiwi_ffi_close(Pointer<flutter_kiwi_ffi_handle_t> handle) {
    return _bindings.flutter_kiwi_ffi_close(handle);
  }

  @override
  Pointer<Char> flutter_kiwi_ffi_analyze_json(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Char> text,
    int topN,
    int matchOptions,
  ) {
    return _bindings.flutter_kiwi_ffi_analyze_json(
      handle,
      text,
      topN,
      matchOptions,
    );
  }

  @override
  int flutter_kiwi_ffi_analyze_token_count(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Char> text,
    int topN,
    int matchOptions,
    Pointer<Int32> outTokenCount,
  ) {
    return _bindings.flutter_kiwi_ffi_analyze_token_count(
      handle,
      text,
      topN,
      matchOptions,
      outTokenCount,
    );
  }

  @override
  int flutter_kiwi_ffi_analyze_token_count_batch(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Pointer<Char>> texts,
    int textCount,
    int topN,
    int matchOptions,
    Pointer<Int32> outTokenCounts,
  ) {
    return _bindings.flutter_kiwi_ffi_analyze_token_count_batch(
      handle,
      texts,
      textCount,
      topN,
      matchOptions,
      outTokenCounts,
    );
  }

  @override
  int flutter_kiwi_ffi_analyze_token_count_batch_runs(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Pointer<Char>> texts,
    int textCount,
    int runs,
    int topN,
    int matchOptions,
    Pointer<Int64> outTotalTokens,
  ) {
    return _bindings.flutter_kiwi_ffi_analyze_token_count_batch_runs(
      handle,
      texts,
      textCount,
      runs,
      topN,
      matchOptions,
      outTotalTokens,
    );
  }

  @override
  int flutter_kiwi_ffi_add_user_word(
    Pointer<flutter_kiwi_ffi_handle_t> handle,
    Pointer<Char> word,
    Pointer<Char> tag,
    double score,
  ) {
    return _bindings.flutter_kiwi_ffi_add_user_word(handle, word, tag, score);
  }

  @override
  void flutter_kiwi_ffi_free_string(Pointer<Char> value) {
    _bindings.flutter_kiwi_ffi_free_string(value);
  }

  @override
  Pointer<Char> flutter_kiwi_ffi_last_error() {
    return _bindings.flutter_kiwi_ffi_last_error();
  }

  @override
  Pointer<Char> flutter_kiwi_ffi_version() {
    return _bindings.flutter_kiwi_ffi_version();
  }
}

KiwiNativeBindings _createDefaultKiwiNativeBindings() {
  final DynamicLibrary dynamicLibrary = _kiwiDynamicLibraryOpenerForTest();
  return GeneratedKiwiNativeBindings(FlutterKiwiFfiBindings(dynamicLibrary));
}

KiwiNativeBindings Function() _kiwiNativeBindingsFactory =
    _createDefaultKiwiNativeBindings;
String? _kiwiNativeArchiveUrlOverrideForTest;
String? _kiwiNativeArchiveSha256OverrideForTest;
HttpClient Function() _kiwiHttpClientFactory = HttpClient.new;
String? _lastOpenedNativeLibraryCandidateForTest;
List<String> Function() _kiwiNativeLibraryCandidatesProviderForTest =
    _nativeLibraryCandidatesForCurrentPlatform;
String? _kiwiDefaultAssetModelPathOverrideForTest;
List<String>? _kiwiAutoAssetModelPathsOverrideForTest;
Future<String?> Function({String? modelPath, String? assetModelPath})?
_kiwiResolveModelPathOverrideForTest;
Duration? _kiwiModelPreparationTimeoutOverrideForTest;
DynamicLibrary Function() _kiwiDynamicLibraryOpenerForTest =
    _openPluginDynamicLibrary;

/// Overrides native binding creation for tests.
void debugSetKiwiNativeBindingsFactoryForTest(
  KiwiNativeBindings Function()? factory,
) {
  _kiwiNativeBindingsFactory = factory ?? _createDefaultKiwiNativeBindings;
}

/// Overrides archive URL/checksum used by default model preparation in tests.
void debugSetKiwiNativeArchiveOverridesForTest({
  String? archiveUrl,
  String? archiveSha256,
}) {
  _kiwiNativeArchiveUrlOverrideForTest = archiveUrl;
  _kiwiNativeArchiveSha256OverrideForTest = archiveSha256;
}

/// Overrides [HttpClient] creation used by default model download in tests.
void debugSetKiwiNativeHttpClientFactoryForTest(
  HttpClient Function()? factory,
) {
  _kiwiHttpClientFactory = factory ?? HttpClient.new;
}

/// Overrides native library load candidates for tests.
void debugSetKiwiNativeLibraryCandidatesProviderForTest(
  List<String> Function()? provider,
) {
  _kiwiNativeLibraryCandidatesProviderForTest =
      provider ?? _nativeLibraryCandidatesForCurrentPlatform;
}

/// Overrides the compile-time default asset model path for tests.
void debugSetKiwiNativeDefaultAssetModelPathForTest(String? assetModelPath) {
  _kiwiDefaultAssetModelPathOverrideForTest = assetModelPath;
}

/// Overrides auto-detected model asset candidate paths for tests.
void debugSetKiwiNativeAutoAssetModelPathsForTest(List<String>? assetPaths) {
  _kiwiAutoAssetModelPathsOverrideForTest = assetPaths;
}

/// Overrides model path resolution logic for tests.
void debugSetKiwiNativeResolveModelPathForTest(
  Future<String?> Function({String? modelPath, String? assetModelPath})?
  resolver,
) {
  _kiwiResolveModelPathOverrideForTest = resolver;
}

/// Overrides default model preparation timeout for tests.
void debugSetKiwiNativeModelPreparationTimeoutForTest(Duration? timeout) {
  _kiwiModelPreparationTimeoutOverrideForTest = timeout;
}

/// Overrides native dynamic library open behavior for tests.
void debugSetKiwiNativeDynamicLibraryOpenerForTest(
  DynamicLibrary Function()? opener,
) {
  _kiwiDynamicLibraryOpenerForTest = opener ?? _openPluginDynamicLibrary;
}

/// Returns native dynamic library load candidates for the current platform.
List<String> debugKiwiNativeLibraryCandidatesForTest() {
  return _kiwiNativeLibraryCandidatesProviderForTest();
}

/// Returns the last candidate that successfully loaded in this isolate.
String? debugKiwiNativeLoadedLibraryCandidateForTest() {
  return _lastOpenedNativeLibraryCandidateForTest;
}

String _effectiveDefaultModelArchiveUrl() {
  return _kiwiNativeArchiveUrlOverrideForTest ?? _defaultModelArchiveUrl;
}

String _effectiveDefaultModelArchiveSha256() {
  return _kiwiNativeArchiveSha256OverrideForTest ?? _defaultModelArchiveSha256;
}

String _effectiveDefaultAssetModelPath() {
  return _kiwiDefaultAssetModelPathOverrideForTest ?? _defaultAssetModelPath;
}

List<String> _effectiveAutoAssetModelPaths() {
  return _kiwiAutoAssetModelPathsOverrideForTest ?? _autoAssetModelPaths;
}

DynamicLibrary _openPluginDynamicLibrary() {
  final List<String> candidates = _kiwiNativeLibraryCandidatesProviderForTest();
  if (candidates.isEmpty) {
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  final List<String> errors = <String>[];
  for (final String path in candidates) {
    try {
      final DynamicLibrary library = DynamicLibrary.open(path);
      _lastOpenedNativeLibraryCandidateForTest = path;
      return library;
    } catch (error) {
      errors.add('$path => $error');
    }
  }

  throw ArgumentError(
    'Failed to load Kiwi native bridge library. '
    'Tried: ${candidates.join(', ')}. '
    'Errors: ${errors.join(' | ')}',
  );
}

List<String> _nativeLibraryCandidatesForCurrentPlatform() {
  return <String>[
    if (Platform.isMacOS || Platform.isIOS) ...<String>[
      'flutter_kiwi_nlp.framework/flutter_kiwi_nlp',
      'flutter_kiwi_ffi.framework/flutter_kiwi_ffi',
    ],
    if (Platform.isAndroid || Platform.isLinux) ...<String>[
      'libflutter_kiwi_ffi.so',
      'libflutter_kiwi_nlp.so',
    ],
    if (Platform.isWindows) ...<String>[
      'flutter_kiwi_ffi.dll',
      'flutter_kiwi_nlp.dll',
    ],
  ];
}

const String _defaultAssetModelPath = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_ASSET_MODEL_PATH',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_ASSET_MODEL_PATH',
    defaultValue: '',
  ),
);
const String _defaultModelArchiveUrl = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_MODEL_ARCHIVE_URL',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_MODEL_ARCHIVE_URL',
    defaultValue:
        'https://github.com/bab2min/Kiwi/releases/download/v0.22.2/kiwi_model_v0.22.2_base.tgz',
  ),
);
const String _defaultModelCacheKey = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_MODEL_CACHE_KEY',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_MODEL_CACHE_KEY',
    defaultValue: 'v0.22.2_base',
  ),
);
const String _defaultModelArchiveSha256 = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_MODEL_ARCHIVE_SHA256',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_MODEL_ARCHIVE_SHA256',
    defaultValue:
        'aa11a6e5b06c7db43e9b07148620f5fb7838a30172dacb40f75202333110f2d1',
  ),
);
const List<String> _autoAssetModelPaths = <String>[
  'assets/kiwi-models/cong/base',
  'packages/flutter_kiwi_ffi_models/assets/kiwi-models/cong/base',
  'packages/flutter_kiwi_nlp/assets/kiwi-models/cong/base',
  'packages/flutter_kiwi_ffi/assets/kiwi-models/cong/base',
];

Future<String>? _downloadedModelPathFuture;

/// Native (FFI) Kiwi analyzer for Korean morphological analysis.
class KiwiAnalyzer {
  final Pointer<flutter_kiwi_ffi_handle> _handle;
  final KiwiNativeBindings _bindings;
  bool _closed = false;

  KiwiAnalyzer._(this._handle, this._bindings);

  /// Creates a native analyzer instance.
  ///
  /// The [modelPath] points to a local Kiwi model directory.
  /// The [assetModelPath] points to bundled Flutter assets and is extracted to
  /// a temporary directory.
  /// The [numThreads] value configures Kiwi worker threads. Use `-1` for the
  /// backend default.
  /// The [buildOptions] value combines [KiwiBuildOption] bit flags.
  /// The [matchOptions] value combines [KiwiMatchOption] bit flags used as the
  /// analyzer default.
  ///
  /// If both paths are omitted, this method tries environment variables,
  /// packaged default assets, and finally the default model archive download.
  ///
  /// Throws a [KiwiException] if the model cannot be resolved or the native
  /// backend initialization fails.
  static Future<KiwiAnalyzer> create({
    String? modelPath,
    String? assetModelPath,
    int numThreads = -1,
    int buildOptions = KiwiBuildOption.defaultOption,
    int matchOptions = KiwiMatchOption.allWithNormalizing,
  }) async {
    final Future<String?> Function({String? modelPath, String? assetModelPath})
    resolveModelPath =
        _kiwiResolveModelPathOverrideForTest ?? _resolveModelPath;
    final String? resolvedModelPath = await resolveModelPath(
      modelPath: modelPath,
      assetModelPath: assetModelPath,
    );
    if (resolvedModelPath == null || resolvedModelPath.isEmpty) {
      throw KiwiException(
        'Kiwi model not found. '
        'Pass modelPath/assetModelPath, set FLUTTER_KIWI_NLP_MODEL_PATH '
        '(legacy: FLUTTER_KIWI_FFI_MODEL_PATH), '
        'or allow default model download.',
      );
    }
    final Pointer<Utf8> modelPathPtr = resolvedModelPath.toNativeUtf8(
      allocator: malloc,
    );
    int resolvedBuildOptions = buildOptions;
    if ((resolvedBuildOptions & 0x0F00) == 0) {
      resolvedBuildOptions |= KiwiBuildOption.modelTypeCong;
    }
    final KiwiNativeBindings bindings = _kiwiNativeBindingsFactory();
    try {
      final Pointer<flutter_kiwi_ffi_handle> handle = bindings
          .flutter_kiwi_ffi_init(
            modelPathPtr.cast(),
            numThreads,
            resolvedBuildOptions,
            matchOptions,
          );
      if (handle == nullptr) {
        throw KiwiException(_readLastError(bindings));
      }
      return KiwiAnalyzer._(handle, bindings);
    } finally {
      malloc.free(modelPathPtr);
    }
  }

  /// The backend version string reported by the native runtime.
  String get nativeVersion {
    final Pointer<Char> ptr = _bindings.flutter_kiwi_ffi_version();
    if (ptr == nullptr) {
      return 'unknown';
    }
    return ptr.cast<Utf8>().toDartString();
  }

  /// Analyzes [text] and returns candidate tokenization results.
  ///
  /// The [options] control candidate count and matching behavior.
  ///
  /// Throws a [KiwiException] if analysis fails or if this analyzer is closed.
  Future<KiwiAnalyzeResult> analyze(
    String text, {
    KiwiAnalyzeOptions options = const KiwiAnalyzeOptions(),
  }) async {
    _assertOpen();
    final Pointer<Utf8> textPtr = text.toNativeUtf8(allocator: malloc);
    try {
      final Pointer<Char> raw = _bindings.flutter_kiwi_ffi_analyze_json(
        _handle,
        textPtr.cast(),
        options.topN,
        options.matchOptions,
      );
      if (raw == nullptr) {
        throw KiwiException(_readLastError(_bindings));
      }
      try {
        final String jsonText = raw.cast<Utf8>().toDartString();
        final dynamic decoded = jsonDecode(jsonText);
        if (decoded is! Map<String, dynamic>) {
          throw const KiwiException('Unexpected analyze payload.');
        }
        return KiwiAnalyzeResult.fromJson(decoded);
      } finally {
        _bindings.flutter_kiwi_ffi_free_string(raw);
      }
    } finally {
      malloc.free(textPtr);
    }
  }

  /// Analyzes [texts] and returns results in input order.
  ///
  /// This batches native calls to reduce FFI boundary and JSON decode overhead.
  ///
  /// Throws a [KiwiException] if analysis fails or if this analyzer is closed.
  Future<List<KiwiAnalyzeResult>> analyzeBatch(
    List<String> texts, {
    KiwiAnalyzeOptions options = const KiwiAnalyzeOptions(),
  }) async {
    _assertOpen();
    if (texts.isEmpty) {
      return const <KiwiAnalyzeResult>[];
    }

    final int textCount = texts.length;
    final Pointer<Pointer<Char>> textPointers = malloc<Pointer<Char>>(
      textCount,
    );
    final List<Pointer<Utf8>> allocated = <Pointer<Utf8>>[];

    try {
      for (int index = 0; index < textCount; index += 1) {
        final Pointer<Utf8> textPtr = texts[index].toNativeUtf8(
          allocator: malloc,
        );
        allocated.add(textPtr);
        textPointers[index] = textPtr.cast<Char>();
      }

      final Pointer<Char> raw = _bindings.flutter_kiwi_ffi_analyze_json_batch(
        _handle,
        textPointers,
        textCount,
        options.topN,
        options.matchOptions,
      );
      if (raw == nullptr) {
        throw KiwiException(_readLastError(_bindings));
      }

      try {
        final String jsonText = raw.cast<Utf8>().toDartString();
        final dynamic decoded = jsonDecode(jsonText);
        if (decoded is! Map<String, dynamic>) {
          throw const KiwiException('Unexpected analyze batch payload.');
        }
        final dynamic rawResults = decoded['results'];
        if (rawResults is! List<dynamic>) {
          throw const KiwiException('Unexpected analyze batch payload.');
        }

        final List<KiwiAnalyzeResult> results = rawResults
            .map((dynamic item) {
              if (item is! Map<String, dynamic>) {
                throw const KiwiException('Unexpected analyze batch payload.');
              }
              return KiwiAnalyzeResult.fromJson(item);
            })
            .toList(growable: false);

        if (results.length != textCount) {
          throw const KiwiException('Unexpected analyze batch payload.');
        }
        return results;
      } finally {
        _bindings.flutter_kiwi_ffi_free_string(raw);
      }
    } finally {
      for (final Pointer<Utf8> pointer in allocated) {
        malloc.free(pointer);
      }
      malloc.free(textPointers);
    }
  }

  /// Analyzes [text] and returns the first-candidate token count.
  ///
  /// This avoids JSON materialization and is intended for performance
  /// benchmarking of tokenizer throughput.
  ///
  /// Throws a [KiwiException] if analysis fails or if this analyzer is closed.
  Future<int> analyzeTokenCount(
    String text, {
    KiwiAnalyzeOptions options = const KiwiAnalyzeOptions(),
  }) async {
    _assertOpen();
    final Pointer<Utf8> textPtr = text.toNativeUtf8(allocator: malloc);
    final Pointer<Int32> outTokenCount = malloc<Int32>(1);
    try {
      final int status = _bindings.flutter_kiwi_ffi_analyze_token_count(
        _handle,
        textPtr.cast(),
        options.topN,
        options.matchOptions,
        outTokenCount,
      );
      if (status != 0) {
        throw KiwiException(_readLastError(_bindings));
      }
      return outTokenCount.value;
    } finally {
      malloc.free(textPtr);
      malloc.free(outTokenCount);
    }
  }

  /// Analyzes [texts] and returns first-candidate token counts in order.
  ///
  /// This batches native calls to reduce FFI boundary overhead.
  ///
  /// Throws a [KiwiException] if analysis fails or if this analyzer is closed.
  Future<List<int>> analyzeTokenCountBatch(
    List<String> texts, {
    KiwiAnalyzeOptions options = const KiwiAnalyzeOptions(),
  }) async {
    _assertOpen();
    if (texts.isEmpty) {
      return const <int>[];
    }

    final int textCount = texts.length;
    final Pointer<Pointer<Char>> textPointers = malloc<Pointer<Char>>(
      textCount,
    );
    final Pointer<Int32> outTokenCounts = malloc<Int32>(textCount);
    final List<Pointer<Utf8>> allocated = <Pointer<Utf8>>[];

    try {
      for (int index = 0; index < textCount; index += 1) {
        final Pointer<Utf8> textPtr = texts[index].toNativeUtf8(
          allocator: malloc,
        );
        allocated.add(textPtr);
        textPointers[index] = textPtr.cast<Char>();
      }

      final int status = _bindings.flutter_kiwi_ffi_analyze_token_count_batch(
        _handle,
        textPointers,
        textCount,
        options.topN,
        options.matchOptions,
        outTokenCounts,
      );
      if (status != 0) {
        throw KiwiException(_readLastError(_bindings));
      }

      return List<int>.generate(
        textCount,
        (int index) => outTokenCounts[index],
        growable: false,
      );
    } finally {
      for (final Pointer<Utf8> pointer in allocated) {
        malloc.free(pointer);
      }
      malloc.free(textPointers);
      malloc.free(outTokenCounts);
    }
  }

  /// Repeats batch analysis [runs] times and returns summed token counts.
  ///
  /// This is optimized for throughput benchmarks by reusing encoded inputs.
  ///
  /// Throws a [KiwiException] if analysis fails or if this analyzer is closed.
  Future<int> analyzeTokenCountBatchRepeated(
    List<String> texts, {
    int runs = 1,
    KiwiAnalyzeOptions options = const KiwiAnalyzeOptions(),
  }) async {
    _assertOpen();
    if (runs < 0) {
      throw const KiwiException('runs must be >= 0.');
    }
    if (texts.isEmpty || runs == 0) {
      return 0;
    }

    final int textCount = texts.length;
    final Pointer<Pointer<Char>> textPointers = malloc<Pointer<Char>>(
      textCount,
    );
    final Pointer<Int64> outTotalTokens = malloc<Int64>(1);
    final List<Pointer<Utf8>> allocated = <Pointer<Utf8>>[];

    try {
      for (int index = 0; index < textCount; index += 1) {
        final Pointer<Utf8> textPtr = texts[index].toNativeUtf8(
          allocator: malloc,
        );
        allocated.add(textPtr);
        textPointers[index] = textPtr.cast<Char>();
      }

      final int status = _bindings
          .flutter_kiwi_ffi_analyze_token_count_batch_runs(
            _handle,
            textPointers,
            textCount,
            runs,
            options.topN,
            options.matchOptions,
            outTotalTokens,
          );
      if (status != 0) {
        throw KiwiException(_readLastError(_bindings));
      }
      return outTotalTokens.value;
    } finally {
      for (final Pointer<Utf8> pointer in allocated) {
        malloc.free(pointer);
      }
      malloc.free(textPointers);
      malloc.free(outTotalTokens);
    }
  }

  /// Adds a user dictionary entry to this analyzer instance.
  ///
  /// The [word] is the surface form to register.
  /// The [tag] is a POS tag string and [score] adjusts dictionary confidence.
  ///
  /// Throws a [KiwiException] if registration fails or if this analyzer is
  /// closed.
  Future<void> addUserWord(
    String word, {
    String tag = 'NNP',
    double score = 0.0,
  }) async {
    _assertOpen();
    final Pointer<Utf8> wordPtr = word.toNativeUtf8(allocator: malloc);
    final Pointer<Utf8> tagPtr = tag.toNativeUtf8(allocator: malloc);
    try {
      final int status = _bindings.flutter_kiwi_ffi_add_user_word(
        _handle,
        wordPtr.cast(),
        tagPtr.cast(),
        score,
      );
      if (status != 0) {
        throw KiwiException(_readLastError(_bindings));
      }
    } finally {
      malloc.free(wordPtr);
      malloc.free(tagPtr);
    }
  }

  /// Releases native resources held by this analyzer.
  ///
  /// After calling this method, subsequent API calls throw a [KiwiException].
  Future<void> close() async {
    if (_closed) return;
    final int status = _bindings.flutter_kiwi_ffi_close(_handle);
    _closed = true;
    if (status != 0) {
      throw KiwiException(_readLastError(_bindings));
    }
  }

  void _assertOpen() {
    if (_closed) {
      throw const KiwiException(
        'KiwiAnalyzer is already closed. Create a new instance.',
      );
    }
  }

  static String _readLastError(KiwiNativeBindings bindings) {
    final Pointer<Char> errorPtr = bindings.flutter_kiwi_ffi_last_error();
    if (errorPtr == nullptr) {
      return 'Unknown kiwi native error.';
    }
    return errorPtr.cast<Utf8>().toDartString();
  }

  static Future<String?> _resolveModelPath({
    String? modelPath,
    String? assetModelPath,
  }) async {
    final String path = (modelPath ?? '').trim();
    if (path.isNotEmpty) {
      return path;
    }

    final String assetBase = (assetModelPath ?? '').trim();
    if (assetBase.isNotEmpty) {
      return _extractModelAssets(assetBase);
    }

    final String envModelPath =
        (Platform.environment['FLUTTER_KIWI_NLP_MODEL_PATH'] ??
                Platform.environment['FLUTTER_KIWI_FFI_MODEL_PATH'] ??
                '')
            .trim();
    if (envModelPath.isNotEmpty) {
      return envModelPath;
    }

    final String definedAssetBase = _effectiveDefaultAssetModelPath().trim();
    if (definedAssetBase.isNotEmpty) {
      return _extractModelAssets(definedAssetBase);
    }

    for (final String candidate in _effectiveAutoAssetModelPaths()) {
      if (await _assetModelExists(candidate)) {
        return _extractModelAssets(candidate);
      }
    }

    return _ensureDownloadedModel();
  }

  static Future<bool> _assetModelExists(String assetBase) async {
    WidgetsFlutterBinding.ensureInitialized();
    final String normalized = assetBase.endsWith('/')
        ? assetBase.substring(0, assetBase.length - 1)
        : assetBase;
    try {
      await rootBundle.load('$normalized/cong.mdl');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> _extractModelAssets(String assetBase) async {
    WidgetsFlutterBinding.ensureInitialized();
    final String normalized = assetBase.endsWith('/')
        ? assetBase.substring(0, assetBase.length - 1)
        : assetBase;
    final String cacheKey = base64Url
        .encode(utf8.encode(normalized))
        .replaceAll('=', '');
    final Directory outputDir = Directory(
      '${Directory.systemTemp.path}/flutter_kiwi_nlp_model/$cacheKey',
    );
    await outputDir.create(recursive: true);

    try {
      for (final String fileName in kiwiModelFileNames) {
        final File outputFile = File('${outputDir.path}/$fileName');
        if (outputFile.existsSync() && outputFile.lengthSync() > 0) {
          continue;
        }
        final ByteData asset = await rootBundle.load('$normalized/$fileName');
        await outputFile.writeAsBytes(
          asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
          flush: true,
        );
      }
    } catch (error) {
      throw KiwiException(
        'Failed to load Kiwi model assets from "$normalized". '
        'Declare assets and include required files '
        '(${kiwiModelFileNames.join(', ')}). '
        'Original error: $error',
      );
    }

    return outputDir.path;
  }

  static Future<String> _ensureDownloadedModel() {
    final Future<String>? cached = _downloadedModelPathFuture;
    if (cached != null) {
      return cached;
    }
    final Future<String> next = _downloadDefaultModelIfNeeded();
    _downloadedModelPathFuture = next;
    return next.whenComplete(() {
      if (identical(_downloadedModelPathFuture, next)) {
        _downloadedModelPathFuture = null;
      }
    });
  }

  static Future<String> _downloadDefaultModelIfNeeded() {
    final Duration timeout =
        _kiwiModelPreparationTimeoutOverrideForTest ??
        const Duration(minutes: 3);
    return _downloadDefaultModelIfNeededImpl().timeout(
      timeout,
      onTimeout: () {
        throw const KiwiException(
          'Timed out while preparing default Kiwi model (3 minutes).',
        );
      },
    );
  }

  static Future<String> _downloadDefaultModelIfNeededImpl() async {
    final String cacheRootPath =
        '${Directory.systemTemp.path}/flutter_kiwi_nlp_model_cache/$_defaultModelCacheKey';
    final Directory cacheRoot = Directory(cacheRootPath);
    final Directory modelDir = Directory('$cacheRootPath/models/cong/base');
    if (_hasModelFiles(modelDir.path)) {
      return modelDir.path;
    }

    await cacheRoot.create(recursive: true);
    final File archiveFile = File('$cacheRootPath/model.tgz');
    await _ensureArchiveReady(archiveFile);

    if (!_hasModelFiles(modelDir.path)) {
      try {
        await _extractModelArchive(
          archiveFile: archiveFile,
          outputRoot: cacheRoot,
        );
      } catch (_) {
        if (archiveFile.existsSync()) {
          await archiveFile.delete();
        }
        await _ensureArchiveReady(archiveFile);
        await _extractModelArchive(
          archiveFile: archiveFile,
          outputRoot: cacheRoot,
        );
      }
    }

    if (!_hasModelFiles(modelDir.path)) {
      throw KiwiException(
        'Downloaded model archive but required files are missing in ${modelDir.path}.',
      );
    }
    return modelDir.path;
  }

  static bool _hasModelFiles(String modelDirPath) {
    for (final String fileName in kiwiModelFileNames) {
      final File file = File('$modelDirPath/$fileName');
      if (!file.existsSync()) {
        return false;
      }
      final int minBytes = kiwiMinModelFileBytes[fileName] ?? 1;
      if (file.lengthSync() < minBytes) {
        return false;
      }
    }
    return true;
  }

  static Future<void> _ensureArchiveReady(File archiveFile) async {
    if (!archiveFile.existsSync() || archiveFile.lengthSync() == 0) {
      await _downloadFile(
        uri: Uri.parse(_effectiveDefaultModelArchiveUrl()),
        outputFile: archiveFile,
      );
    }
    try {
      await _verifyArchiveChecksum(archiveFile);
    } catch (_) {
      if (archiveFile.existsSync()) {
        await archiveFile.delete();
      }
      await _downloadFile(
        uri: Uri.parse(_effectiveDefaultModelArchiveUrl()),
        outputFile: archiveFile,
      );
      await _verifyArchiveChecksum(archiveFile);
    }
  }

  static Future<void> _verifyArchiveChecksum(File archiveFile) async {
    final String expected = _effectiveDefaultModelArchiveSha256()
        .trim()
        .toLowerCase();
    if (expected.isEmpty) {
      return;
    }
    final crypto.Digest digest = await crypto.sha256
        .bind(archiveFile.openRead())
        .first;
    final String actual = digest.toString().toLowerCase();
    if (actual != expected) {
      throw KiwiException(
        'Default model checksum mismatch. expected=$expected actual=$actual',
      );
    }
  }

  static Future<void> _downloadFile({
    required Uri uri,
    required File outputFile,
  }) async {
    final HttpClient client = _kiwiHttpClientFactory();
    client.connectionTimeout = const Duration(seconds: 20);
    try {
      final HttpClientRequest request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 20));
      final HttpClientResponse response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw KiwiException(
          'Failed to download default model (${response.statusCode}) from $uri',
        );
      }

      final File partial = File('${outputFile.path}.part');
      if (partial.existsSync()) {
        await partial.delete();
      }
      await partial.create(recursive: true);
      final IOSink sink = partial.openWrite();
      await for (final List<int> chunk in response.timeout(
        const Duration(seconds: 30),
        onTimeout: (EventSink<List<int>> sink) {
          throw TimeoutException('Download stalled for 30 seconds.');
        },
      )) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();

      if (outputFile.existsSync()) {
        await outputFile.delete();
      }
      await partial.rename(outputFile.path);
    } on KiwiException {
      rethrow;
    } catch (error) {
      throw KiwiException(
        'Failed to download default model from $uri: $error. '
        'If network is restricted, pass modelPath/assetModelPath '
        'or set FLUTTER_KIWI_NLP_MODEL_PATH '
        '(legacy: FLUTTER_KIWI_FFI_MODEL_PATH).',
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> _extractModelArchive({
    required File archiveFile,
    required Directory outputRoot,
  }) async {
    try {
      final String archivePath = archiveFile.path;
      final String outputPath = outputRoot.path;
      await Isolate.run(() => extractFileToDisk(archivePath, outputPath));
    } catch (error) {
      throw KiwiException(
        'Failed to extract default model archive "${archiveFile.path}": $error',
      );
    }
  }
}
