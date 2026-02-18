// Verifies generated FFI bindings dispatch to resolved native symbols.
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_ffi_bindings_generated.dart';
import 'package:flutter_test/flutter_test.dart';

class _BindingStubs {
  // Tracks native pointers that pass through free-string for leak checks.
  final Set<int> freedPointers = <int>{};
  final List<ffi.NativeCallable<dynamic>> _callables =
      <ffi.NativeCallable<dynamic>>[];
  final ffi.Pointer<ffi.Char> _versionPtr = '1.2.3'.toNativeUtf8().cast();
  final ffi.Pointer<ffi.Char> _lastErrorPtr = 'stub-last-error'
      .toNativeUtf8()
      .cast();

  late final ffi.NativeCallable<
    ffi.Pointer<flutter_kiwi_ffi_handle_t> Function(
      ffi.Pointer<ffi.Char>,
      ffi.Int32,
      ffi.Int32,
      ffi.Int32,
    )
  >
  _init = _trackCallable(
    ffi.NativeCallable<
      ffi.Pointer<flutter_kiwi_ffi_handle_t> Function(
        ffi.Pointer<ffi.Char>,
        ffi.Int32,
        ffi.Int32,
        ffi.Int32,
      )
    >.isolateLocal((
      ffi.Pointer<ffi.Char> modelPath,
      int numThreads,
      int buildOptions,
      int matchOptions,
    ) {
      return ffi.Pointer<flutter_kiwi_ffi_handle_t>.fromAddress(11);
    }),
  );

  late final ffi.NativeCallable<
    ffi.Int32 Function(ffi.Pointer<flutter_kiwi_ffi_handle_t>)
  >
  _close = _trackCallable(
    ffi.NativeCallable<
      ffi.Int32 Function(ffi.Pointer<flutter_kiwi_ffi_handle_t>)
    >.isolateLocal((ffi.Pointer<flutter_kiwi_ffi_handle_t> handle) {
      return 0;
    }, exceptionalReturn: -1),
  );

  late final ffi.NativeCallable<
    ffi.Pointer<ffi.Char> Function(
      ffi.Pointer<flutter_kiwi_ffi_handle_t>,
      ffi.Pointer<ffi.Char>,
      ffi.Int32,
      ffi.Int32,
    )
  >
  _analyze = _trackCallable(
    ffi.NativeCallable<
      ffi.Pointer<ffi.Char> Function(
        ffi.Pointer<flutter_kiwi_ffi_handle_t>,
        ffi.Pointer<ffi.Char>,
        ffi.Int32,
        ffi.Int32,
      )
    >.isolateLocal((
      ffi.Pointer<flutter_kiwi_ffi_handle_t> handle,
      ffi.Pointer<ffi.Char> text,
      int topN,
      int matchOptions,
    ) {
      return '{"candidates":[]}'.toNativeUtf8().cast<ffi.Char>();
    }),
  );

  late final ffi.NativeCallable<
    ffi.Pointer<ffi.Char> Function(
      ffi.Pointer<flutter_kiwi_ffi_handle_t>,
      ffi.Pointer<ffi.Pointer<ffi.Char>>,
      ffi.Int32,
      ffi.Int32,
      ffi.Int32,
    )
  >
  _analyzeBatch = _trackCallable(
    ffi.NativeCallable<
      ffi.Pointer<ffi.Char> Function(
        ffi.Pointer<flutter_kiwi_ffi_handle_t>,
        ffi.Pointer<ffi.Pointer<ffi.Char>>,
        ffi.Int32,
        ffi.Int32,
        ffi.Int32,
      )
    >.isolateLocal((
      ffi.Pointer<flutter_kiwi_ffi_handle_t> handle,
      ffi.Pointer<ffi.Pointer<ffi.Char>> texts,
      int textCount,
      int topN,
      int matchOptions,
    ) {
      return '{"results":[{"candidates":[]},{"candidates":[]}]}'
          .toNativeUtf8()
          .cast<ffi.Char>();
    }),
  );

