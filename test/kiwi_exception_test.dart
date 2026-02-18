// Verifies exception message preservation and string formatting behavior.
import 'package:flutter_kiwi_nlp/src/kiwi_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KiwiException', () {
    test('stores message and implements Exception', () {
      const KiwiException exception = KiwiException('boom');

      expect(exception.message, 'boom');
      expect(exception, isA<Exception>());
    });

    test('formats message with toString', () {
      const KiwiException exception = KiwiException('unsupported');

      expect(exception.toString(), 'KiwiException: unsupported');
    });
  });
}
