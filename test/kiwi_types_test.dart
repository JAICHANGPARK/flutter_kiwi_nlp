import 'package:flutter_kiwi_nlp/src/kiwi_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KiwiToken.fromJson', () {
    test('parses values and numeric conversions', () {
      final KiwiToken token = KiwiToken.fromJson(<String, dynamic>{
        'form': '안녕',
        'tag': 'NNG',
        'start': 3.9,
        'length': 2,
        'wordPosition': 1.2,
        'sentPosition': 0,
        'score': 0.75,
        'typoCost': 1,
      });

      expect(token.form, '안녕');
      expect(token.tag, 'NNG');
      expect(token.start, 3);
      expect(token.length, 2);
      expect(token.wordPosition, 1);
      expect(token.sentPosition, 0);
      expect(token.score, 0.75);
      expect(token.typoCost, 1.0);
    });

    test('falls back to defaults when keys are missing', () {
      final KiwiToken token = KiwiToken.fromJson(<String, dynamic>{});

      expect(token.form, '');
      expect(token.tag, 'UNK');
      expect(token.start, 0);
      expect(token.length, 0);
      expect(token.wordPosition, 0);
      expect(token.sentPosition, 0);
      expect(token.score, 0.0);
      expect(token.typoCost, 0.0);
    });
  });

  group('KiwiCandidate.fromJson', () {
    test('parses candidate with immutable token list', () {
      final KiwiCandidate candidate = KiwiCandidate.fromJson(<String, dynamic>{
        'probability': 0.42,
        'tokens': <Map<String, dynamic>>[
          <String, dynamic>{
            'form': '테스트',
            'tag': 'NNG',
            'start': 0,
            'length': 3,
            'wordPosition': 0,
            'sentPosition': 0,
            'score': 0.1,
            'typoCost': 0.0,
          },
        ],
      });

      expect(candidate.probability, 0.42);
      expect(candidate.tokens, hasLength(1));
      expect(candidate.tokens.first.form, '테스트');
      expect(
        () => candidate.tokens.add(
          const KiwiToken(
            form: '추가',
            tag: 'NNG',
            start: 0,
            length: 1,
            wordPosition: 0,
            sentPosition: 0,
            score: 0.0,
            typoCost: 0.0,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('uses defaults for missing fields', () {
      final KiwiCandidate candidate = KiwiCandidate.fromJson(
        <String, dynamic>{},
      );

      expect(candidate.probability, 0.0);
      expect(candidate.tokens, isEmpty);
    });
  });

  group('KiwiAnalyzeResult.fromJson', () {
    test('parses nested candidates', () {
      final KiwiAnalyzeResult result = KiwiAnalyzeResult.fromJson(
        <String, dynamic>{
          'candidates': <Map<String, dynamic>>[
            <String, dynamic>{
              'probability': 0.9,
              'tokens': <Map<String, dynamic>>[
                <String, dynamic>{
                  'form': '안녕',
                  'tag': 'IC',
                  'start': 0,
                  'length': 2,
                  'wordPosition': 0,
                  'sentPosition': 0,
                  'score': 0.0,
                  'typoCost': 0.0,
                },
              ],
            },
          ],
        },
      );

      expect(result.candidates, hasLength(1));
      expect(result.candidates.first.probability, 0.9);
      expect(result.candidates.first.tokens.first.tag, 'IC');
    });

    test('uses empty list when candidates key is missing', () {
      final KiwiAnalyzeResult result = KiwiAnalyzeResult.fromJson(
        <String, dynamic>{},
      );

      expect(result.candidates, isEmpty);
    });
  });
}
