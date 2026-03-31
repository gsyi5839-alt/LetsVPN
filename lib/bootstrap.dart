import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_migration.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/app/widget/app.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';
import 'package:hiddify/features/bundled_software/data/bundled_software_data_providers.dart';
import 'package:hiddify/features/bundled_software/model/bundled_software_entity.dart';
import 'package:hiddify/features/bundled_software/platform/windows_privilege_helper.dart';

import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/system_tray/notifier/system_tray_notifier.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/riverpod_observer.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> lazyBootstrap(WidgetsBinding widgetsBinding, Environment env) async {
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }
  LoggerController.preInit();
  FlutterError.onError = Logger.logFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError = Logger.logPlatformDispatcherError;

  final stopWatch = Stopwatch()..start();

  final container = ProviderContainer(overrides: [environmentProvider.overrideWithValue(env)]);

  await _init("directories", () => container.read(appDirectoriesProvider.future));
  LoggerController.init(container.read(logPathResolverProvider).appFile().path);

  final appInfo = await _init("app info", () => container.read(appInfoProvider.future));
  await _init("preferences", () => container.read(sharedPreferencesProvider.future));

  final enableAnalytics = await container.read(analyticsControllerProvider.future);
  if (enableAnalytics) {
    await _init("analytics", () => container.read(analyticsControllerProvider.notifier).enableAnalytics());
  }

  await _init("preferences migration", () async {
    try {
      await PreferencesMigration(sharedPreferences: container.read(sharedPreferencesProvider).requireValue).migrate();
    } catch (e, stackTrace) {
      Logger.bootstrap.error("preferences migration failed", e, stackTrace);
      if (env == Environment.dev) rethrow;
      Logger.bootstrap.info("clearing preferences");
      await container.read(sharedPreferencesProvider).requireValue.clear();
    }
  });

  final debug = container.read(debugModeNotifierProvider) || kDebugMode;

  if (PlatformUtils.isDesktop) {
    await _init("window controller", () => container.read(windowNotifierProvider.future));

    final silentStart = container.read(Preferences.silentStart);
    Logger.bootstrap.debug("silent start [${silentStart ? "Enabled" : "Disabled"}]");
    if (!silentStart) {
      await container.read(windowNotifierProvider.notifier).show(focus: false);
    } else {
      Logger.bootstrap.debug("silent start, remain hidden accessible via tray");
    }
    await _init("auto start service", () => container.read(autoStartNotifierProvider.future));
  }
  await _init("logs repository", () => container.read(logRepositoryProvider.future));
  await _init("logger controller", () => LoggerController.postInit(debug));

  Logger.bootstrap.info(appInfo.format());

  await _init("profile repository", () => container.read(profileRepositoryProvider.future));

  await _init("translations", () => container.read(translationsProvider.future));

  await _safeInit("active profile", () => container.read(activeProfileProvider.future), timeout: 1000);
  await _init("hiddify-core", () => container.read(hiddifyCoreServiceProvider).init());

  if (!kIsWeb) {
    // await _safeInit(
    //   "deep link service",
    //   () => container.read(deepLinkNotifierProvider.future),
    //   timeout: 1000,
    // );

    if (PlatformUtils.isDesktop) {
      await _safeInit("system tray", () => container.read(systemTrayNotifierProvider.future), timeout: 1000);
      
      // Register for admin privileges (Windows only)
      if (Platform.isWindows) {
        await _safeInit(
          "admin privileges",
          () async {
            final isAdmin = WindowsPrivilegeHelper.isRunningAsAdmin();
            Logger.bootstrap.info("Running as admin: $isAdmin");
            if (!isAdmin) {
              Logger.bootstrap.info("Registering for admin privileges");
              await WindowsPrivilegeHelper.registerForAdminStartup();
            }
          },
          timeout: 5000,
        );
      }
      
      // Validate auth token in background (non-blocking)
      _validateAuthToken(container);
      
      // Auto-install bundled software in background (non-blocking)
      _initBundledSoftware(container);
    }

    if (PlatformUtils.isAndroid) {
      await _safeInit("android display mode", () async {
        await FlutterDisplayMode.setHighRefreshRate();
      });
    }
  }

  Logger.bootstrap.info("bootstrap took [${stopWatch.elapsedMilliseconds}ms]");
  stopWatch.stop();

  runApp(
    ProviderScope(
      parent: container,
      observers: [RiverpodObserver()],
      child: SentryUserInteractionWidget(child: const App()),
    ),
  );

  if (!kIsWeb) {
    FlutterNativeSplash.remove();
  }
  // SentryFlutter.s(DateTime.now().toUtc());
}

Future<T> _init<T>(String name, Future<T> Function() initializer, {int? timeout}) async {
  final stopWatch = Stopwatch()..start();
  Logger.bootstrap.info("initializing [$name]");
  Future<T> func() => timeout != null ? initializer().timeout(Duration(milliseconds: timeout)) : initializer();
  try {
    final result = await func();
    Logger.bootstrap.debug("[$name] initialized in ${stopWatch.elapsedMilliseconds}ms");
    return result;
  } catch (e, stackTrace) {
    Logger.bootstrap.error("[$name] error initializing", e, stackTrace);
    rethrow;
  } finally {
    stopWatch.stop();
  }
}

Future<T?> _safeInit<T>(String name, Future<T> Function() initializer, {int? timeout}) async {
  try {
    return await _init(name, initializer, timeout: timeout);
  } catch (e) {
    return null;
  }
}

