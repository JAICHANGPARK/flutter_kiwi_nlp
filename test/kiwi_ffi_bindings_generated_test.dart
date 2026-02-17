import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_ffi_bindings_generated.dart';
import 'package:flutter_test/flutter_test.dart';

class _BindingStubs {
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
    final ffi.Pointer<ffi.NativeType> symbol = switch (symbolName) {
      'flutter_kiwi_ffi_init' => _init.nativeFunction.cast(),
      'flutter_kiwi_ffi_close' => _close.nativeFunction.cast(),
      'flutter_kiwi_ffi_analyze_json' => _analyze.nativeFunction.cast(),
      'flutter_kiwi_ffi_add_user_word' => _addWord.nativeFunction.cast(),
      'flutter_kiwi_ffi_free_string' => _freeString.nativeFunction.cast(),
      'flutter_kiwi_ffi_last_error' => _lastError.nativeFunction.cast(),
      'flutter_kiwi_ffi_version' => _version.nativeFunction.cast(),
      _ => throw ArgumentError('Unknown symbol: $symbolName'),
    };
    return symbol.cast<T>();
  }

  void dispose() {
    for (final ffi.NativeCallable<dynamic> callable in _callables) {
      callable.close();
    }
    malloc.free(_versionPtr.cast<Utf8>());
    malloc.free(_lastErrorPtr.cast<Utf8>());
  }
}

void main() {
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

    final ffi.Pointer<ffi.Char> jsonPtr = bindings
        .flutter_kiwi_ffi_analyze_json(handle, text, 1, 0);
    expect(jsonPtr.cast<Utf8>().toDartString(), '{"candidates":[]}');
    bindings.flutter_kiwi_ffi_free_string(jsonPtr);
    expect(stubs.freedPointers, contains(jsonPtr.address));

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
