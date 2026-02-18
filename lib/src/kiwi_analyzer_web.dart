import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'kiwi_exception.dart';
import 'kiwi_model_assets.dart';
import 'kiwi_options.dart';
import 'kiwi_types.dart';

const String _defaultModuleUrl = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_WEB_MODULE_URL',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_WEB_MODULE_URL',
    defaultValue: 'https://cdn.jsdelivr.net/npm/kiwi-nlp@0.22.1/dist/index.js',
  ),
);
const String _defaultWasmUrl = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_WEB_WASM_URL',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_WEB_WASM_URL',
    defaultValue:
        'https://cdn.jsdelivr.net/npm/kiwi-nlp@0.22.1/dist/kiwi-wasm.wasm',
  ),
);
const String _defaultModelBaseUrl = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_WEB_MODEL_BASE_URL',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_WEB_MODEL_BASE_URL',
    defaultValue: '',
  ),
);
const String _defaultModelGithubRepo = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_WEB_MODEL_GITHUB_REPO',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_WEB_MODEL_GITHUB_REPO',
    defaultValue: 'bab2min/Kiwi',
  ),
);
const String _defaultModelArchiveVersion = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_WEB_MODEL_ARCHIVE_VERSION',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_WEB_MODEL_ARCHIVE_VERSION',
    defaultValue: 'v0.22.2',
  ),
);
const String _defaultModelArchiveName = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_WEB_MODEL_ARCHIVE_NAME',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_WEB_MODEL_ARCHIVE_NAME',
    defaultValue: 'kiwi_model_v0.22.2_base.tgz',
  ),
);
const String _defaultModelArchiveUrl = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_WEB_MODEL_ARCHIVE_URL',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_WEB_MODEL_ARCHIVE_URL',
    defaultValue: '',
  ),
);
const String _defaultModelArchiveSha256 = String.fromEnvironment(
  'FLUTTER_KIWI_NLP_WEB_MODEL_ARCHIVE_SHA256',
  defaultValue: String.fromEnvironment(
    'FLUTTER_KIWI_FFI_WEB_MODEL_ARCHIVE_SHA256',
    defaultValue: '',
  ),
);
const String _defaultAssetModelBaseUrl =
    'assets/packages/flutter_kiwi_nlp/assets/kiwi-models/cong/base';

Future<JSObject>? _moduleFuture;
Future<Map<String, Uint8List>>? _webModelFilesFuture;
String? _lastCreateModelBaseForTest;
String? _lastCreateUrlModelBaseForTest;
String? _lastCreateModuleUrlForTest;
String? _lastCreateWasmUrlForTest;

/// Returns the module URL resolved for this build.
String debugKiwiWebModuleUrlForTest() => _defaultModuleUrl;

/// Returns the WASM URL resolved for this build.
String debugKiwiWebWasmUrlForTest() => _defaultWasmUrl;

/// Returns the default packaged model base URL used on web.
String debugKiwiWebDefaultAssetModelBaseUrlForTest() {
  return _defaultAssetModelBaseUrl;
}

/// Resolves the model URL base with the same rules used by create.
String debugKiwiWebResolveModelUrlBaseForTest({
  String? modelPath,
  String? assetModelPath,
}) {
  final String modelBase = normalizeKiwiModelBasePath(
    modelPath ?? assetModelPath ?? _defaultModelBaseUrl,
  );
  return normalizeKiwiModelUrlBase(
    modelBase.isNotEmpty ? modelBase : _defaultAssetModelBaseUrl,
  );
}

/// Returns the last model base resolved by [KiwiAnalyzer.create].
String? debugKiwiWebLastCreateModelBaseForTest() {
  return _lastCreateModelBaseForTest;
}

/// Returns the last normalized model URL base resolved by create.
String? debugKiwiWebLastCreateUrlModelBaseForTest() {
  return _lastCreateUrlModelBaseForTest;
}

/// Returns the last module URL used by [KiwiAnalyzer.create].
String? debugKiwiWebLastCreateModuleUrlForTest() {
  return _lastCreateModuleUrlForTest;
}

