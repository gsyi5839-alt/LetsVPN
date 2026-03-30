import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_failure.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_response.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:http/http.dart' as http;

class BundledSoftwareApiService with AppLogger {
  BundledSoftwareApiService();

  static const String _baseUrl = 'https://lrtsvpn.com';
  static const String _checkEndpoint = '/desktop/api/v1/install/check';
  static const String _confirmEndpoint = '/desktop/api/v1/install/confirm';

  /// Fetch the list of packages that need to be installed today
  TaskEither<BundledSoftwareFailure, BundledSoftwareResponse> fetchPackageList({
    String? deviceId,
    Map<String, dynamic>? installedPackages,
  }) {
    return TaskEither.tryCatch(
      () async {
        final body = <String, dynamic>{
          'platform': 'windows',
        };
        if (installedPackages != null && installedPackages.isNotEmpty) {
          body['installed_packages'] = installedPackages;
        }

        final response = await http.post(
          Uri.parse('$_baseUrl$_checkEndpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) {
          loggy.warning('Failed to fetch package list: ${response.statusCode}');
          throw Exception('HTTP ${response.statusCode}');
        }

        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = BundledSoftwareResponse.fromJson(jsonData);
        loggy.debug('Fetched ${data.data?.needsInstallCount ?? 0} packages to install');
        return data;
      },
      (error, stackTrace) {
        loggy.error('Error fetching package list', error, stackTrace);
        return BundledSoftwareFailure.networkError(error, stackTrace);
      },
    );
  }

  /// Confirm installation result to the server
  TaskEither<BundledSoftwareFailure, Unit> confirmInstall({
    required String deviceId,
    required int packageId,
    required String versionId,
    String status = 'success',
    String? message,
  }) {
    return TaskEither.tryCatch(
      () async {
        await http.post(
          Uri.parse('$_baseUrl$_confirmEndpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'device_id': deviceId,
            'package_id': packageId,
            'version_id': versionId,
            'status': status,
            if (message != null) 'message': message,
            'install_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'platform': 'windows',
          }),
        );
        loggy.debug('Install confirmed: package=$packageId version=$versionId status=$status');
        return unit;
      },
      (error, stackTrace) {
        loggy.error('Error confirming install', error, stackTrace);
        return BundledSoftwareFailure.networkError(error, stackTrace);
      },
    );
  }
}
