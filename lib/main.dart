import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:hiddify/bootstrap.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/desktop_sub_window.dart';

Future<void> main(List<String> args) async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // final widgetsBinding = SentryWidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
  );

  if (await runDesktopSubWindowIfNeeded(args: args, environment: Environment.dev)) {
    return;
  }

  return await lazyBootstrap(widgetsBinding, Environment.dev);
}