/// Returns the last WASM URL used by [KiwiAnalyzer.create].
String? debugKiwiWebLastCreateWasmUrlForTest() {
  return _lastCreateWasmUrlForTest;
}

/// Web (WASM) Kiwi analyzer for Korean morphological analysis.
class KiwiAnalyzer {
  final JSObject _builder;
  JSObject? _kiwi;
  JSObject? _api;
  int? _kiwiId;
  final Map<String, Object?> _baseBuildArgs;
  final List<Map<String, Object?>> _userWords = <Map<String, Object?>>[];
  final String _version;
  bool _closed = false;

  KiwiAnalyzer._(
    this._builder,
    this._kiwi,
    this._api,
    this._kiwiId,
    this._baseBuildArgs,
    this._version,
  );

  /// Creates a web analyzer instance.
  ///
  /// The [modelPath] or [assetModelPath] should point to a model base URL.
  /// If omitted, this method uses compile-time defaults and package assets.
  /// The [buildOptions] value uses [KiwiBuildOption] flags supported by the
  /// web backend.
  /// The [numThreads] and [matchOptions] values are accepted for API parity
  /// with native platforms but are not applied on web create.
  ///
  /// Throws a [KiwiException] if the module or model cannot be loaded.
  static Future<KiwiAnalyzer> create({
    String? modelPath,
    String? assetModelPath,
    int numThreads = -1,
    int buildOptions = KiwiBuildOption.defaultOption,
    int matchOptions = KiwiMatchOption.allWithNormalizing,
  }) async {
    final String modelBase = normalizeKiwiModelBasePath(
      modelPath ?? assetModelPath ?? _defaultModelBaseUrl,
    );
    final String urlModelBase = normalizeKiwiModelUrlBase(
      modelBase.isNotEmpty ? modelBase : _defaultAssetModelBaseUrl,
    );
    _lastCreateModelBaseForTest = modelBase;
    _lastCreateUrlModelBaseForTest = urlModelBase;
    _lastCreateModuleUrlForTest = _defaultModuleUrl;
    _lastCreateWasmUrlForTest = _defaultWasmUrl;
    _webLog('create modelBase="$modelBase" urlModelBase="$urlModelBase"');
    Map<String, Object?> buildModelFiles = buildKiwiModelFiles(urlModelBase);

    final JSObject kiwiModule = await _loadKiwiModule();
    final JSAny? kiwiBuilderType = kiwiModule['KiwiBuilder'];
    if (kiwiBuilderType == null) {
      throw const KiwiException(
        'Failed to load kiwi-nlp module. KiwiBuilder is missing.',
      );
    }
    final JSObject kiwiBuilderTypeObject = kiwiBuilderType as JSObject;

    final JSAny? builderAny;
    try {
      builderAny = await _resolveJsFutureLike(
        kiwiBuilderTypeObject.callMethodVarArgs<JSAny?>('create'.toJS, <JSAny?>[
          _defaultWasmUrl.toJS,
        ]),
        context: 'KiwiBuilder.create',
      );
    } catch (error) {
      throw KiwiException('Failed to create KiwiBuilder on web: $error');
    }
    if (builderAny == null) {
      throw const KiwiException('Failed to create KiwiBuilder on web.');
    }
    final JSObject builder = builderAny as JSObject;

    final JSAny? versionAny = builder.callMethod<JSAny?>('version'.toJS);
    final String version = versionAny != null && versionAny.isA<JSString>()
        ? (versionAny as JSString).toDart
        : 'unknown';

    final Map<String, Object?> buildArgs = <String, Object?>{
      'modelFiles': buildModelFiles,
      'integrateAllomorph':
          (buildOptions & KiwiBuildOption.integrateAllomorph) != 0,
      'loadDefaultDict': (buildOptions & KiwiBuildOption.loadDefaultDict) != 0,
      'loadTypoDict': (buildOptions & KiwiBuildOption.loadTypoDict) != 0,
      'loadMultiDict': (buildOptions & KiwiBuildOption.loadMultiDict) != 0,
      'modelType': 'cong',
      'typos': 'none',
    };

    _BuiltKiwi built;
    try {
      built = await _buildKiwi(builder, buildArgs);
    } on KiwiException catch (firstError) {
      _webLog('initial build failed: ${firstError.message}');
      if (modelBase.isNotEmpty && !shouldTryKiwiArchiveFallback(modelBase)) {
        rethrow;
      }
      // Fallback: if URL-based model loading fails, try in-memory archive load.
      buildModelFiles = _asObjectMap(await _ensureWebModelFiles());
      _webLog('retrying build with downloaded model bytes');
      buildArgs['modelFiles'] = buildModelFiles;
      try {
        built = await _buildKiwi(builder, buildArgs);
      } on KiwiException catch (secondError) {
        throw KiwiException(
          'Failed to build Kiwi web backend with default asset URL ($urlModelBase): '
          '${firstError.message}. Fallback with downloaded archive also failed: '
          '${secondError.message}',
        );
      }
    }

    // Keep API parity. Both args are intentionally accepted for web.
    if (numThreads != -1 ||
        matchOptions != KiwiMatchOption.allWithNormalizing) {
      // no-op
    }

    return KiwiAnalyzer._(
      builder,
      built.kiwi,
      built.api,
      built.kiwiId,
      buildArgs,
      version,
    );
  }

