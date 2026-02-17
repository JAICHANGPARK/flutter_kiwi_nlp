import '_web_runtime_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'web runtime path: module/wasm/model base probe',
    () {
      final String moduleUrl = kiwiWebModuleUrlForTest();
      final String wasmUrl = kiwiWebWasmUrlForTest();
      final String modelUrlBase = kiwiWebModelUrlBaseForTest();

      // ignore: avoid_print
      print('[runtime/web] moduleUrl=$moduleUrl');
      // ignore: avoid_print
      print('[runtime/web] wasmUrl=$wasmUrl');
      // ignore: avoid_print
      print('[runtime/web] modelUrlBase=$modelUrlBase');

      expect(moduleUrl, isNotEmpty);
      expect(moduleUrl, endsWith('/index.js'));
      expect(wasmUrl, isNotEmpty);
      expect(wasmUrl, endsWith('/kiwi-wasm.wasm'));
      expect(modelUrlBase, isNotEmpty);
      expect(
        modelUrlBase,
        equals('assets/packages/flutter_kiwi_nlp/assets/kiwi-models/cong/base'),
      );
    },
    skip: !kiwiWebRuntimeProbeSupported,
  );
}
