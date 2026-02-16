class KiwiToken {
  final String form;
  final String tag;
  final int start;
  final int length;
  final int wordPosition;
  final int sentPosition;
  final double score;
  final double typoCost;

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

class KiwiCandidate {
  final double probability;
  final List<KiwiToken> tokens;

  const KiwiCandidate({required this.probability, required this.tokens});

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

class KiwiAnalyzeResult {
  final List<KiwiCandidate> candidates;

  const KiwiAnalyzeResult({required this.candidates});

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
