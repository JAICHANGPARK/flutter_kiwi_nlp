import 'package:flutter_kiwi_nlp/src/kiwi_model_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeKiwiModelBasePath', () {
    test('trims input and removes trailing slash', () {
      expect(
        normalizeKiwiModelBasePath('  assets/kiwi-models/cong/base/  '),
        'assets/kiwi-models/cong/base',
      );
    });

    test('returns empty string for null/blank', () {
      expect(normalizeKiwiModelBasePath(null), '');
      expect(normalizeKiwiModelBasePath('   '), '');
    });
  });

  group('normalizeKiwiModelUrlBase', () {
    test('converts package path to assets path', () {
      expect(
        normalizeKiwiModelUrlBase('packages/flutter_kiwi_nlp/assets/model'),
        'assets/packages/flutter_kiwi_nlp/assets/model',
      );
      expect(
        normalizeKiwiModelUrlBase('/packages/flutter_kiwi_nlp/assets/model'),
        'assets/packages/flutter_kiwi_nlp/assets/model',
      );
    });

    test('keeps plain urls/paths as-is', () {
      expect(
        normalizeKiwiModelUrlBase('https://example.com/model'),
        'https://example.com/model',
      );
      expect(normalizeKiwiModelUrlBase('assets/model'), 'assets/model');
    });
  });

  group('buildKiwiModelFiles', () {
    test('creates file map for all required files', () {
      final Map<String, Object?> files = buildKiwiModelFiles('assets/base');

      expect(files.keys, orderedEquals(kiwiModelFileNames));
      expect(files['cong.mdl'], 'assets/base/cong.mdl');
      expect(files['default.dict'], 'assets/base/default.dict');
    });
  });

  group('shouldTryKiwiArchiveFallback', () {
    test('returns true for bundled asset paths', () {
      expect(shouldTryKiwiArchiveFallback('assets/models'), isTrue);
      expect(shouldTryKiwiArchiveFallback('packages/my_pkg/assets'), isTrue);
      expect(shouldTryKiwiArchiveFallback('/packages/my_pkg/assets'), isTrue);
    });

    test('returns false for non-asset urls', () {
      expect(
        shouldTryKiwiArchiveFallback('https://cdn.example/model'),
        isFalse,
      );
      expect(shouldTryKiwiArchiveFallback('/var/tmp/model'), isFalse);
    });
  });

  group('kiwiBaseName', () {
    test('extracts basename from unix and windows paths', () {
      expect(kiwiBaseName('a/b/c/file.txt'), 'file.txt');
      expect(kiwiBaseName(r'a\b\c\file.txt'), 'file.txt');
      expect(kiwiBaseName('file.txt'), 'file.txt');
    });
  });

  group('isJsonContentType', () {
    test('detects json content-types', () {
      expect(isJsonContentType('application/json'), isTrue);
      expect(isJsonContentType('application/problem+json'), isTrue);
      expect(isJsonContentType('APPLICATION/JSON; charset=utf-8'), isTrue);
    });

    test('returns false for non-json or null', () {
      expect(isJsonContentType('application/octet-stream'), isFalse);
      expect(isJsonContentType(null), isFalse);
    });
  });

  group('findMissingKiwiModelFiles', () {
    test('returns all files when none are provided', () {
      expect(
        findMissingKiwiModelFiles(<String, List<int>>{}),
        kiwiModelFileNames,
      );
    });

    test('returns empty list when all files satisfy min length', () {
      final Map<String, List<int>> files = <String, List<int>>{
        for (final String fileName in kiwiModelFileNames)
          fileName: List<int>.filled(kiwiMinModelFileBytes[fileName] ?? 1, 0),
      };

      expect(findMissingKiwiModelFiles(files), isEmpty);
    });

    test('returns undersized or missing file names', () {
      final Map<String, List<int>> files = <String, List<int>>{
        'combiningRule.txt': List<int>.filled(127, 0),
        'cong.mdl': List<int>.filled(kiwiMinModelFileBytes['cong.mdl']!, 0),
      };

      final List<String> missing = findMissingKiwiModelFiles(files);

      expect(missing, contains('combiningRule.txt'));
      expect(missing, contains('default.dict'));
    });
  });
}
