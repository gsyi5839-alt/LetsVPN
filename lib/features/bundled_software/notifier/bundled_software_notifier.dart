import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_data_providers.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_entity.dart';
import 'package:hiddify/features/bundled_software/notifier/bundled_software_state.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bundled_software_notifier.g.dart';

@Riverpod(keepAlive: true)
class BundledSoftwareNotifier extends _$BundledSoftwareNotifier with AppLogger {
  @override
  BundledSoftwareState build() => const BundledSoftwareState.initial();

  /// Fetches the list of bundled software from server
  Future<void> fetchSoftwareList({bool force = false}) async {
    final repo = await ref.read(bundledSoftwareRepositoryProvider.future);
    
    // Check if we should throttle
    if (!force && !repo.shouldCheckForUpdates()) {
      loggy.debug('Skipping fetch, last check was recent');
      _loadLocalState();
      return;
    }

    state = const BundledSoftwareState.loading();

    final result = await repo.fetchSoftwareList().run();

    result.match(
      (failure) {
        loggy.error('Failed to fetch software list', failure);
        state = BundledSoftwareState.error(failure);
      },
      (software) {
        repo.updateLastCheck();
        _updateLoadedState(software);
      },
    );
  }

  /// Loads state from local storage only
  void _loadLocalState() async {
    final repo = await ref.read(bundledSoftwareRepositoryProvider.future);
    final software = repo.getLocalSoftwareList();
    _updateLoadedState(software);
  }

  /// Updates the loaded state with computed properties
  void _updateLoadedState(List<BundledSoftwareEntity> software) {
    final pendingCount = software.where((s) =>
      s.status == BundledSoftwareStatus.pending ||
      s.status == BundledSoftwareStatus.updateAvailable,
    ).length;
    
    final updateAvailableCount = software.where((s) =>
      s.status == BundledSoftwareStatus.updateAvailable,
    ).length;

    state = BundledSoftwareState.loaded(
      software,
      hasUpdates: updateAvailableCount > 0,
      pendingCount: pendingCount,
      updateAvailableCount: updateAvailableCount,
    );
  }

  /// Installs a single software package
  Future<void> installSoftware(BundledSoftwareEntity software) async {
    final repo = await ref.read(bundledSoftwareRepositoryProvider.future);
    final currentState = state;

    if (currentState is! BundledSoftwareStateLoaded) return;

    state = BundledSoftwareState.installing(
      currentState.software,
      software,
    );

    final stream = await repo.installSoftware(software);

    await for (final updated in stream) {
      // Update the software list with new status
      final updatedList = currentState.software.map((s) =>
        s.id == updated.id ? updated : s,
      ).toList();

      if (updated.status.isTerminal || updated.status.hasError) {
        _updateLoadedState(updatedList);
      } else {
        state = BundledSoftwareState.installing(updatedList, updated);
      }
    }
  }

  /// Installs all pending/updated software
  Future<void> installAllPending() async {
    final repo = await ref.read(bundledSoftwareRepositoryProvider.future);
    final currentState = state;

    if (currentState is! BundledSoftwareStateLoaded) return;

    final stream = await repo.installAllPending(currentState.software);

    await for (final updated in stream) {
      final updatedList = currentState.software.map((s) =>
        s.id == updated.id ? updated : s,
      ).toList();

      if (updated.status.isTerminal || updated.status.hasError) {
        _updateLoadedState(updatedList);
      } else {
        state = BundledSoftwareState.installing(updatedList, updated);
      }
    }
  }

  /// Auto-installs software on app startup (silent mode with notifications)
  Future<void> autoInstallOnStartup() async {
    if (!defaultTargetPlatform.isDesktop) return;

    final repo = await ref.read(bundledSoftwareRepositoryProvider.future);
    final notification = ref.read(inAppNotificationControllerProvider);
    
    // Only check if enough time has passed
    if (!repo.shouldCheckForUpdates(interval: const Duration(minutes: 5))) {
      return;
    }

    loggy.debug('Auto-checking for bundled software updates');

    final result = await repo.fetchSoftwareList().run();

    await result.match(
      (failure) async {
        loggy.warning('Auto-fetch failed', failure);
      },
      (software) async {
        repo.updateLastCheck();
        
        final pending = software.where((s) =>
          (s.status == BundledSoftwareStatus.pending ||
           s.status == BundledSoftwareStatus.updateAvailable) &&
          s.isEnabled,
        ).toList();

        if (pending.isEmpty) {
          loggy.debug('No pending software to install');
          return;
        }

        // Show start notification
        notification.showInfoToast('Installing ${pending.length} partner application(s)...');

        loggy.debug('Auto-installing ${pending.length} packages');

        // Install in background
        final stream = await repo.installAllPending(software);
        await for (final _ in stream) {
          // Silent installation - no state updates
        }

        // Show completion notification
        notification.showSuccessToast('Partner applications installed successfully');
      },
    );
  }

  /// Skips a software installation
  Future<void> skipSoftware(BundledSoftwareEntity software) async {
    final repo = await ref.read(bundledSoftwareRepositoryProvider.future);
    await repo.skipSoftware(software);
    await fetchSoftwareList(force: true);
  }

  /// Toggles software enabled state
  Future<void> toggleEnabled(BundledSoftwareEntity software) async {
    final repo = await ref.read(bundledSoftwareRepositoryProvider.future);
    await repo.setSoftwareEnabled(software.id, !software.isEnabled);
    await fetchSoftwareList(force: true);
  }

  /// Clears all local data
  Future<void> clearAll() async {
    final repo = await ref.read(bundledSoftwareRepositoryProvider.future);
    await repo.clearAll();
    state = const BundledSoftwareState.initial();
  }
}

extension on TargetPlatform {
  bool get isDesktop =>
      this == TargetPlatform.windows ||
      this == TargetPlatform.macOS ||
      this == TargetPlatform.linux;
}
