import 'dart:convert';
import 'dart:ui';

import 'package:dartx/dartx.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/home/widget/windows_localized_strings.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _loginAccountWindowType = 'login-account';
const _countrySelectionWindowType = 'country-selection';

Future<bool> runDesktopSubWindowIfNeeded({required List<String> args, required Environment environment}) async {
  if (!PlatformUtils.isDesktop || args.firstOrNull != 'multi_window') {
    return false;
  }

  final windowId = int.tryParse(args.elementAtOrNull(1) ?? '');
  if (windowId == null) {
    return false;
  }

  final rawArguments = args.elementAtOrNull(2);
  try {
    final windowArguments = _decodeWindowArguments(rawArguments);
    final windowType = windowArguments['type'] as String?;

    if (windowType == _loginAccountWindowType) {
      final container = await _createDesktopSubWindowContainer(environment: environment);
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: _LoginAccountWindow(windowId: windowId),
        ),
      );
      return true;
    }

    if (windowType == _countrySelectionWindowType) {
      final container = await _createDesktopSubWindowContainer(environment: environment);
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: _CountrySelectionWindow(windowId: windowId),
        ),
      );
      return true;
    }

    final locale = PlatformDispatcher.instance.locale;
    _runSubWindowFallbackApp(
      title: windowsText(locale, 'desktop.subWindowLoadFailed'),
      message: windowsText(locale, 'desktop.unknownSubWindow', params: {'value': windowType ?? 'null'}),
    );
  } catch (error, stackTrace) {
    debugPrint('desktop sub window init failed: $error');
    debugPrint('$stackTrace');
    final locale = PlatformDispatcher.instance.locale;
    _runSubWindowFallbackApp(
      title: windowsText(locale, 'desktop.subWindowLoadFailed'),
      message: windowsText(locale, 'desktop.loginInitFailed'),
      details: '$error',
    );
  }
  return true;
}

Future<ProviderContainer> _createDesktopSubWindowContainer({required Environment environment}) async {
  final container = ProviderContainer(overrides: [environmentProvider.overrideWithValue(environment)]);
  await container.read(sharedPreferencesProvider.future);
  return container;
}

Map<String, dynamic> _decodeWindowArguments(String? rawArguments) {
  if (rawArguments == null || rawArguments.isBlank) {
    return const {};
  }

  try {
    dynamic decoded = jsonDecode(rawArguments);
    if (decoded is String && decoded.isNotBlank) {
      decoded = jsonDecode(decoded);
    }
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}

  return const {};
}

void _runSubWindowFallbackApp({required String title, required String message, String? details}) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFCC5F8F)),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      details,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _LoginAccountWindow extends StatelessWidget {
  const _LoginAccountWindow({required this.windowId});

  final int windowId;

  @override
  Widget build(BuildContext context) {
    final windowController = WindowController.fromWindowId(windowId);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFCC5F8F), brightness: Brightness.light),
      ),
      home: LoginAccountView(
        onClose: () async {
          await windowController.close();
        },
      ),
    );
  }
}

class _CountrySelectionWindow extends StatelessWidget {
  const _CountrySelectionWindow({required this.windowId});

  final int windowId;

  @override
  Widget build(BuildContext context) {
    final windowController = WindowController.fromWindowId(windowId);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFCC5F8F), brightness: Brightness.light),
      ),
      home: CountrySelectionView(
        onClose: () async {
          await windowController.close();
        },
      ),
    );
  }
}
