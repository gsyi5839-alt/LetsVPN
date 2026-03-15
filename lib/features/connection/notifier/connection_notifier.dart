import 'dart:io';

import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/data/connection_repository.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'connection_notifier.g.dart';

typedef DesktopProxyContext = ({ServiceMode serviceMode, HiddifyCoreService coreService});

@Riverpod(keepAlive: true)
class ConnectionNotifier extends _$ConnectionNotifier with AppLogger {
  @override
  Stream<ConnectionStatus> build() async* {
    if (Platform.isIOS) {
      await _connectionRepo.setup().mapLeft((l) {
        loggy.error("error setting up connection repository", l);
      }).run();
    }

    listenSelf((previous, next) async {
      if (previous == next) return;
      if (previous case AsyncData(:final value) when !value.isConnected) {
        if (next case AsyncData(value: final Connected _)) {
          await ref.read(hapticServiceProvider.notifier).heavyImpact();

          if (Platform.isAndroid && !ref.read(Preferences.storeReviewedByUser)) {
            if (await InAppReview.instance.isAvailable()) {
              InAppReview.instance.requestReview();
              ref.read(Preferences.storeReviewedByUser.notifier).update(true);
            }
          }
        }
      }
    });

    ref.listen(activeProfileProvider.select((value) => value.asData?.value), (previous, next) async {
      if (previous == null) return;
      final shouldReconnect = next == null || previous.id != next.id;
      if (shouldReconnect) {
        await reconnect(next);
      }
    });
    ref.watch(coreRestartSignalProvider);

    yield* _connectionRepo.watchConnectionStatus().doOnData((event) {
      if (event case Disconnected(connectionFailure: final _?) when PlatformUtils.isDesktop) {
        ref.read(Preferences.startedByUser.notifier).update(false);
      }
      loggy.info("connection status: ${event.format()}");
    });
  }

  ConnectionRepository get _connectionRepo => ref.read(connectionRepositoryProvider);

  Future<void> mayConnect() async {
    if (state case AsyncData(:final value)) {
      if (value case Disconnected()) return _connect();
    }
  }

  Future<void> toggleConnection() async {
    final haptic = ref.read(hapticServiceProvider.notifier);
    if (state case AsyncError()) {
      await haptic.lightImpact();
      await _connect();
    } else if (state case AsyncData(:final value)) {
      switch (value) {
        case Disconnected():
          await haptic.lightImpact();
          await ref.read(Preferences.startedByUser.notifier).update(true);
          await _connect();
        case Connected():
          // default:
          await haptic.mediumImpact();
          await ref.read(Preferences.startedByUser.notifier).update(false);
          await _disconnect();
        default:
          loggy.warning("switching status, debounce");
      }
    } else {
      // Startup may temporarily keep the stream in loading state.
      // Treat this as disconnected so the first quick-connect tap still works.
      loggy.debug("connection state is loading, attempting to connect");
      await haptic.lightImpact();
      await ref.read(Preferences.startedByUser.notifier).update(true);
      await _connect();
    }
  }

  Future<void> reconnect(ProfileEntity? profile) async {
    if (state case AsyncData(:final value) when value == const Connected()) {
      if (profile == null) {
        loggy.info("no active profile, disconnecting");
        return _disconnect();
      }
      final connectableProfile = await _resolveConnectableProfile(profile);
      if (connectableProfile == null) {
        await _showMissingConfigAlert();
        return;
      }
      loggy.info("active profile changed, reconnecting");
      final desktopProxyContext = _captureDesktopProxyContext();
      await ref.read(Preferences.startedByUser.notifier).update(true);
      final reconnectResult = await _connectionRepo.reconnect(
        connectableProfile,
        ref.read(Preferences.disableMemoryLimit),
      ).run();
      await reconnectResult.match((err) async {
        loggy.warning("error reconnecting", err);
        state = AsyncError(err, StackTrace.current);
        await ref
            .read(dialogNotifierProvider.notifier)
            .showCustomAlertFromErr(err.present(ref.read(translationsProvider).requireValue));
      }, (_) async {
        await _ensureDesktopSystemProxyApplied(desktopProxyContext);
      });
    }
  }

