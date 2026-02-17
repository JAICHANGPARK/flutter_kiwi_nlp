import 'package:flutter_kiwi_nlp/src/kiwi_analyzer_web.dart' as kiwi_web;

bool get kiwiWebRuntimeProbeSupported => true;

String kiwiWebModuleUrlForTest() => kiwi_web.debugKiwiWebModuleUrlForTest();

String kiwiWebWasmUrlForTest() => kiwi_web.debugKiwiWebWasmUrlForTest();

String kiwiWebModelUrlBaseForTest() {
  return kiwi_web.debugKiwiWebResolveModelUrlBaseForTest();
}
