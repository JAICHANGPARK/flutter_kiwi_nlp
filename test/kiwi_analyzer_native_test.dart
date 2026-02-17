import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_ffi_bindings_generated.dart';
import 'package:flutter_kiwi_nlp/src/kiwi_analyzer_native.dart';
import 'package:flutter_kiwi_nlp/src/kiwi_exception.dart';
import 'package:flutter_kiwi_nlp/src/kiwi_model_assets.dart';
import 'package:flutter_kiwi_nlp/src/kiwi_options.dart';
import 'package:flutter_test/flutter_test.dart';

ffi.Pointer<ffi.Char> _toCharPointer(String value) {
  return value.toNativeUtf8().cast<ffi.Char>();
}

class _FakeKiwiNativeBindings implements KiwiNativeBindings {
  ffi.Pointer<flutter_kiwi_ffi_handle_t> initHandle =
      ffi.Pointer<flutter_kiwi_ffi_handle_t>.fromAddress(1);
  bool returnNullVersion = false;
  bool returnNullAnalyze = false;
  bool returnNullLastError = false;
  int addUserWordStatus = 0;
  int closeStatus = 0;
  String lastErrorText = 'fake-native-error';
  String versionText = '0.0.1-test';
  String analyzePayload = '{"candidates": []}';

  int initCallCount = 0;
  int closeCallCount = 0;
  int addUserWordCallCount = 0;
  int? initNumThreads;
  int? initBuildOptions;
  int? initMatchOptions;
  String? initModelPath;
  int? analyzeTopN;
  int? analyzeMatchOptions;
  String? analyzeText;
  String? addWord;
  String? addTag;
  double? addScore;
  final List<int> freedAddresses = <int>[];

  ffi.Pointer<ffi.Char>? _lastErrorPointer;
  ffi.Pointer<ffi.Char>? _versionPointer;

  @override
  ffi.Pointer<flutter_kiwi_ffi_handle_t> flutter_kiwi_ffi_init(
    ffi.Pointer<ffi.Char> modelPath,
    int numThreads,
    int buildOptions,
    int matchOptions,
  ) {
    initCallCount += 1;
    initModelPath = modelPath.cast<Utf8>().toDartString();
    initNumThreads = numThreads;
    initBuildOptions = buildOptions;
    initMatchOptions = matchOptions;
    return initHandle;
  }

  @override
  int flutter_kiwi_ffi_close(ffi.Pointer<flutter_kiwi_ffi_handle_t> handle) {
    closeCallCount += 1;
    return closeStatus;
  }

  @override
  ffi.Pointer<ffi.Char> flutter_kiwi_ffi_analyze_json(
    ffi.Pointer<flutter_kiwi_ffi_handle_t> handle,
    ffi.Pointer<ffi.Char> text,
    int topN,
    int matchOptions,
  ) {
    analyzeText = text.cast<Utf8>().toDartString();
    analyzeTopN = topN;
    analyzeMatchOptions = matchOptions;
    if (returnNullAnalyze) {
      return ffi.nullptr;
    }
    return _toCharPointer(analyzePayload);
  }

  @override
  int flutter_kiwi_ffi_add_user_word(
    ffi.Pointer<flutter_kiwi_ffi_handle_t> handle,
    ffi.Pointer<ffi.Char> word,
    ffi.Pointer<ffi.Char> tag,
    double score,
  ) {
    addUserWordCallCount += 1;
    addWord = word.cast<Utf8>().toDartString();
    addTag = tag.cast<Utf8>().toDartString();
    addScore = score;
    return addUserWordStatus;
  }

  @override
  void flutter_kiwi_ffi_free_string(ffi.Pointer<ffi.Char> value) {
    if (value == ffi.nullptr) {
      return;
    }
    freedAddresses.add(value.address);
    malloc.free(value.cast<Utf8>());
  }

  @override
  ffi.Pointer<ffi.Char> flutter_kiwi_ffi_last_error() {
    if (returnNullLastError) {
      return ffi.nullptr;
    }
    _lastErrorPointer ??= _toCharPointer(lastErrorText);
    return _lastErrorPointer!;
  }

  @override
  ffi.Pointer<ffi.Char> flutter_kiwi_ffi_version() {
    if (returnNullVersion) {
      return ffi.nullptr;
    }
    _versionPointer ??= _toCharPointer(versionText);
    return _versionPointer!;
  }

  void dispose() {
    if (_lastErrorPointer != null) {
      malloc.free(_lastErrorPointer!.cast<Utf8>());
      _lastErrorPointer = null;
    }
    if (_versionPointer != null) {
      malloc.free(_versionPointer!.cast<Utf8>());
      _versionPointer = null;
    }
  }
}