  /// The backend version string reported by the web runtime.
  String get nativeVersion => 'web/wasm $_version';

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
    final int topN = options.topN > 0 ? options.topN : 1;
    final JSAny? raw = _kiwi != null
        ? _kiwi!.callMethodVarArgs<JSAny?>('analyzeTopN'.toJS, <JSAny?>[
            text.toJS,
            topN.toJS,
            options.matchOptions.toJS,
          ])
        : _callApiCmd('analyzeTopN', <Object?>[
            text,
            topN,
            options.matchOptions,
          ]);
    if (raw == null) {
      throw const KiwiException('Analyze returned null on web backend.');
    }

    final Object? dartified = raw.dartify();
    if (dartified is! List<dynamic>) {
      throw const KiwiException('Unexpected analyze payload from web backend.');
    }

    final List<KiwiCandidate> candidates = dartified
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> candidateJson) {
          final double score =
              (candidateJson['score'] as num?)?.toDouble() ?? 0.0;
          final List<dynamic> tokenList =
              candidateJson['tokens'] as List<dynamic>? ?? const <dynamic>[];
          final List<KiwiToken> tokens = tokenList
              .whereType<Map<dynamic, dynamic>>()
              .map((Map<dynamic, dynamic> tokenJson) {
                return KiwiToken(
                  form: tokenJson['str'] as String? ?? '',
                  tag: tokenJson['tag'] as String? ?? 'UNK',
                  start: (tokenJson['position'] as num?)?.toInt() ?? 0,
                  length: (tokenJson['length'] as num?)?.toInt() ?? 0,
                  wordPosition:
                      (tokenJson['wordPosition'] as num?)?.toInt() ?? 0,
                  sentPosition:
                      (tokenJson['sentPosition'] as num?)?.toInt() ?? 0,
                  score: (tokenJson['score'] as num?)?.toDouble() ?? 0.0,
                  typoCost: (tokenJson['typoCost'] as num?)?.toDouble() ?? 0.0,
                );
              })
              .toList(growable: false);
          return KiwiCandidate(probability: score, tokens: tokens);
        })
        .toList(growable: false);

    return KiwiAnalyzeResult(candidates: candidates);
  }

  /// Analyzes [text] and returns the first-candidate token count.
  ///
  /// This keeps API parity with native backends. On web, it delegates to
  /// [analyze] and counts tokens from the first candidate.
  ///
  /// Throws a [KiwiException] if analysis fails or if this analyzer is closed.
  Future<int> analyzeTokenCount(
    String text, {
    KiwiAnalyzeOptions options = const KiwiAnalyzeOptions(),
  }) async {
    final KiwiAnalyzeResult result = await analyze(text, options: options);
    if (result.candidates.isEmpty) {
      return 0;
    }
    return result.candidates.first.tokens.length;
  }

  /// Adds a user dictionary entry to this analyzer instance.
  ///
  /// The [word] is the surface form to register.
  /// The [tag] is a POS tag string and [score] adjusts dictionary confidence.
  ///
  /// Throws a [KiwiException] if this analyzer is closed or [word] is empty.
  Future<void> addUserWord(
    String word, {
    String tag = 'NNP',
    double score = 0.0,
  }) async {
    _assertOpen();
    if (word.trim().isEmpty) {
      throw const KiwiException('word must not be empty.');
    }

    _userWords.add(<String, Object?>{'word': word, 'tag': tag, 'score': score});

    final Map<String, Object?> nextArgs = Map<String, Object?>.from(
      _baseBuildArgs,
    );
    nextArgs['userWords'] = List<Map<String, Object?>>.from(_userWords);
    final _BuiltKiwi rebuilt = await _buildKiwi(_builder, nextArgs);
    _kiwi = rebuilt.kiwi;
    _api = rebuilt.api;
    _kiwiId = rebuilt.kiwiId;
  }

  /// Releases web-side state for this analyzer.
  ///
  /// After calling this method, subsequent API calls throw a [KiwiException].
  Future<void> close() async {
    _closed = true;
    _kiwi = null;
    _api = null;
    _kiwiId = null;
  }

  void _assertOpen() {
    final bool hasNativeObject = _kiwi != null;
    final bool hasApiBridge = _api != null && _kiwiId != null;
    if (_closed || (!hasNativeObject && !hasApiBridge)) {
      throw const KiwiException(
        'KiwiAnalyzer is already closed. Create a new instance.',
      );
    }
  }

  JSAny? _callApiCmd(String method, List<Object?> args) {
    final JSObject? api = _api;
    final int? kiwiId = _kiwiId;
    if (api == null || kiwiId == null) {
      throw const KiwiException('Web API backend is not initialized.');
    }
    return api.callMethodVarArgs<JSAny?>('cmd'.toJS, <JSAny?>[
      <String, Object?>{'method': method, 'id': kiwiId, 'args': args}.jsify(),
    ]);
  }
}

