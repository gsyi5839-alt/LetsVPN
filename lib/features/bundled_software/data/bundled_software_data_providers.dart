import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_api_service.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_installer_service.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_local_data_source.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_repository.dart';
import 'package:hiddify/features/bundled_software/data/desktop_api_service.dart';
import 'package:hiddify/features/bundled_software/data/desktop_event_tracker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bundled_software_data_providers.g.dart';

// Legacy API service (kept for backward compatibility)
@Riverpod(keepAlive: true)
BundledSoftwareApiService bundledSoftwareApiService(BundledSoftwareApiServiceRef ref) {
  return BundledSoftwareApiService();
}

/// New Desktop API Service (recommended)
@Riverpod(keepAlive: true)
DesktopApiService desktopApiService(DesktopApiServiceRef ref) {
  return DesktopApiService();
}

/// Desktop Event Tracker for batch event reporting
@Riverpod(keepAlive: true)
DesktopEventTracker desktopEventTracker(DesktopEventTrackerRef ref) {
  final apiService = ref.watch(desktopApiServiceProvider);
  // TODO: Get deviceId, userId, clientVersion from appropriate providers
  final tracker = DesktopEventTracker(
    apiService: apiService,
    clientVersion: '4.1.2+40102',
  );
  tracker.start();
  return tracker;
}

@Riverpod(keepAlive: true)
Future<BundledSoftwareInstallerService> bundledSoftwareInstallerService(
  BundledSoftwareInstallerServiceRef ref,
) async {
  final dirs = await ref.watch(appDirectoriesProvider.future);
  return BundledSoftwareInstallerService(appDir: dirs);
}

@Riverpod(keepAlive: true)
Future<BundledSoftwareRepository> bundledSoftwareRepository(BundledSoftwareRepositoryRef ref) async {
  final installerService = await ref.watch(bundledSoftwareInstallerServiceProvider.future);
  return BundledSoftwareRepository(
    apiService: ref.watch(bundledSoftwareApiServiceProvider),
    localDataSource: ref.watch(bundledSoftwareLocalDataSourceProvider),
    installerService: installerService,
  );
}
