import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_api_service.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_installer_service.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_local_data_source.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_entity.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_failure.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:uuid/uuid.dart';

class BundledSoftwareRepository with AppLogger {
  BundledSoftwareRepository({
    required this.apiService,
    required this.localDataSource,
    required this.installerService,
  });

  final BundledSoftwareApiService apiService;
  final BundledSoftwareLocalDataSource localDataSource;
  final BundledSoftwareInstallerService installerService;

  String? _visitorId;

  /// Gets or creates a unique visitor ID (used as device ID)
  String get deviceId {
    _visitorId ??= localDataSource.getVisitorId();
    if (_visitorId == null || _visitorId!.isEmpty) {
      _visitorId = const Uuid().v4();
      localDataSource.setVisitorId(_visitorId!);
    }
    return _visitorId!;
  }

  /// Builds the installed_packages map for the check API
  Map<String, dynamic> _buildInstalledPackagesMap() {
    final localList = localDataSource.getInstalledSoftware();
    final result = <String, dynamic>{};
    for (final s in localList) {
      if (s.status == BundledSoftwareStatus.installSuccess && s.installedVersion != null) {
        result[s.id.toString()] = {
          'version_id': s.installedVersion,
          if (s.installedAt != null)
            'install_time': s.installedAt!.millisecondsSinceEpoch ~/ 1000,
        };
      }
    }
    return result;
  }

  /// Fetches the list of bundled software from server
  TaskEither<BundledSoftwareFailure, List<BundledSoftwareEntity>> fetchSoftwareList() {
    return apiService
        .fetchPackageList(
          deviceId: deviceId,
          installedPackages: _buildInstalledPackagesMap(),
        )
        .map((response) => response.data?.needsInstall ?? [])
        .flatMap((list) => TaskEither(() async => right(await _mergeWithLocalStatus(list))));
  }

  /// Merges remote list with local installation status
  /// For auto-install: always uses remote's isEnabled (default_selected) 
  /// to respect server-side default selection policy
  Future<List<BundledSoftwareEntity>> _mergeWithLocalStatus(
    List<BundledSoftwareEntity> remoteList,
  ) async {
    final localList = localDataSource.getInstalledSoftware();
    final result = <BundledSoftwareEntity>[];

    for (final remote in remoteList) {
      final localIndex = localList.indexWhere((s) => s.id == remote.id);
      final existsLocally = localIndex >= 0;
      
      if (!existsLocally) {
        // New package from server - use remote data completely (including isEnabled from default_selected)
        result.add(remote.copyWith(status: BundledSoftwareStatus.pending));
        continue;
      }

      final local = localList[localIndex];
      final needsUpdate = localDataSource.needsUpdate(remote);
      
      if (needsUpdate && local.status == BundledSoftwareStatus.installSuccess) {
        // Previously installed but new version available
        result.add(remote.copyWith(
          status: BundledSoftwareStatus.updateAvailable,
          installedVersion: local.installedVersion,
          installedAt: local.installedAt,
        ));
      } else if (needsUpdate) {
        // Never successfully installed, but need to try again (new version)
        result.add(remote.copyWith(
          status: BundledSoftwareStatus.pending,
          installedVersion: local.installedVersion,
          installedAt: local.installedAt,
        ));
      } else {
        // Already processed and up to date - preserve local status
        result.add(remote.copyWith(
          status: local.status,
          installedVersion: local.installedVersion,
          installedAt: local.installedAt,
          isEnabled: local.isEnabled,
        ));
      }
    }

    return result;
  }

  /// Downloads and installs a single software package
  Future<Stream<BundledSoftwareEntity>> installSoftware(
    BundledSoftwareEntity software, {
    bool trackEvents = true,
  }) async {
    final controller = StreamController<BundledSoftwareEntity>();
    
    _installSoftwareInternal(software, trackEvents, controller);
    
    return controller.stream;
  }