Future<_BuiltKiwi> _buildKiwi(
  JSObject builder,
  Map<String, Object?> buildArgs,
) async {
  try {
    _webLog(
      'build start (modelFilesType=${buildArgs['modelFiles']?.runtimeType})',
    );
    final JSObject? api = _extractBuilderApi(builder);
    if (api != null) {
      final _BuiltKiwi viaApi = await _buildKiwiViaApi(api, buildArgs);
      _webLog('build succeeded (api-bridge)');
      return viaApi;
    }

    final JSAny? kiwiAny = await _resolveJsFutureLike(
      builder.callMethodVarArgs<JSAny?>('build'.toJS, <JSAny?>[
        buildArgs.jsify(),
      ]),
      context: 'KiwiBuilder.build',
    );
    if (kiwiAny == null) {
      throw const KiwiException('Web build returned null Kiwi instance.');
    }
    _webLog('build succeeded');
    return _BuiltKiwi(kiwi: kiwiAny as JSObject);
  } catch (error) {
    _webLog('build failed: $error');
    throw KiwiException('Failed to build Kiwi web backend: $error');
  }
}

Future<_BuiltKiwi> _buildKiwiViaApi(
  JSObject api,
  Map<String, Object?> buildArgs,
) async {
  final Object? modelFiles = buildArgs['modelFiles'];
  if (modelFiles is! Map<String, Object?>) {
    throw const KiwiException('Invalid modelFiles payload for web API bridge.');
  }

  final JSAny? loadResultAny = await _resolveJsFutureLike(
    api.callMethodVarArgs<JSAny?>('loadModelFiles'.toJS, <JSAny?>[
      modelFiles.jsify(),
    ]),
    context: 'KiwiApi.loadModelFiles',
  );
  if (loadResultAny == null) {
    throw const KiwiException('KiwiApi.loadModelFiles returned null.');
  }

  final JSObject loadResult = loadResultAny as JSObject;
  final JSAny? modelPathAny = loadResult['modelPath'];
  final String modelPath = modelPathAny != null && modelPathAny.isA<JSString>()
      ? (modelPathAny as JSString).toDart
      : '';
  if (modelPath.isEmpty) {
    throw const KiwiException(
      'KiwiApi.loadModelFiles did not return modelPath.',
    );
  }

  final Map<String, Object?> apiBuildArgs = Map<String, Object?>.from(
    buildArgs,
  );
  apiBuildArgs['modelPath'] = modelPath;
  apiBuildArgs.remove('modelFiles');

  final Object? userDictsAny = apiBuildArgs['userDicts'];
  if (userDictsAny is List) {
    apiBuildArgs['userDicts'] = userDictsAny
        .map((Object? path) => '$modelPath/${path ?? ''}')
        .toList(growable: false);
  }

  final JSAny? kiwiIdAny = api.callMethodVarArgs<JSAny?>('cmd'.toJS, <JSAny?>[
    <String, Object?>{
      'method': 'build',
      'args': <Object?>[apiBuildArgs],
    }.jsify(),
  ]);
  final int kiwiId = _asInt(kiwiIdAny, context: 'KiwiApi.cmd(build)');
  return _BuiltKiwi(api: api, kiwiId: kiwiId);
}

