import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(details.exceptionAsString());
  };

  runZonedGuarded(() {
    runApp(const FoxNetworkApp());
  }, (Object error, StackTrace stackTrace) {
    debugPrint('FATAL: $error');
    debugPrintStack(stackTrace: stackTrace);
  });
}