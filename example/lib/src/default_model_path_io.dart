import 'dart:io';

String defaultModelPath() {
  return Platform.environment['FLUTTER_KIWI_NLP_MODEL_PATH'] ?? '';
}