JSObject? _extractBuilderApi(JSObject builder) {
  final JSAny? apiAny = builder['api'];
  final JSAny? normalized = _normalizeJsAny(apiAny);
  if (normalized == null) {
    return null;
  }
  try {
    return normalized as JSObject;
  } catch (_) {
    return null;
  }
}

int _asInt(JSAny? value, {required String context}) {
  if (value == null) {
    throw KiwiException('$context returned null.');
  }
  final Object? dartified = value.dartify();
  if (dartified is num) {
    return dartified.toInt();
  }
  throw KiwiException('$context returned non-numeric value: $dartified');
}

class _BuiltKiwi {
  final JSObject? kiwi;
  final JSObject? api;
  final int? kiwiId;

  const _BuiltKiwi({this.kiwi, this.api, this.kiwiId});
}

Map<String, Object?> _asObjectMap(Map<String, Uint8List> files) {
  return <String, Object?>{
    for (final MapEntry<String, Uint8List> entry in files.entries)
      entry.key: entry.value,
  };
}

Future<JSObject> _loadKiwiModule() {
  _moduleFuture ??= _loadKiwiModuleImpl();
  return _moduleFuture!;
}

Future<Map<String, Uint8List>> _ensureWebModelFiles() {
  final Future<Map<String, Uint8List>>? cached = _webModelFilesFuture;
  if (cached != null) {
    return cached;
  }
  final Future<Map<String, Uint8List>> next = _downloadDefaultWebModelFiles();
  _webModelFilesFuture = next;
  return next.whenComplete(() {
    if (identical(_webModelFilesFuture, next)) {
      _webModelFilesFuture = null;
    }
  });
}

Future<Map<String, Uint8List>> _downloadDefaultWebModelFiles() async {
  final List<String> attempts = <String>[];
  try {
    final Uint8List archiveBytes = await _downloadDefaultModelArchive(attempts);
    _verifyWebModelArchiveChecksum(archiveBytes);

    final Map<String, Uint8List> modelFiles = _extractModelFilesFromArchive(
      archiveBytes,
    );
    _validateWebModelFiles(modelFiles);
    return modelFiles;
  } catch (error) {
    final String details = error is KiwiException
        ? error.message
        : error.toString();
    _webLog(
      'default web model prepare failed: $details | '
      'attempts=${attempts.join(' | ')}',
    );
    throw KiwiException(
      'Failed to prepare default web model: $details. '
      'Attempts: ${attempts.join(' | ')}. '
      'On web, host model files on same-origin assets or pass '
      'modelPath/assetModelPath/FLUTTER_KIWI_NLP_WEB_MODEL_BASE_URL '
      '(legacy: FLUTTER_KIWI_FFI_WEB_MODEL_BASE_URL).',
    );
  }
}