  late final ffi.NativeCallable<
    ffi.Int32 Function(
      ffi.Pointer<flutter_kiwi_ffi_handle_t>,
      ffi.Pointer<ffi.Char>,
      ffi.Int32,
      ffi.Int32,
      ffi.Pointer<ffi.Int32>,
    )
  >
  _analyzeTokenCount = _trackCallable(
    ffi.NativeCallable<
      ffi.Int32 Function(
        ffi.Pointer<flutter_kiwi_ffi_handle_t>,
        ffi.Pointer<ffi.Char>,
        ffi.Int32,
        ffi.Int32,
        ffi.Pointer<ffi.Int32>,
      )
    >.isolateLocal((
      ffi.Pointer<flutter_kiwi_ffi_handle_t> handle,
      ffi.Pointer<ffi.Char> text,
      int topN,
      int matchOptions,
      ffi.Pointer<ffi.Int32> outTokenCount,
    ) {
      outTokenCount.value = 42;
      return 0;
    }, exceptionalReturn: -1),
  );

  late final ffi.NativeCallable<
    ffi.Int32 Function(
      ffi.Pointer<flutter_kiwi_ffi_handle_t>,
      ffi.Pointer<ffi.Pointer<ffi.Char>>,
      ffi.Int32,
      ffi.Int32,
      ffi.Int32,
      ffi.Pointer<ffi.Int32>,
    )
  >
  _analyzeTokenCountBatch = _trackCallable(
    ffi.NativeCallable<
      ffi.Int32 Function(
        ffi.Pointer<flutter_kiwi_ffi_handle_t>,
        ffi.Pointer<ffi.Pointer<ffi.Char>>,
        ffi.Int32,
        ffi.Int32,
        ffi.Int32,
        ffi.Pointer<ffi.Int32>,
      )
    >.isolateLocal((
      ffi.Pointer<flutter_kiwi_ffi_handle_t> handle,
      ffi.Pointer<ffi.Pointer<ffi.Char>> texts,
      int textCount,
      int topN,
      int matchOptions,
      ffi.Pointer<ffi.Int32> outTokenCounts,
    ) {
      for (int index = 0; index < textCount; index += 1) {
        outTokenCounts[index] = 70 + index;
      }
      return 0;
    }, exceptionalReturn: -1),
  );

  late final ffi.NativeCallable<
    ffi.Int32 Function(
      ffi.Pointer<flutter_kiwi_ffi_handle_t>,
      ffi.Pointer<ffi.Pointer<ffi.Char>>,
      ffi.Int32,
      ffi.Int32,
      ffi.Int32,
      ffi.Int32,
      ffi.Pointer<ffi.Int64>,
    )
  >
  _analyzeTokenCountBatchRuns = _trackCallable(
    ffi.NativeCallable<
      ffi.Int32 Function(
        ffi.Pointer<flutter_kiwi_ffi_handle_t>,
        ffi.Pointer<ffi.Pointer<ffi.Char>>,
        ffi.Int32,
        ffi.Int32,
        ffi.Int32,
        ffi.Int32,
        ffi.Pointer<ffi.Int64>,
      )
    >.isolateLocal((
      ffi.Pointer<flutter_kiwi_ffi_handle_t> handle,
      ffi.Pointer<ffi.Pointer<ffi.Char>> texts,
      int textCount,
      int runs,
      int topN,
      int matchOptions,
      ffi.Pointer<ffi.Int64> outTotalTokens,
    ) {
      outTotalTokens.value = 4321;
      return 0;
    }, exceptionalReturn: -1),
  );

  late final ffi.NativeCallable<
    ffi.Int32 Function(
      ffi.Pointer<flutter_kiwi_ffi_handle_t>,
      ffi.Pointer<ffi.Char>,
      ffi.Pointer<ffi.Char>,
      ffi.Float,
    )
  >
  _addWord = _trackCallable(
    ffi.NativeCallable<
      ffi.Int32 Function(
        ffi.Pointer<flutter_kiwi_ffi_handle_t>,
        ffi.Pointer<ffi.Char>,
        ffi.Pointer<ffi.Char>,
        ffi.Float,
      )
    >.isolateLocal((
      ffi.Pointer<flutter_kiwi_ffi_handle_t> handle,
      ffi.Pointer<ffi.Char> word,
      ffi.Pointer<ffi.Char> tag,
      double score,
    ) {
      return 0;
    }, exceptionalReturn: -1),
  );

