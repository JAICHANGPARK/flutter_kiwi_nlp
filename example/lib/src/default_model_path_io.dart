import 'dart:io';

String defaultModelPath() {
  return Platform.environment['FLUTTER_KIWI_FFI_MODEL_PATH'] ?? '';
}
