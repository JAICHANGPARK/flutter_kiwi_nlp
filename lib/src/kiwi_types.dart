/// A token produced by Kiwi morphological analysis.
class KiwiToken {
  /// The surface form in the input text.
  final String form;

  /// The part-of-speech tag.
  final String tag;

  /// The start offset (in UTF-16 code units) in the input string.
  final int start;

  /// The token length (in UTF-16 code units).
  final int length;

  /// The word index for this token.
  final int wordPosition;

  /// The sentence index for this token.
  final int sentPosition;

  /// The token score from Kiwi.
  final double score;

  /// The typo normalization penalty for this token.
  final double typoCost;

  /// Creates a [KiwiToken].
  const KiwiToken({
    required this.form,
    required this.tag,
    required this.start,
    required this.length,
    required this.wordPosition,
    required this.sentPosition,
    required this.score,
    required this.typoCost,
  });

  /// Creates a token from a JSON-compatible map.
  factory KiwiToken.fromJson(Map<String, dynamic> json) {
    return KiwiToken(
      form: json['form'] as String? ?? '',
      tag: json['tag'] as String? ?? 'UNK',
      start: (json['start'] as num?)?.toInt() ?? 0,
      length: (json['length'] as num?)?.toInt() ?? 0,
      wordPosition: (json['wordPosition'] as num?)?.toInt() ?? 0,
      sentPosition: (json['sentPosition'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      typoCost: (json['typoCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// A candidate analysis path returned by Kiwi.
class KiwiCandidate {
  /// The candidate score or probability.
  final double probability;

  /// The token sequence for this candidate.
  final List<KiwiToken> tokens;

  /// Creates a [KiwiCandidate].
  const KiwiCandidate({required this.probability, required this.tokens});

  /// Creates a candidate from a JSON-compatible map.
  factory KiwiCandidate.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTokens =
        json['tokens'] as List<dynamic>? ?? const <dynamic>[];
    return KiwiCandidate(
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      tokens: rawTokens
          .map(
            (dynamic tokenJson) =>
                KiwiToken.fromJson(tokenJson as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

/// The top-level analysis result returned by `KiwiAnalyzer.analyze`.
class KiwiAnalyzeResult {
  /// Candidate analyses sorted by backend preference.
  final List<KiwiCandidate> candidates;

  /// Creates a [KiwiAnalyzeResult].
  const KiwiAnalyzeResult({required this.candidates});

  /// Creates an analysis result from a JSON-compatible map.
  factory KiwiAnalyzeResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawCandidates =
        json['candidates'] as List<dynamic>? ?? const <dynamic>[];
    return KiwiAnalyzeResult(
      candidates: rawCandidates
          .map(
            (dynamic candidateJson) =>
                KiwiCandidate.fromJson(candidateJson as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}
