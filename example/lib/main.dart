import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'src/app.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[KiwiDemo][flutter] ${details.exception}');
    final StackTrace? stack = details.stack;
    if (stack != null) {
      debugPrintStack(label: '[KiwiDemo][flutter]', stackTrace: stack);
    }
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    debugPrint('[KiwiDemo][platform] $error');
    debugPrintStack(label: '[KiwiDemo][platform]', stackTrace: stackTrace);
    return false;
  };
  runZonedGuarded(() => runApp(const KiwiDemoApp()), (
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[KiwiDemo][zone] $error');
    debugPrintStack(label: '[KiwiDemo][zone]', stackTrace: stackTrace);
  });
}