  late final ffi.NativeCallable<ffi.Void Function(ffi.Pointer<ffi.Char>)>
  _freeString = _trackCallable(
    ffi.NativeCallable<ffi.Void Function(ffi.Pointer<ffi.Char>)>.isolateLocal((
      ffi.Pointer<ffi.Char> value,
    ) {
      if (value != ffi.nullptr) {
        freedPointers.add(value.address);
        malloc.free(value.cast<Utf8>());
      }
    }),
  );

  late final ffi.NativeCallable<ffi.Pointer<ffi.Char> Function()> _lastError =
      _trackCallable(
        ffi.NativeCallable<ffi.Pointer<ffi.Char> Function()>.isolateLocal(() {
          return _lastErrorPtr;
        }),
      );

  late final ffi.NativeCallable<ffi.Pointer<ffi.Char> Function()> _version =
      _trackCallable(
        ffi.NativeCallable<ffi.Pointer<ffi.Char> Function()>.isolateLocal(() {
          return _versionPtr;
        }),
      );

  ffi.NativeCallable<T> _trackCallable<T extends Function>(
    ffi.NativeCallable<T> callable,
  ) {
    _callables.add(callable as ffi.NativeCallable<dynamic>);
    return callable;
  }

  ffi.Pointer<T> lookup<T extends ffi.NativeType>(String symbolName) {
    // Exposes fake symbols so generated bindings can resolve function pointers.
    final ffi.Pointer<ffi.NativeType> symbol = switch (symbolName) {
      'flutter_kiwi_ffi_init' => _init.nativeFunction.cast(),
      'flutter_kiwi_ffi_close' => _close.nativeFunction.cast(),
      'flutter_kiwi_ffi_analyze_json' => _analyze.nativeFunction.cast(),
      'flutter_kiwi_ffi_analyze_json_batch' =>
        _analyzeBatch.nativeFunction.cast(),
      'flutter_kiwi_ffi_analyze_token_count' =>
        _analyzeTokenCount.nativeFunction.cast(),
      'flutter_kiwi_ffi_analyze_token_count_batch' =>
        _analyzeTokenCountBatch.nativeFunction.cast(),
      'flutter_kiwi_ffi_analyze_token_count_batch_runs' =>
        _analyzeTokenCountBatchRuns.nativeFunction.cast(),
      'flutter_kiwi_ffi_add_user_word' => _addWord.nativeFunction.cast(),
      'flutter_kiwi_ffi_free_string' => _freeString.nativeFunction.cast(),
      'flutter_kiwi_ffi_last_error' => _lastError.nativeFunction.cast(),
      'flutter_kiwi_ffi_version' => _version.nativeFunction.cast(),
      _ => throw ArgumentError('Unknown symbol: $symbolName'),
    };
    return symbol.cast<T>();
  }

  void dispose() {
    // Releases callables and static C strings allocated by this test stub.
    for (final ffi.NativeCallable<dynamic> callable in _callables) {
      callable.close();
    }
    malloc.free(_versionPtr.cast<Utf8>());
    malloc.free(_lastErrorPtr.cast<Utf8>());
  }
}

