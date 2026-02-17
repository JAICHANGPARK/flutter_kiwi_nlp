import 'dart:io';

import 'package:flutter/services.dart';

Future<String?> materializeBenchmarkModelDirectory(
  String assetModelPath,
  List<String> fileNames,
) async {
  final String safeDirName = assetModelPath.replaceAll(
    RegExp(r'[^a-zA-Z0-9._-]'),
    '_',
  );
  final Directory cacheDir = Directory(
    '${Directory.systemTemp.path}/flutter_kiwi_nlp_bench_model/$safeDirName',
  );

  if (await _hasCompleteModelDirectory(cacheDir, fileNames)) {
    return cacheDir.path;
  }

  await cacheDir.create(recursive: true);
  for (final String fileName in fileNames) {
    final ByteData data = await rootBundle.load('$assetModelPath/$fileName');
    final Uint8List bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await File('${cacheDir.path}/$fileName').writeAsBytes(bytes, flush: true);
  }

  return cacheDir.path;
}

Future<bool> _hasCompleteModelDirectory(
  Directory directory,
  List<String> fileNames,
) async {
  if (!await directory.exists()) {
    return false;
  }

  for (final String fileName in fileNames) {
    final File file = File('${directory.path}/$fileName');
    if (!await file.exists()) {
      return false;
    }
    if (await file.length() <= 0) {
      return false;
    }
  }

  return true;
}