Matcher kiwiExceptionMessage(String message) {
  return isA<KiwiException>().having(
    (KiwiException error) => error.message,
    'message',
    message,
  );
}

Future<void> _setAssetHandler(Map<String, Uint8List> assets) async {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    ByteData? message,
  ) async {
    if (message == null) {
      return null;
    }
    final String key = utf8.decode(
      message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );
    final Uint8List? value = assets[key];
    if (value == null) {
      return null;
    }
    return ByteData.view(value.buffer);
  });
}

Future<void> _clearAssetHandler() async {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
}

Future<Directory> _prepareCachedModelDirectory() async {
  final Directory modelDirectory = Directory(
    '${Directory.systemTemp.path}/flutter_kiwi_nlp_model_cache/'
    'v0.22.2_base/models/cong/base',
  );
  await modelDirectory.create(recursive: true);
  for (final String fileName in kiwiModelFileNames) {
    final int minBytes = kiwiMinModelFileBytes[fileName] ?? 1;
    final RandomAccessFile raf = File(
      '${modelDirectory.path}/$fileName',
    ).openSync(mode: FileMode.write);
    raf.truncateSync(minBytes);
    raf.closeSync();
  }
  return modelDirectory;
}

Future<void> _deleteDirectoryIfExists(String path) async {
  final Directory directory = Directory(path);
  if (directory.existsSync()) {
    await directory.delete(recursive: true);
  }
}

