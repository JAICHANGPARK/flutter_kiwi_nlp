import 'kiwi_exception.dart';
import 'kiwi_options.dart';
import 'kiwi_types.dart';

const String _unsupportedMessage =
    'flutter_kiwi_nlp native backend is not available on this platform yet.';

/// Fallback analyzer used on unsupported platforms.
///
/// All methods throw a [KiwiException] with an unsupported-platform message.
class KiwiAnalyzer {
  /// Creates a fallback analyzer for unsupported platforms.
  @pragma('vm:never-inline')
  KiwiAnalyzer();

  Never _throwUnsupported() {
    throw const KiwiException(_unsupportedMessage);
  }

  /// Creates an analyzer.
  ///
  /// Parameters are accepted for API compatibility with supported platforms:
  /// [modelPath], [assetModelPath], [numThreads], [buildOptions], and
  /// [matchOptions].
  ///
  /// Throws a [KiwiException] on unsupported platforms.
  static Future<KiwiAnalyzer> create({
    String? modelPath,
    String? assetModelPath,
    int numThreads = -1,
    int buildOptions = KiwiBuildOption.defaultOption,
    int matchOptions = KiwiMatchOption.allWithNormalizing,
  }) async {
    KiwiAnalyzer()._throwUnsupported();
  }

  /// Analyzes [text].
  ///
  /// Throws a [KiwiException] on unsupported platforms.
  Future<KiwiAnalyzeResult> analyze(
    String text, {
    KiwiAnalyzeOptions options = const KiwiAnalyzeOptions(),
  }) async {
    _throwUnsupported();
  }

  /// Analyzes [text] and returns first-candidate token count.
  ///
  /// Throws a [KiwiException] on unsupported platforms.
  Future<int> analyzeTokenCount(
    String text, {
    KiwiAnalyzeOptions options = const KiwiAnalyzeOptions(),
  }) async {
    _throwUnsupported();
  }

  /// Adds a user word.
  ///
  /// Throws a [KiwiException] on unsupported platforms.
  Future<void> addUserWord(
    String word, {
    String tag = 'NNP',
    double score = 0.0,
  }) async {
    _throwUnsupported();
  }

  /// Releases analyzer resources.
  ///
  /// Throws a [KiwiException] on unsupported platforms.
  Future<void> close() async {
    _throwUnsupported();
  }

  /// The unsupported-platform message.
  String get nativeVersion => _unsupportedMessage;
}
