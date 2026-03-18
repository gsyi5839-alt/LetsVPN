import 'dart:io';

import 'package:hiddify/utils/custom_loggers.dart';
import 'package:loggy/loggy.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class UriUtils {
  static final loggy = Loggy<InfraLogger>("UriUtils");

  static Future<bool> tryShareOrLaunchFile(Uri uri, {Uri? fileOrDir}) {
    if (Platform.isWindows || Platform.isLinux) {
      return tryLaunch(fileOrDir ?? uri);
    }
    return tryShareFile(uri);
  }

  static Future<bool> tryLaunch(Uri uri) async {
    try {
      loggy.debug("launching [$uri]");
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        return true;
      }
      loggy.warning("launchUrl returned false for [$uri], trying system fallback");
      return _tryLaunchWithSystemCommand(uri);
    } catch (e, stackTrace) {
      loggy.warning("error launching [$uri], trying system fallback", e, stackTrace);
      return _tryLaunchWithSystemCommand(uri);
    }
  }

  static Future<bool> _tryLaunchWithSystemCommand(Uri uri) async {
    final url = uri.toString();

    try {
      if (Platform.isWindows) {
        await Process.start('rundll32', ['url.dll,FileProtocolHandler', url], runInShell: true);
        return true;
      }

      if (Platform.isLinux) {
        await Process.start('xdg-open', [url], runInShell: true);
        return true;
      }

      if (Platform.isMacOS) {
        await Process.start('open', [url], runInShell: true);
        return true;
      }
    } catch (e, stackTrace) {
      loggy.warning("system fallback launch failed for [$uri]", e, stackTrace);
    }

    return false;
  }

  static Future<bool> tryShareFile(Uri uri, {String? mimeType}) async {
    try {
      loggy.debug("sharing [$uri]");
      final file = XFile(uri.path, mimeType: mimeType);
      final result = await Share.shareXFiles([file]);
      loggy.debug("share result: ${result.raw}");
      return result.status == ShareResultStatus.success;
    } catch (e, stackTrace) {
      loggy.warning("error sharing file [$uri]", e, stackTrace);
      return false;
    }
  }
}