void main() {
  test('generated bindings can be constructed from DynamicLibrary', () {
    final FlutterKiwiFfiBindings bindings = FlutterKiwiFfiBindings(
      ffi.DynamicLibrary.process(),
    );
    expect(bindings, isA<FlutterKiwiFfiBindings>());
  });

  test('generated bindings route calls through symbol lookup', () {
    final _BindingStubs stubs = _BindingStubs();
    addTearDown(stubs.dispose);
    final FlutterKiwiFfiBindings bindings = FlutterKiwiFfiBindings.fromLookup(
      stubs.lookup,
    );

    final ffi.Pointer<ffi.Char> modelPath = '/tmp/model'.toNativeUtf8().cast();
    final ffi.Pointer<ffi.Char> text = '안녕'.toNativeUtf8().cast();
    final ffi.Pointer<ffi.Char> word = '키위'.toNativeUtf8().cast();
    final ffi.Pointer<ffi.Char> tag = 'NNP'.toNativeUtf8().cast();
    addTearDown(() {
      malloc.free(modelPath.cast<Utf8>());
      malloc.free(text.cast<Utf8>());
      malloc.free(word.cast<Utf8>());
      malloc.free(tag.cast<Utf8>());
    });

    final ffi.Pointer<flutter_kiwi_ffi_handle_t> handle = bindings
        .flutter_kiwi_ffi_init(modelPath, 2, 3, 4);
    expect(handle.address, 11);
    expect(bindings.flutter_kiwi_ffi_close(handle), 0);
    expect(bindings.flutter_kiwi_ffi_add_user_word(handle, word, tag, 0.5), 0);
    final ffi.Pointer<ffi.Int32> outTokenCount = malloc<ffi.Int32>(1);
    addTearDown(() {
      malloc.free(outTokenCount);
    });
    expect(
      bindings.flutter_kiwi_ffi_analyze_token_count(
        handle,
        text,
        1,
        0,
        outTokenCount,
      ),
      0,
    );
    expect(outTokenCount.value, 42);
    final ffi.Pointer<ffi.Pointer<ffi.Char>> batchTexts =
        malloc<ffi.Pointer<ffi.Char>>(2);
    final ffi.Pointer<ffi.Int32> batchOutTokenCounts = malloc<ffi.Int32>(2);
    final ffi.Pointer<ffi.Char> batchText0 = 'x'.toNativeUtf8().cast();
    final ffi.Pointer<ffi.Char> batchText1 = 'y'.toNativeUtf8().cast();
    batchTexts[0] = batchText0;
    batchTexts[1] = batchText1;
    addTearDown(() {
      malloc.free(batchText0.cast<Utf8>());
      malloc.free(batchText1.cast<Utf8>());
      malloc.free(batchTexts);
      malloc.free(batchOutTokenCounts);
    });
    expect(
      bindings.flutter_kiwi_ffi_analyze_token_count_batch(
        handle,
        batchTexts,
        2,
        1,
        0,
        batchOutTokenCounts,
      ),
      0,
    );
    expect(batchOutTokenCounts[0], 70);
    expect(batchOutTokenCounts[1], 71);
    final ffi.Pointer<ffi.Int64> batchRunsOutTotalTokens = malloc<ffi.Int64>(1);
    addTearDown(() {
      malloc.free(batchRunsOutTotalTokens);
    });
    expect(
      bindings.flutter_kiwi_ffi_analyze_token_count_batch_runs(
        handle,
        batchTexts,
        2,
        3,
        1,
        0,
        batchRunsOutTotalTokens,
      ),
      0,
    );
    expect(batchRunsOutTotalTokens.value, 4321);

    final ffi.Pointer<ffi.Char> jsonPtr = bindings
        .flutter_kiwi_ffi_analyze_json(handle, text, 1, 0);
    expect(jsonPtr.cast<Utf8>().toDartString(), '{"candidates":[]}');
    bindings.flutter_kiwi_ffi_free_string(jsonPtr);
    expect(stubs.freedPointers, contains(jsonPtr.address));
    final ffi.Pointer<ffi.Char> batchJsonPtr = bindings
        .flutter_kiwi_ffi_analyze_json_batch(handle, batchTexts, 2, 1, 0);
    expect(
      batchJsonPtr.cast<Utf8>().toDartString(),
      '{"results":[{"candidates":[]},{"candidates":[]}]}',
    );
    bindings.flutter_kiwi_ffi_free_string(batchJsonPtr);
    expect(stubs.freedPointers, contains(batchJsonPtr.address));

    expect(
      bindings.flutter_kiwi_ffi_last_error().cast<Utf8>().toDartString(),
      'stub-last-error',
    );
    expect(
      bindings.flutter_kiwi_ffi_version().cast<Utf8>().toDartString(),
      '1.2.3',
    );
  });
}
