class KiwiTokenCell {
  final String form;
  final String tag;

  const KiwiTokenCell({required this.form, required this.tag});

  String get joined => '$form/$tag';
}

class KiwiCandidateRow {
  final int rank;
  final double probability;
  final List<KiwiTokenCell> tokens;

  const KiwiCandidateRow({
    required this.rank,
    required this.probability,
    required this.tokens,
  });

  String get joined => tokens.isEmpty
      ? '(결과 없음)'
      : tokens.map((KiwiTokenCell token) => token.joined).join(' + ');
}

class KiwiResultRow {
  final int number;
  final String input;
  final List<KiwiCandidateRow> candidates;

  const KiwiResultRow({
    required this.number,
    required this.input,
    required this.candidates,
  });
}