Future<Uint8List> _downloadDefaultModelArchive(List<String> attempts) async {
  final Set<String> visited = <String>{};
  final List<String> urlCandidates = <String>[
    if (_defaultModelArchiveUrl.trim().isNotEmpty)
      _defaultModelArchiveUrl.trim(),
    _defaultReleaseArchiveUrl(),
  ];

  for (final String url in urlCandidates) {
    if (!visited.add(url)) {
      continue;
    }
    try {
      final Uint8List bytes = await _downloadBinaryFromUrl(url);
      attempts.add('archive:$url(ok)');
      return bytes;
    } catch (error) {
      attempts.add('archive:$url($error)');
    }
  }

  try {
    final Uint8List bytes = await _downloadArchiveFromGithubApi();
    attempts.add('archive:github-api(ok)');
    return bytes;
  } catch (error) {
    attempts.add('archive:github-api($error)');
  }

  throw const KiwiException('Default web model archive download failed.');
}

String _defaultReleaseArchiveUrl() {
  return 'https://github.com/$_defaultModelGithubRepo/releases/download/'
      '$_defaultModelArchiveVersion/$_defaultModelArchiveName';
}

Future<Uint8List> _downloadBinaryFromUrl(String url) async {
  final Uri uri = Uri.parse(url);
  final http.Response response = await http
      .get(uri)
      .timeout(const Duration(seconds: 45));
  if (response.statusCode != 200) {
    throw KiwiException('HTTP ${response.statusCode} while downloading $uri');
  }
  return response.bodyBytes;
}

Future<Uint8List> _downloadArchiveFromGithubApi() async {
  final Uri releaseMetaUri = Uri.parse(
    'https://api.github.com/repos/$_defaultModelGithubRepo/releases/tags/'
    '$_defaultModelArchiveVersion',
  );
  final http.Response releaseMetaResponse = await http
      .get(
        releaseMetaUri,
        headers: const <String, String>{
          'Accept': 'application/vnd.github+json',
        },
      )
      .timeout(const Duration(seconds: 30));
  if (releaseMetaResponse.statusCode != 200) {
    throw KiwiException(
      'Release metadata request failed (${releaseMetaResponse.statusCode})',
    );
  }

  final Object? decoded = jsonDecode(releaseMetaResponse.body);
  if (decoded is! Map<String, dynamic>) {
    throw const KiwiException('Invalid GitHub release metadata payload.');
  }
  final List<dynamic> assets =
      decoded['assets'] as List<dynamic>? ?? <dynamic>[];
  Map<String, dynamic>? target;
  for (final dynamic asset in assets) {
    if (asset is Map<String, dynamic> &&
        asset['name']?.toString() == _defaultModelArchiveName) {
      target = asset;
      break;
    }
  }
  if (target == null) {
    throw KiwiException(
      'Asset not found in release: $_defaultModelArchiveName',
    );
  }

  final String apiAssetUrl = target['url']?.toString() ?? '';
  if (apiAssetUrl.isNotEmpty) {
    final Uri uri = Uri.parse(apiAssetUrl);
    final http.Response response = await http
        .get(
          uri,
          headers: const <String, String>{'Accept': 'application/octet-stream'},
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode == 200 &&
        !isJsonContentType(response.headers['content-type'])) {
      return response.bodyBytes;
    }
  }

  final String browserDownloadUrl =
      target['browser_download_url']?.toString() ?? '';
  if (browserDownloadUrl.isEmpty) {
    throw const KiwiException('Asset URL missing in GitHub release metadata.');
  }
  return _downloadBinaryFromUrl(browserDownloadUrl);
}

void _verifyWebModelArchiveChecksum(Uint8List bytes) {
  final String expected = _defaultModelArchiveSha256.trim().toLowerCase();
  if (expected.isEmpty) {
    return;
  }
  final String actual = sha256.convert(bytes).toString().toLowerCase();
  if (actual != expected) {
    throw KiwiException(
      'Default web model checksum mismatch. expected=$expected actual=$actual',
    );
  }
}

