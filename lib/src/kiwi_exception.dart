class KiwiException implements Exception {
  final String message;

  const KiwiException(this.message);

  @override
  String toString() => 'KiwiException: $message';
}