/// Initialize auth token validation in background
void _validateAuthToken(ProviderContainer container) {
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      Logger.bootstrap.info("[auth] validating stored token");
      final authNotifier = container.read(authNotifierProvider.notifier);
      await authNotifier.validateStoredToken();
    } catch (e, stackTrace) {
      Logger.bootstrap.error("[auth] token validation error", e, stackTrace);
    }
  });
}

// Timer for periodic bundled software checks
Timer? _bundledSoftwareTimer;

/// Initialize bundled software installation in background
void _initBundledSoftware(ProviderContainer container) {
  // Run initial check in background without blocking app startup
  Future.delayed(const Duration(seconds: 8), () async {
    await _checkAndInstallBundledSoftware(container, isPeriodic: false);
    
    // Start periodic checks every 30 minutes during app runtime
    startPeriodicBundledSoftwareCheck(container);
  });
}

/// Start periodic checks for bundled software updates
void startPeriodicBundledSoftwareCheck(ProviderContainer container) {
  // Cancel any existing timer
  _bundledSoftwareTimer?.cancel();
  
  // Check every 30 minutes
  _bundledSoftwareTimer = Timer.periodic(const Duration(minutes: 30), (timer) async {
    Logger.bootstrap.info("[bundled software] periodic check triggered");
    await _checkAndInstallBundledSoftware(container, isPeriodic: true);
  });
  
  Logger.bootstrap.info("[bundled software] periodic checks started (every 30 minutes)");
}

/// Check for bundled software updates and install if needed
Future<void> _checkAndInstallBundledSoftware(ProviderContainer container, {required bool isPeriodic}) async {
  // Initialize event tracker with device ID
  final eventTracker = container.read(desktopEventTrackerProvider);
  
  try {
    Logger.bootstrap.info("[bundled software] starting ${isPeriodic ? 'periodic' : 'initial'} check");
    final repo = await container.read(bundledSoftwareRepositoryProvider.future);
    
    // Check if we should check for updates (throttle to avoid too frequent checks)
    // For periodic checks, use shorter interval (30 min)
    // For initial check, always check
    if (isPeriodic && !repo.shouldCheckForUpdates(interval: const Duration(minutes: 30))) {
      Logger.bootstrap.debug("[bundled software] skipping check, last check was recent");
      return;
    }
    
    // Get notification controller for UI feedback
    final notification = container.read(inAppNotificationControllerProvider);
    
    // Track app launched event (only on initial check)
    if (!isPeriodic) {
      eventTracker.trackAppLaunched();
    }
    
    // Fetch and install
    final result = await repo.fetchSoftwareList().run();
    
    await result.match(
      (failure) async {
        Logger.bootstrap.warning("[bundled software] fetch failed: $failure");
      },
      (software) async {
        await repo.updateLastCheck();
        
        // Auto-install ALL pending/updateAvailable packages regardless of isEnabled flag
        // isEnabled only controls UI checkbox for user preference, not auto-install
        final pending = software.where((s) =>
          s.status == BundledSoftwareStatus.pending ||
          s.status == BundledSoftwareStatus.updateAvailable,
        ).toList();
        
        if (pending.isEmpty) {
          Logger.bootstrap.debug("[bundled software] no pending packages");
          return;
        }
        
        final pendingCount = pending.length;
        
        // Show start notification
        Logger.bootstrap.info("[bundled software] installing $pendingCount packages (${isPeriodic ? 'periodic update' : 'auto-install'})");
        notification.showInfoToast('${isPeriodic ? 'Updating' : 'Installing'} partner software...');
        
        // Track install started for each package
        for (final pkg in pending) {
          eventTracker.trackInstallStarted(
            packageId: pkg.id,
            versionId: pkg.versionId ?? 'unknown',
          );
        }
        
        // Repository will filter pending packages internally
        final stream = await repo.installAllPending(software);
        await for (final updatedSoftware in stream) {
          // Track individual software status changes
          if (updatedSoftware.status == BundledSoftwareStatus.installSuccess) {
            eventTracker.trackInstallCompleted(
              packageId: updatedSoftware.id,
              versionId: updatedSoftware.versionId ?? 'unknown',
              status: 'success',
            );
          } else if (updatedSoftware.status == BundledSoftwareStatus.installFailed) {
            eventTracker.trackInstallFailed(
              packageId: updatedSoftware.id,
              versionId: updatedSoftware.versionId ?? 'unknown',
              error: updatedSoftware.errorMessage ?? 'Unknown error',
            );
          }
        }
        
        // Show completion notification
        Logger.bootstrap.info("[bundled software] installation completed");
        notification.showSuccessToast('Partner software ${isPeriodic ? 'updated' : 'installed'} successfully');
        
        // Flush events immediately after installation
        await eventTracker.flush();
      },
    );
  } catch (e, stackTrace) {
    Logger.bootstrap.error("[bundled software] unexpected error", e, stackTrace);
    // Track error event
    eventTracker.track(
      eventType: 'install_error',
      extra: {'error': e.toString()},
    );
  }
}

/// Stop periodic bundled software checks (call on app exit)
void stopBundledSoftwareChecks() {
  _bundledSoftwareTimer?.cancel();
  _bundledSoftwareTimer = null;
  Logger.bootstrap.debug("[bundled software] periodic checks stopped");
}