Uint8List _createGzipTarBytes(Map<String, List<int>> files) {
  final Archive archive = Archive();
  for (final MapEntry<String, List<int>> entry in files.entries) {
    archive.addFile(
      ArchiveFile(
        entry.key,
        entry.value.length,
        Uint8List.fromList(entry.value),
      ),
    );
  }
  final List<int> tarBytes = TarEncoder().encode(archive)!;
  return Uint8List.fromList(GZipEncoder().encode(tarBytes)!);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(this.statusCode, this._chunks);

  @override
  final int statusCode;
  final List<List<int>> _chunks;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> data)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(_chunks).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this._response);

  final HttpClientResponse _response;

  @override
  Future<HttpClientResponse> close() async {
    return _response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({required this.onGetUrl});

  final Future<HttpClientResponse> Function(Uri uri) onGetUrl;
  Duration? _connectionTimeout;

  @override
  Duration? get connectionTimeout => _connectionTimeout;

  @override
  set connectionTimeout(Duration? value) {
    _connectionTimeout = value;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final HttpClientResponse response = await onGetUrl(url);
    return _FakeHttpClientRequest(response);
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeKiwiNativeBindings fakeBindings;

  setUp(() {
    fakeBindings = _FakeKiwiNativeBindings();
    debugSetKiwiNativeBindingsFactoryForTest(() => fakeBindings);
  });

  tearDown(() async {
    debugSetKiwiNativeBindingsFactoryForTest(null);
    debugSetKiwiNativeArchiveOverridesForTest();
    debugSetKiwiNativeHttpClientFactoryForTest(null);
    fakeBindings.dispose();
    await _clearAssetHandler();
    await _deleteDirectoryIfExists(
      '${Directory.systemTemp.path}/flutter_kiwi_nlp_model',
    );
    await _deleteDirectoryIfExists(
      '${Directory.systemTemp.path}/flutter_kiwi_nlp_model_cache/v0.22.2_base',
    );
  });

  test('create injects default cong model type when absent', () async {
    final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
      modelPath: ' /tmp/model_path ',
      buildOptions: KiwiBuildOption.integrateAllomorph,
      numThreads: 4,
      matchOptions: KiwiMatchOption.url,
    );

    expect(fakeBindings.initModelPath, '/tmp/model_path');
    expect(fakeBindings.initNumThreads, 4);
    expect(fakeBindings.initMatchOptions, KiwiMatchOption.url);
    expect(
      fakeBindings.initBuildOptions! & 0x0F00,
      KiwiBuildOption.modelTypeCong,
    );
    await analyzer.close();
  });

  test('create preserves explicit model type bits', () async {
    final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
      modelPath: '/tmp/model_path',
      buildOptions: KiwiBuildOption.modelTypeLargest,
    );

    expect(
      fakeBindings.initBuildOptions! & 0x0F00,
      KiwiBuildOption.modelTypeLargest,
    );
    await analyzer.close();
  });

  test('create throws KiwiException when init returns nullptr', () async {
    fakeBindings.initHandle = ffi.nullptr;
    fakeBindings.lastErrorText = 'init failed';

    await expectLater(
      KiwiAnalyzer.create(modelPath: '/tmp/model_path'),
      throwsA(kiwiExceptionMessage('init failed')),
    );
  });

  test('create uses fallback message when native last_error is null', () async {
    fakeBindings.initHandle = ffi.nullptr;
    fakeBindings.returnNullLastError = true;

    await expectLater(
      KiwiAnalyzer.create(modelPath: '/tmp/model_path'),
      throwsA(kiwiExceptionMessage('Unknown kiwi native error.')),
    );
  });

  test(
    'nativeVersion returns version and unknown when pointer is null',
    () async {
      final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
        modelPath: '/tmp/model_path',
      );
      expect(analyzer.nativeVersion, '0.0.1-test');

      fakeBindings.returnNullVersion = true;
      expect(analyzer.nativeVersion, 'unknown');
      await analyzer.close();
    },
  );

  test('analyze parses json payload and frees returned string', () async {
    fakeBindings.analyzePayload = jsonEncode(<String, Object?>{
      'candidates': <Object?>[
        <String, Object?>{
          'probability': 0.9,
          'tokens': <Object?>[
            <String, Object?>{
              'form': '안녕',
              'tag': 'IC',
              'start': 0,
              'length': 2,
              'wordPosition': 0,
              'sentPosition': 0,
              'score': 0.1,
              'typoCost': 0.0,
            },
          ],
        },
      ],
    });
    final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
      modelPath: '/tmp/model_path',
    );

    final result = await analyzer.analyze(
      '안녕하세요',
      options: const KiwiAnalyzeOptions(
        topN: 3,
        matchOptions: KiwiMatchOption.email,
      ),
    );

    expect(fakeBindings.analyzeText, '안녕하세요');
    expect(fakeBindings.analyzeTopN, 3);
    expect(fakeBindings.analyzeMatchOptions, KiwiMatchOption.email);
    expect(result.candidates, hasLength(1));
    expect(result.candidates.first.tokens.first.form, '안녕');
    expect(fakeBindings.freedAddresses, isNotEmpty);
    await analyzer.close();
  });

  test('analyze throws on null native payload', () async {
    fakeBindings.returnNullAnalyze = true;
    fakeBindings.lastErrorText = 'analyze failed';
    final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
      modelPath: '/tmp/model_path',
    );

    await expectLater(
      analyzer.analyze('abc'),
      throwsA(kiwiExceptionMessage('analyze failed')),
    );
    await analyzer.close();
  });

  test('analyze throws on unexpected payload structure', () async {
    fakeBindings.analyzePayload = '[]';
    final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
      modelPath: '/tmp/model_path',
    );

    await expectLater(
      analyzer.analyze('abc'),
      throwsA(kiwiExceptionMessage('Unexpected analyze payload.')),
    );
    await analyzer.close();
  });

  test('addUserWord forwards arguments and handles error status', () async {
    final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
      modelPath: '/tmp/model_path',
    );

    await analyzer.addUserWord('키위', tag: 'NNP', score: 1.5);
    expect(fakeBindings.addWord, '키위');
    expect(fakeBindings.addTag, 'NNP');
    expect(fakeBindings.addScore, 1.5);
    expect(fakeBindings.addUserWordCallCount, 1);

    fakeBindings.addUserWordStatus = 2;
    fakeBindings.lastErrorText = 'add failed';
    await expectLater(
      analyzer.addUserWord('실패'),
      throwsA(kiwiExceptionMessage('add failed')),
    );
    await analyzer.close();
  });

  test('close is idempotent and closed analyzer rejects calls', () async {
    final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
      modelPath: '/tmp/model_path',
    );

    await analyzer.close();
    await analyzer.close();
    expect(fakeBindings.closeCallCount, 1);

    await expectLater(
      analyzer.analyze('abc'),
      throwsA(
        kiwiExceptionMessage(
          'KiwiAnalyzer is already closed. Create a new instance.',
        ),
      ),
    );
    await expectLater(
      analyzer.addUserWord('abc'),
      throwsA(
        kiwiExceptionMessage(
          'KiwiAnalyzer is already closed. Create a new instance.',
        ),
      ),
    );
  });

  test('close propagates native error status', () async {
    fakeBindings.closeStatus = 9;
    fakeBindings.lastErrorText = 'close failed';
    final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
      modelPath: '/tmp/model_path',
    );

    await expectLater(
      analyzer.close(),
      throwsA(kiwiExceptionMessage('close failed')),
    );
  });

  test('create extracts model assets from rootBundle', () async {
    final Map<String, Uint8List> assets = <String, Uint8List>{
      for (final String fileName in kiwiModelFileNames)
        'assets/custom/base/$fileName': Uint8List.fromList(<int>[1]),
    };
    await _setAssetHandler(assets);

    final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
      assetModelPath: 'assets/custom/base/',
    );
    final String modelPath = fakeBindings.initModelPath!;

    expect(Directory(modelPath).existsSync(), isTrue);
    for (final String fileName in kiwiModelFileNames) {
      expect(File('$modelPath/$fileName').existsSync(), isTrue);
    }
    await analyzer.close();
  });

  test('create throws when model assets are missing', () async {
    await _setAssetHandler(<String, Uint8List>{});

    await expectLater(
      KiwiAnalyzer.create(assetModelPath: 'assets/missing/base'),
      throwsA(
        isA<KiwiException>().having(
          (KiwiException error) => error.message,
          'message',
          contains('Failed to load Kiwi model assets'),
        ),
      ),
    );
  });

  test('create falls back to cached downloaded model directory', () async {
    await _setAssetHandler(<String, Uint8List>{});
    final Directory modelDirectory = await _prepareCachedModelDirectory();

    final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();

    expect(fakeBindings.initModelPath, modelDirectory.path);
    await analyzer.close();
  });

  test(
    'create downloads archive and fails when extracted model is incomplete',
    () async {
      await _setAssetHandler(<String, Uint8List>{});
      await _deleteDirectoryIfExists(
        '${Directory.systemTemp.path}/flutter_kiwi_nlp_model_cache/v0.22.2_base',
      );
      final Uint8List archiveBytes = _createGzipTarBytes(<String, List<int>>{
        'models/cong/base/cong.mdl': <int>[1, 2, 3],
      });
      debugSetKiwiNativeHttpClientFactoryForTest(
        () => _FakeHttpClient(
          onGetUrl: (Uri uri) async {
            return _FakeHttpClientResponse(HttpStatus.ok, <List<int>>[
              archiveBytes,
            ]);
          },
        ),
      );
      debugSetKiwiNativeArchiveOverridesForTest(
        archiveUrl: 'http://local.test/model.tgz',
        archiveSha256: '',
      );

      await expectLater(
        KiwiAnalyzer.create(),
        throwsA(
          isA<KiwiException>().having(
            (KiwiException error) => error.message,
            'message',
            contains('Downloaded model archive but required files are missing'),
          ),
        ),
      );
    },
  );

  test(
    'create reports checksum mismatch after archive verification retry',
    () async {
      await _setAssetHandler(<String, Uint8List>{});
      await _deleteDirectoryIfExists(
        '${Directory.systemTemp.path}/flutter_kiwi_nlp_model_cache/v0.22.2_base',
      );
      final Uint8List archiveBytes = _createGzipTarBytes(<String, List<int>>{
        'models/cong/base/cong.mdl': <int>[1, 2, 3],
      });
      int requestCount = 0;
      debugSetKiwiNativeHttpClientFactoryForTest(
        () => _FakeHttpClient(
          onGetUrl: (Uri uri) async {
            requestCount += 1;
            return _FakeHttpClientResponse(HttpStatus.ok, <List<int>>[
              archiveBytes,
            ]);
          },
        ),
      );
      debugSetKiwiNativeArchiveOverridesForTest(
        archiveUrl: 'http://local.test/model.tgz',
        archiveSha256: 'deadbeef',
      );

      await expectLater(
        KiwiAnalyzer.create(),
        throwsA(
          isA<KiwiException>().having(
            (KiwiException error) => error.message,
            'message',
            contains('Default model checksum mismatch'),
          ),
        ),
      );
      expect(requestCount, greaterThanOrEqualTo(2));
    },
  );

  test(
    'create propagates default model download http status failures',
    () async {
      await _setAssetHandler(<String, Uint8List>{});
      await _deleteDirectoryIfExists(
        '${Directory.systemTemp.path}/flutter_kiwi_nlp_model_cache/v0.22.2_base',
      );
      debugSetKiwiNativeHttpClientFactoryForTest(
        () => _FakeHttpClient(
          onGetUrl: (Uri uri) async {
            return _FakeHttpClientResponse(
              HttpStatus.internalServerError,
              const <List<int>>[],
            );
          },
        ),
      );
      debugSetKiwiNativeArchiveOverridesForTest(
        archiveUrl: 'http://local.test/model.tgz',
        archiveSha256: '',
      );

      await expectLater(
        KiwiAnalyzer.create(),
        throwsA(
          isA<KiwiException>().having(
            (KiwiException error) => error.message,
            'message',
            contains('Failed to download default model (500)'),
          ),
        ),
      );
    },
  );
}