  Future<void> abortConnection() async {
    if (state case AsyncData(:final value)) {
      switch (value) {
        case Connected() || Connecting():
          loggy.debug("aborting connection");
          await _disconnect();
        default:
      }
    }
  }

  final _singleStart = SingleCall();

  Future<void> _connect() async {
    _singleStart.run(
      () async {
        await _connectThrottled();
      },
      onIgnored: () {
        loggy.debug("connect called while another connect/disconnect is still running, ignoring");
      },
    );
  }

  Future<void> _connectThrottled() async {
    final desktopProxyContext = _captureDesktopProxyContext();
    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null) {
      loggy.info("no active profile, not connecting");
      return;
    }
    final connectableProfile = await _resolveConnectableProfile(activeProfile);
    if (connectableProfile == null) {
      await _showMissingConfigAlert();
      return;
    }
    final connectResult = await _connectionRepo.connect(
      connectableProfile,
      ref.read(Preferences.disableMemoryLimit),
    ).run();
    await connectResult.match((
      ConnectionFailure err,
    ) async {
      loggy.warning("error connecting", err);
      //Go err is not normal object to see the go errors are string and need to be dumped
      await ref
          .read(dialogNotifierProvider.notifier)
          .showCustomAlertFromErr(err.present(ref.read(translationsProvider).requireValue));
      loggy.warning(err);
      if (err.toString().contains("panic")) {
        await Sentry.captureException(Exception(err.toString()));
      }
      await ref.read(Preferences.startedByUser.notifier).update(false);
      state = AsyncError(err, StackTrace.current);
    }, (_) async {
      await _ensureDesktopSystemProxyApplied(desktopProxyContext);
    });
  }

  DesktopProxyContext? _captureDesktopProxyContext() {
    if (!PlatformUtils.isDesktop) {
      return null;
    }

    final serviceMode = ref.read(ConfigOptions.serviceMode);
    final coreService = ref.read(hiddifyCoreServiceProvider);
    return (serviceMode: serviceMode, coreService: coreService);
  }

  Future<void> _ensureDesktopSystemProxyApplied(DesktopProxyContext? desktopProxyContext) async {
    if (desktopProxyContext == null) {
      return;
    }

    if (desktopProxyContext.serviceMode == ServiceMode.tun) {
      return;
    }

    final coreService = desktopProxyContext.coreService;
    final statusResult = await coreService.getSystemProxyStatus().run();
    await statusResult.match((error) async {
      loggy.warning("failed to query system proxy status", error);
    }, (status) async {
      if (!status.available) {
        loggy.warning("system proxy is not available on current platform");
        return;
      }
      if (status.enabled) {
        return;
      }
      loggy.warning("system proxy is disabled while in system proxy mode, enabling it");
      final enableResult = await coreService.setSystemProxyEnabled(true).run();
      enableResult.match(
        (error) => loggy.warning("failed to enable system proxy", error),
        (_) => loggy.info("system proxy enabled successfully"),
      );
    });
  }

  Future<ProfileEntity?> _resolveConnectableProfile(ProfileEntity profile) async {
    final profileConfigFile = ref.read(profilePathResolverProvider).file(profile.id);
    final hasConfigFile = await profileConfigFile.exists();
    if (hasConfigFile) {
      return profile;
    }

    loggy.warning(
      "profile config is missing for profile ${profile.id}, attempting automatic recovery",
    );

    try {
      switch (profile) {
        case RemoteProfileEntity(:final url, :final userOverride):
          final profileRepository = await ref.read(profileRepositoryProvider.future);
          final recovered = await profileRepository
              .upsertRemote(url, userOverride: userOverride)
              .match((err) {
                loggy.warning("failed to recover remote profile config", err);
                return false;
              }, (_) => true)
            .run();
          if (!recovered) {
            return await _ensureSubscriptionAndUseActiveProfile();
          }
        case LocalProfileEntity():
          loggy.warning(
            "local profile config is missing, trying to recover from account subscription",
          );
          return await _ensureSubscriptionAndUseActiveProfile();
      }
    } catch (err, stackTrace) {
      loggy.error("unexpected error while recovering profile config", err, stackTrace);
      return await _ensureSubscriptionAndUseActiveProfile();
    }

    final refreshedActiveProfile = await _refreshAndGetActiveProfile();
    if (refreshedActiveProfile == null) {
      return await _switchToAnyAvailableProfileWithConfig();
    }
    final refreshedActiveConfigFile = ref.read(profilePathResolverProvider).file(refreshedActiveProfile.id);
    if (await refreshedActiveConfigFile.exists()) {
      return refreshedActiveProfile;
    }
    return await _switchToAnyAvailableProfileWithConfig();
  }

  Future<ProfileEntity?> _ensureSubscriptionAndUseActiveProfile() async {
    final ensured = await ref.read(authNotifierProvider.notifier).ensureSubscriptionProfileForCurrentUser();
    if (!ensured) {
      return await _switchToAnyAvailableProfileWithConfig();
    }
    final refreshedActiveProfile = await _refreshAndGetActiveProfile();
    if (refreshedActiveProfile == null) {
      return await _switchToAnyAvailableProfileWithConfig();
    }
    final refreshedActiveConfigFile = ref.read(profilePathResolverProvider).file(refreshedActiveProfile.id);
    if (await refreshedActiveConfigFile.exists()) {
      return refreshedActiveProfile;
    }
    return await _switchToAnyAvailableProfileWithConfig();
  }

  Future<ProfileEntity?> _switchToAnyAvailableProfileWithConfig() async {
    final profileRepository = await ref.read(profileRepositoryProvider.future);
    final profilesEither = await profileRepository.watchAll(
      sort: ProfilesSort.lastUpdate,
      sortMode: SortMode.descending,
    ).first;
    final profiles = profilesEither.getOrElse((_) => <ProfileEntity>[]);

    for (final profile in profiles) {
      final profileConfigFile = ref.read(profilePathResolverProvider).file(profile.id);
      final hasConfigFile = await profileConfigFile.exists();
      if (!hasConfigFile) {
        continue;
      }
      await profileRepository.setAsActive(profile.id).run();
      final refreshedActiveProfile = await _refreshAndGetActiveProfile();
      if (refreshedActiveProfile != null) {
        return refreshedActiveProfile;
      }
      return profile;
    }
    return null;
  }

  Future<ProfileEntity?> _refreshAndGetActiveProfile() async {
    ref.invalidate(activeProfileProvider);
    return await ref.read(activeProfileProvider.future);
  }

  Future<void> _showMissingConfigAlert() async {
    const message = '当前节点配置丢失，已自动尝试同步订阅与切换节点但仍失败，请重新登录后重试。';
    final err = ConnectionFailure.invalidConfig(message);
    await ref.read(Preferences.startedByUser.notifier).update(false);
    await ref
        .read(dialogNotifierProvider.notifier)
        .showCustomAlertFromErr(err.present(ref.read(translationsProvider).requireValue));
    state = AsyncError(err, StackTrace.current);
  }

  Future<void> _disconnect() async {
    await _connectionRepo.disconnect().mapLeft((err) {
      loggy.warning("error disconnecting", err);
      ref
          .read(dialogNotifierProvider.notifier)
          .showCustomAlertFromErr(err.present(ref.read(translationsProvider).requireValue));
      state = AsyncError(err, StackTrace.current);
    }).run();
  }
}

@Riverpod(keepAlive: true)
Future<bool> serviceRunning(Ref ref) async {
  // ref.watch(coreRestartSignalProvider);
  return await ref
      .watch(connectionNotifierProvider.selectAsync((data) => data.isConnected))
      .onError((error, stackTrace) => false);
}

class SingleCall {
  bool _running = false;

  Future<T> run<T>(Future<T> Function() task, {required T onIgnored}) async {
    if (_running) return onIgnored;

    _running = true;
    try {
      return await task();
    } finally {
      _running = false;
    }
  }
}