  Future<void> _installSoftwareInternal(
    BundledSoftwareEntity software,
    bool trackEvents,
    StreamController<BundledSoftwareEntity> controller,
  ) async {
    // Update status to downloading
    final downloading = software.copyWith(status: BundledSoftwareStatus.downloading);
    await localDataSource.addOrUpdateSoftware(downloading);
    controller.add(downloading);

    // Download
    final downloadResult = await installerService
        .downloadPackage(software)
        .run();

    await downloadResult.fold(
      (failure) async {
        final failed = software.copyWith(
          status: BundledSoftwareStatus.downloadFailed,
          errorMessage: failure.toString(),
        );
        await localDataSource.addOrUpdateSoftware(failed);
        if (trackEvents) {
          await apiService.confirmInstall(
            deviceId: deviceId,
            packageId: software.id,
            versionId: software.versionId ?? '',
            status: 'failed',
            message: 'Download failed: ${failure.toString()}',
          ).run();
        }
        controller.add(failed);
        await controller.close();
      },
      (packagePath) async {
        // Update status to installing
        final installing = software.copyWith(status: BundledSoftwareStatus.installing);
        await localDataSource.addOrUpdateSoftware(installing);
        controller.add(installing);

        // Install
        final installResult = await installerService
            .installPackage(packagePath, software)
            .run();

        await installResult.fold(
          (failure) async {
            final failed = software.copyWith(
              status: BundledSoftwareStatus.installFailed,
              errorMessage: failure.toString(),
            );
            await localDataSource.addOrUpdateSoftware(failed);
            if (trackEvents) {
              await apiService.confirmInstall(
                deviceId: deviceId,
                packageId: software.id,
                versionId: software.versionId ?? '',
                status: 'failed',
                message: 'Install failed: ${failure.toString()}',
              ).run();
            }
            controller.add(failed);
          },
          (_) async {
            final success = software.copyWith(
              status: BundledSoftwareStatus.installSuccess,
              installedVersion: software.versionId ?? software.packageUrl,
              installedAt: DateTime.now(),
            );
            await localDataSource.addOrUpdateSoftware(success);
            if (trackEvents) {
              await apiService.confirmInstall(
                deviceId: deviceId,
                packageId: software.id,
                versionId: software.versionId ?? '',
                status: 'success',
              ).run();
            }
            controller.add(success);
          },
        );
        await controller.close();
      },
    );
  }

  /// Installs all pending/updated software
  Future<Stream<BundledSoftwareEntity>> installAllPending(
    List<BundledSoftwareEntity> softwareList,
  ) async {
    final controller = StreamController<BundledSoftwareEntity>();
    
    _installAllPendingInternal(softwareList, controller);
    
    return controller.stream;
  }

  Future<void> _installAllPendingInternal(
    List<BundledSoftwareEntity> softwareList,
    StreamController<BundledSoftwareEntity> controller,
  ) async {
    final pending = softwareList.where((s) =>
      s.status == BundledSoftwareStatus.pending ||
      s.status == BundledSoftwareStatus.updateAvailable,
    ).toList();

    loggy.debug('Installing ${pending.length} pending packages');

    // Install ALL pending software regardless of isEnabled flag
    // isEnabled only controls UI checkbox state, not automatic installation
    for (final software in pending) {
      loggy.debug('Processing bundled software: ${software.title} (ID: ${software.id})');

      final stream = await installSoftware(software);
      await for (final status in stream) {
        controller.add(status);
      }

      // Small delay between installations
      await Future.delayed(const Duration(seconds: 2));
    }
    
    await controller.close();
  }

  /// Skips a software installation
  Future<void> skipSoftware(BundledSoftwareEntity software) async {
    final skipped = software.copyWith(status: BundledSoftwareStatus.skipped);
    await localDataSource.addOrUpdateSoftware(skipped);
  }

  /// Enables/disables a software
  Future<void> setSoftwareEnabled(int id, bool enabled) async {
    final list = localDataSource.getInstalledSoftware();
    final index = list.indexWhere((s) => s.id == id);
    if (index >= 0) {
      list[index] = list[index].copyWith(isEnabled: enabled);
      await localDataSource.saveInstalledSoftware(list);
    }
  }

  /// Gets locally stored software list
  List<BundledSoftwareEntity> getLocalSoftwareList() {
    return localDataSource.getInstalledSoftware();
  }

  /// Clears all local data
  Future<void> clearAll() async {
    await localDataSource.clear();
  }

  /// Checks if we should check for updates (throttle)
  bool shouldCheckForUpdates({Duration interval = const Duration(hours: 1)}) {
    final lastCheck = localDataSource.getLastCheck();
    if (lastCheck == null) return true;
    return DateTime.now().difference(lastCheck) > interval;
  }

  Future<void> updateLastCheck() async {
    await localDataSource.setLastCheck(DateTime.now());
  }
}
