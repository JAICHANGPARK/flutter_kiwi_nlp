import 'kiwi_exception.dart';
import 'kiwi_options.dart';
import 'kiwi_types.dart';

const String _unsupportedMessage =
    'flutter_kiwi_nlp native backend is not available on this platform yet.';

class KiwiAnalyzer {
  KiwiAnalyzer._();

  static Future<KiwiAnalyzer> create({
    String? modelPath,
    String? assetModelPath,
    int numThreads = -1,
    int buildOptions = KiwiBuildOption.defaultOption,
    int matchOptions = KiwiMatchOption.allWithNormalizing,
  }) async {
    throw const KiwiException(_unsupportedMessage);
  }

  Future<KiwiAnalyzeResult> analyze(
    String text, {
    KiwiAnalyzeOptions options = const KiwiAnalyzeOptions(),
  }) async {
    throw const KiwiException(_unsupportedMessage);
  }

  Future<void> addUserWord(
    String word, {
    String tag = 'NNP',
    double score = 0.0,
  }) async {
    throw const KiwiException(_unsupportedMessage);
  }

  Future<void> close() async {
    throw const KiwiException(_unsupportedMessage);
  }

  String get nativeVersion => _unsupportedMessage;
}
