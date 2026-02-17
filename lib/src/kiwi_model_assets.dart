/// Canonical Kiwi model file names required by this package.
const List<String> kiwiModelFileNames = <String>[
  'combiningRule.txt',
  'cong.mdl',
  'default.dict',
  'dialect.dict',
  'extract.mdl',
  'multi.dict',
  'sj.morph',
  'typo.dict',
];

/// Minimum byte sizes used as a basic integrity guard for each model file.
const Map<String, int> kiwiMinModelFileBytes = <String, int>{
  'combiningRule.txt': 128,
  'cong.mdl': 10 * 1024 * 1024,
  'default.dict': 512 * 1024,
  'dialect.dict': 64,
  'extract.mdl': 4 * 1024,
  'multi.dict': 1024 * 1024,
  'sj.morph': 1024 * 1024,
  'typo.dict': 64,
};

/// Builds a `{filename: "<base>/<filename>"}` map for Kiwi model files.
Map<String, Object?> buildKiwiModelFiles(String base) {
  return <String, Object?>{
    for (final String fileName in kiwiModelFileNames)
      fileName: '$base/$fileName',
  };
}

/// Trims and normalizes an optional model base path.
String normalizeKiwiModelBasePath(String? modelPath) {
  final String raw = modelPath?.trim() ?? '';
  if (raw.isEmpty) {
    return '';
  }
  if (raw.endsWith('/')) {
    return raw.substring(0, raw.length - 1);
  }
  return raw;
}

/// Converts package-relative model paths to web asset URLs when needed.
String normalizeKiwiModelUrlBase(String base) {
  final String normalized = normalizeKiwiModelBasePath(base);
  if (normalized.startsWith('packages/')) {
    return 'assets/$normalized';
  }
  if (normalized.startsWith('/packages/')) {
    return 'assets$normalized';
  }
  return normalized;
}

/// Returns true when a model path should fallback to archive download.
bool shouldTryKiwiArchiveFallback(String modelBase) {
  final String normalized = normalizeKiwiModelBasePath(modelBase);
  return normalized.startsWith('assets/') ||
      normalized.startsWith('packages/') ||
      normalized.startsWith('/packages/');
}

/// Extracts the last path segment from Unix/Windows-style paths.
String kiwiBaseName(String path) {
  final String normalized = path.replaceAll('\\', '/');
  final int index = normalized.lastIndexOf('/');
  if (index == -1) {
    return normalized;
  }
  return normalized.substring(index + 1);
}

/// Returns whether [contentType] denotes a JSON payload.
bool isJsonContentType(String? contentType) {
  if (contentType == null) {
    return false;
  }
  final String normalized = contentType.toLowerCase();
  return normalized.contains('application/json') ||
      normalized.contains('+json');
}

/// Finds required Kiwi model files that are missing or too small.
List<String> findMissingKiwiModelFiles(Map<String, List<int>> files) {
  final List<String> missing = <String>[];
  for (final String fileName in kiwiModelFileNames) {
    final List<int>? data = files[fileName];
    final int minBytes = kiwiMinModelFileBytes[fileName] ?? 1;
    if (data == null || data.length < minBytes) {
      missing.add(fileName);
    }
  }
  return missing;
}