Map<String, Uint8List> _extractModelFilesFromArchive(Uint8List archiveBytes) {
  final List<int> tarBytes = GZipDecoder().decodeBytes(archiveBytes);
  final Archive tarArchive = TarDecoder().decodeBytes(tarBytes);
  final Map<String, Uint8List> files = <String, Uint8List>{};

  for (final ArchiveFile entry in tarArchive.files) {
    if (!entry.isFile) {
      continue;
    }
    final String baseName = kiwiBaseName(entry.name);
    if (!kiwiModelFileNames.contains(baseName)) {
      continue;
    }
    final Object content = entry.content;
    if (content is Uint8List) {
      files[baseName] = content;
    } else if (content is List<int>) {
      files[baseName] = Uint8List.fromList(content);
    }
  }
  return files;
}

void _validateWebModelFiles(Map<String, Uint8List> files) {
  final List<String> missing = findMissingKiwiModelFiles(files);
  if (missing.isNotEmpty) {
    throw KiwiException(
      'Downloaded default web model is incomplete. Missing files: ${missing.join(', ')}',
    );
  }
}

Future<JSObject> _loadKiwiModuleImpl() async {
  try {
    final JSAny? moduleAny =
        await _resolveJsFutureLike(
          importModule(_defaultModuleUrl.toJS),
          context: 'import($_defaultModuleUrl)',
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw const KiwiException(
              'Timed out while loading kiwi-nlp web module.',
            );
          },
        );
    if (moduleAny == null) {
      throw const KiwiException('Imported module is null or undefined.');
    }
    return moduleAny as JSObject;
  } catch (error) {
    throw KiwiException('Failed to import kiwi-nlp module: $error');
  }
}

Future<JSAny?> _resolveJsFutureLike(
  JSAny? value, {
  required String context,
}) async {
  final JSAny? normalizedInput = _normalizeJsAny(value);
  if (normalizedInput == null) {
    return null;
  }
  bool isPromise = false;
  try {
    isPromise = normalizedInput.instanceOfString('Promise');
  } catch (error) {
    _webLog('$context promise-detect failed: $error');
  }
  if (isPromise) {
    try {
      final JSAny? resolved = await _awaitPromise(
        normalizedInput,
        context: context,
      );
      return resolved;
    } catch (error) {
      throw KiwiException('$context failed: $error');
    }
  }
  return normalizedInput;
}

Future<JSAny?> _awaitPromise(JSAny promiseValue, {required String context}) {
  final Completer<void> completer = Completer<void>();
  JSAny? resolvedValue;
  try {
    final JSObject promise = promiseValue as JSObject;
    final JSExportedDartFunction onFulfilled = ((JSAny? resolved) {
      if (!completer.isCompleted) {
        resolvedValue = _normalizeJsAny(resolved);
        completer.complete();
      }
    }).toJS;
    final JSExportedDartFunction onRejected = ((JSAny? reason) {
      if (!completer.isCompleted) {
        final JSAny? normalizedReason = _normalizeJsAny(reason);
        String reasonText;
        try {
          reasonText =
              normalizedReason?.dartify().toString() ?? 'null/undefined';
        } catch (_) {
          reasonText = normalizedReason?.toString() ?? 'null/undefined';
        }
        completer.completeError(
          KiwiException('$context rejected: $reasonText'),
        );
      }
    }).toJS;
    promise.callMethodVarArgs<JSAny?>('then'.toJS, <JSAny?>[
      onFulfilled,
      onRejected,
    ]);
  } catch (error, stackTrace) {
    if (!completer.isCompleted) {
      completer.completeError(
        KiwiException('$context promise attach failed: $error'),
        stackTrace,
      );
    }
  }
  return completer.future.then((_) => resolvedValue);
}

JSAny? _normalizeJsAny(JSAny? value) {
  if (value == null) {
    return null;
  }
  try {
    if (value.isUndefined || value.isNull) {
      return null;
    }
  } catch (_) {
    // Fall through to best-effort return.
  }
  try {
    if (value.isUndefinedOrNull) {
      return null;
    }
  } catch (_) {
    // Fall through to best-effort return.
  }
  return value;
}

void _webLog(String message) {
  // ignore: avoid_print
  print('[flutter_kiwi_nlp/web] $message');
}
