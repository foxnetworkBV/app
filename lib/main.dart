import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await runZonedGuarded<Future<void>>(() async {
    runApp(const FoxNetworkApp());
  }, (Object error, StackTrace stackTrace) {
    debugPrint('Uncaught startup error: $error');
    debugPrintStack(stackTrace: stackTrace);
  });
}
