/// Exception type used by `flutter_kiwi_nlp`.
///
/// Check [message] for the user-facing error reason.
class KiwiException implements Exception {
  /// A human-readable description of the failure.
  final String message;

  /// Creates a plugin exception with [message].
  const KiwiException(this.message);

  @pragma('vm:never-inline')
  @override
  String toString() => 'KiwiException: $message';
}
