// Verifies adapter behavior that wraps generated FFI bindings.
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_ffi_bindings_generated.dart';
import 'package:flutter_kiwi_nlp/src/kiwi_analyzer_native.dart';
import 'package:flutter_test/flutter_test.dart';

class _AdapterBindingStubs {
  // Tracks native pointers that pass through free-string for leak checks.
  final Set<int> freedPointers = <int>{};
  final List<ffi.NativeCallable<dynamic>> _callables =
      <ffi.NativeCallable<dynamic>>[];
  final ffi.Pointer<ffi.Char> _versionPtr = '2.0.0'.toNativeUtf8().cast();
  final ffi.Pointer<ffi.Char> _lastErrorPtr = 'adapter-error'
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
  _init = _track(
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
      return ffi.Pointer<flutter_kiwi_ffi_handle_t>.fromAddress(91);
    }),
  );

  late final ffi.NativeCallable<
    ffi.Int32 Function(ffi.Pointer<flutter_kiwi_ffi_handle_t>)
  >
  _close = _track(
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
  _analyze = _track(
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
    ffi.Int32 Function(
      ffi.Pointer<flutter_kiwi_ffi_handle_t>,
      ffi.Pointer<ffi.Char>,
      ffi.Int32,
      ffi.Int32,
      ffi.Pointer<ffi.Int32>,
    )
  >
  _analyzeTokenCount = _track(
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
      outTokenCount.value = 24;
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
  _addWord = _track(
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
  _freeString = _track(
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
      _track(
        ffi.NativeCallable<ffi.Pointer<ffi.Char> Function()>.isolateLocal(() {
          return _lastErrorPtr;
        }),
      );

  late final ffi.NativeCallable<ffi.Pointer<ffi.Char> Function()> _version =
      _track(
        ffi.NativeCallable<ffi.Pointer<ffi.Char> Function()>.isolateLocal(() {
          return _versionPtr;
        }),
      );

  ffi.NativeCallable<T> _track<T extends Function>(ffi.NativeCallable<T> c) {
    _callables.add(c as ffi.NativeCallable<dynamic>);
    return c;
  }

  ffi.Pointer<T> lookup<T extends ffi.NativeType>(String symbolName) {
    // Exposes fake symbols so generated bindings can resolve function pointers.
    final ffi.Pointer<ffi.NativeType> pointer = switch (symbolName) {
      'flutter_kiwi_ffi_init' => _init.nativeFunction.cast(),
      'flutter_kiwi_ffi_close' => _close.nativeFunction.cast(),
      'flutter_kiwi_ffi_analyze_json' => _analyze.nativeFunction.cast(),
      'flutter_kiwi_ffi_analyze_token_count' =>
        _analyzeTokenCount.nativeFunction.cast(),
      'flutter_kiwi_ffi_add_user_word' => _addWord.nativeFunction.cast(),
      'flutter_kiwi_ffi_free_string' => _freeString.nativeFunction.cast(),
      'flutter_kiwi_ffi_last_error' => _lastError.nativeFunction.cast(),
      'flutter_kiwi_ffi_version' => _version.nativeFunction.cast(),
      _ => throw ArgumentError('Unknown symbol: $symbolName'),
    };
    return pointer.cast<T>();
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
  test('GeneratedKiwiNativeBindings delegates all calls', () {
    final _AdapterBindingStubs stubs = _AdapterBindingStubs();
    addTearDown(stubs.dispose);
    final FlutterKiwiFfiBindings generated = FlutterKiwiFfiBindings.fromLookup(
      stubs.lookup,
    );
    final GeneratedKiwiNativeBindings adapter = GeneratedKiwiNativeBindings(
      generated,
    );

    final ffi.Pointer<ffi.Char> modelPath = '/tmp/model'.toNativeUtf8().cast();
    final ffi.Pointer<ffi.Char> text = '텍스트'.toNativeUtf8().cast();
    final ffi.Pointer<ffi.Char> word = '단어'.toNativeUtf8().cast();
    final ffi.Pointer<ffi.Char> tag = 'NNP'.toNativeUtf8().cast();
    addTearDown(() {
      malloc.free(modelPath.cast<Utf8>());
      malloc.free(text.cast<Utf8>());
      malloc.free(word.cast<Utf8>());
      malloc.free(tag.cast<Utf8>());
    });

    final ffi.Pointer<flutter_kiwi_ffi_handle_t> handle = adapter
        .flutter_kiwi_ffi_init(modelPath, 1, 2, 3);
    expect(handle.address, 91);
    expect(adapter.flutter_kiwi_ffi_close(handle), 0);
    expect(adapter.flutter_kiwi_ffi_add_user_word(handle, word, tag, 0.2), 0);
    final ffi.Pointer<ffi.Int32> outTokenCount = malloc<ffi.Int32>(1);
    addTearDown(() {
      malloc.free(outTokenCount);
    });
    expect(
      adapter.flutter_kiwi_ffi_analyze_token_count(
        handle,
        text,
        1,
        0,
        outTokenCount,
      ),
      0,
    );
    expect(outTokenCount.value, 24);
    final ffi.Pointer<ffi.Char> json = adapter.flutter_kiwi_ffi_analyze_json(
      handle,
      text,
      1,
      0,
    );
    expect(json.cast<Utf8>().toDartString(), '{"candidates":[]}');
    adapter.flutter_kiwi_ffi_free_string(json);
    expect(stubs.freedPointers, contains(json.address));
    expect(
      adapter.flutter_kiwi_ffi_last_error().cast<Utf8>().toDartString(),
      'adapter-error',
    );
    expect(
      adapter.flutter_kiwi_ffi_version().cast<Utf8>().toDartString(),
      '2.0.0',
    );
  });
}
