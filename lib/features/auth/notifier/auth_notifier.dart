import 'dart:convert';

import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/auth/data/auth_api_service.dart';
import 'package:hiddify/features/auth/model/auth_models.dart';
import 'package:hiddify/features/home/widget/windows_localized_strings.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthApiService 单例 Provider
final authApiServiceProvider = Provider<AuthApiService>((ref) => AuthApiService());

/// 控制登录后是否自动写入订阅配置（子窗口可关闭该行为）
final authAutoAddProfileProvider = Provider<bool>((ref) => true);

/// 认证状态管理 Notifier
///
/// 职责:
/// - 登录/注册
/// - Token 持久化 (SharedPreferences)
/// - 登录成功后自动添加 singbox 订阅为 Profile
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return AuthNotifier(prefs, ref);
});

class AuthNotifier extends StateNotifier<AuthState> with InfraLogger {
  final SharedPreferences _prefs;
  final Ref _ref;

  static const _tokenKey = 'auth_token';
  static const _accountKey = 'auth_account';
  static const _uuidKey = 'auth_uuid';

  AuthNotifier(this._prefs, this._ref) : super(const AuthState()) {
    refreshFromStorage();
  }

  AuthApiService get _api => _ref.read(authApiServiceProvider);

  void _applyAuthStateFromPreferences() {
    final token = _prefs.getString(_tokenKey);
    final account = _prefs.getString(_accountKey);
    final uuid = _prefs.getString(_uuidKey);
    if (token != null && token.isNotEmpty) {
      state = AuthState(isLoggedIn: true, token: token, account: account, uuid: uuid);
      return;
    }
    state = const AuthState();
  }

  /// 从 SharedPreferences 恢复登录状态
  void refreshFromStorage() {
    _applyAuthStateFromPreferences();
  }

  /// 验证存储的 Token 是否仍然有效，并确保订阅配置已加载
  Future<void> validateStoredToken() async {
    final token = _prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return; // 未登录状态，无需验证
    }

    loggy.debug('validating stored token...');
    final isValid = await _api.validateToken(token);
    
    if (!isValid) {
      loggy.warning('stored token is invalid or expired, clearing auth state');
      await _clearAuth();
      state = const AuthState();
    } else {
      loggy.debug('stored token is valid');
      // Token 有效，确保订阅配置已加载
      loggy.info('ensuring subscription profile for logged in user');
      await ensureSubscriptionProfileForCurrentUser();
    }
  }

  /// 强制从磁盘重新加载 SharedPreferences 后恢复登录状态
  Future<void> refreshFromStorageFromDisk() async {
    await _prefs.reload();
    _applyAuthStateFromPreferences();
  }

  /// 持久化保存认证信息
  Future<void> _saveAuth(AuthResult result) async {
    await _prefs.setString(_tokenKey, result.token);
    await _prefs.setString(_accountKey, result.user.account);
    await _prefs.setString(_uuidKey, result.user.uuid);
  }

  /// 清除认证信息
  Future<void> _clearAuth() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_accountKey);
    await _prefs.remove(_uuidKey);
  }

  /// 账号密码登录
  Future<bool> login(String account, String password) async {
    final locale = _ref.read(localePreferencesProvider).flutterLocale;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _api.login(account, password, fallbackErrorMessage: windowsText(locale, 'auth.loginFailed'));
      await _saveAuth(result);
      state = AuthState(isLoggedIn: true, token: result.token, account: result.user.account, uuid: result.user.uuid);
      // 登录成功后自动添加订阅
      if (_ref.read(authAutoAddProfileProvider)) {
        await _addSubscriptionProfile(result);
      }
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } on Exception catch (e) {
      loggy.error('login error', e);
      state = state.copyWith(isLoading: false, error: windowsText(locale, 'auth.networkError'));
      return false;
    }
  }

  /// 注册新账号
  Future<bool> register(String account, String password) async {
    final locale = _ref.read(localePreferencesProvider).flutterLocale;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _api.register(
        account,
        password,
        fallbackErrorMessage: windowsText(locale, 'auth.registerFailed'),
      );
      await _saveAuth(result);
      state = AuthState(isLoggedIn: true, token: result.token, account: result.user.account, uuid: result.user.uuid);
      // 注册成功后自动添加订阅
      if (_ref.read(authAutoAddProfileProvider)) {
        await _addSubscriptionProfile(result);
      }
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } on Exception catch (e) {
      loggy.error('register error', e);
      state = state.copyWith(isLoading: false, error: windowsText(locale, 'auth.networkError'));
      return false;
    }
  }

  /// 浏览器授权登录（按照设备码轮询流程）
  Future<bool> loginWithBrowserAuth() async {
    final locale = _ref.read(localePreferencesProvider).flutterLocale;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deviceAuthInfo = await _api.startDeviceAuth(
        fallbackErrorMessage: windowsText(locale, 'auth.deviceCodeFailed'),
      );
      final loginUri = Uri.tryParse(deviceAuthInfo.loginUrl);
      if (loginUri == null) {
        throw AuthException(windowsText(locale, 'auth.invalidLoginUrl'));
      }

      final opened = await UriUtils.tryLaunch(loginUri);
      if (!opened) {
        throw AuthException(windowsText(locale, 'auth.openBrowserFailed', params: {'value': deviceAuthInfo.loginUrl}));
      }

      final authorizationDeadline = DateTime.now().add(Duration(seconds: deviceAuthInfo.expiresIn));
      final pollIntervalSeconds = deviceAuthInfo.interval > 0 ? deviceAuthInfo.interval : 3;
      while (DateTime.now().isBefore(authorizationDeadline)) {
        final result = await _api.checkDeviceAuth(
          deviceAuthInfo.deviceCode,
          expiredErrorMessage: windowsText(locale, 'auth.authExpired'),
        );
        if (result != null) {
          await _saveAuth(result);
          state = AuthState(
            isLoggedIn: true,
            token: result.token,
            account: result.user.account,
            uuid: result.user.uuid,
          );
          if (_ref.read(authAutoAddProfileProvider)) {
            await _addSubscriptionProfile(result);
          }
          return true;
        }
        await Future.delayed(Duration(seconds: pollIntervalSeconds));
      }

      state = state.copyWith(isLoading: false, error: windowsText(locale, 'auth.timeout'));
      return false;
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
      return false;
    } on Exception catch (error) {
      loggy.error('browser auth error', error);
      final detail = error.toString().replaceFirst('Exception: ', '').trim();
      final message = detail.isEmpty
          ? windowsText(locale, 'auth.browserFailed')
          : windowsText(locale, 'auth.browserFailedDetail', params: {'value': detail});
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    await _clearAuth();
    state = const AuthState();
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith();
  }

  /// 登录/注册成功后，将 singbox 订阅 URL 添加为 Profile
  Future<void> _addSubscriptionProfile(AuthResult result) async {
    try {
      final profileEnsured = await _ensureSubscriptionProfile(token: result.token, account: result.user.account);
      if (!profileEnsured) {
        loggy.warning('failed to add subscription profile for current account');
      }
    } catch (e) {
      loggy.error('error adding subscription profile', e);
    }
  }

  /// 确保当前已登录账号的订阅已写入本地配置，便于一键快连直接使用。
  Future<bool> ensureSubscriptionProfileForCurrentUser() async {
    final token = state.token ?? _prefs.getString(_tokenKey);
    final account = state.account ?? _prefs.getString(_accountKey);
    final uuid = state.uuid ?? _prefs.getString(_uuidKey);

    if (token == null || token.isEmpty) {
      loggy.warning('ensure subscription skipped: auth token is empty');
      return false;
    }

    try {
      final profileEnsured = await _ensureSubscriptionProfile(token: token, account: account);
      if (profileEnsured && !state.isLoggedIn) {
        state = AuthState(isLoggedIn: true, token: token, account: account, uuid: uuid);
      }
      return profileEnsured;
    } catch (error) {
      loggy.error('error ensuring subscription profile', error);
      return false;
    }
  }

  Future<bool> _ensureSubscriptionProfile({required String token, String? account}) async {
    final subscribeUrl = _api.getSubscribeUrl(token);
    final userOverride = account != null && account.isNotEmpty ? UserOverride(name: account) : null;
    final profileRepository = await _ref.read(profileRepositoryProvider.future);

    loggy.info('ensuring subscription profile from url: $subscribeUrl');
    final remoteUpsertSuccess = await _tryUpsertRemoteProfile(
      profileRepository: profileRepository,
      subscribeUrl: subscribeUrl,
      userOverride: userOverride,
    );
    if (remoteUpsertSuccess) {
      await _preferRemoteProfileAsActive(profileRepository: profileRepository, subscribeUrl: subscribeUrl);
      return true;
    }

    loggy.warning('remote subscription profile is incompatible, trying normalized local import fallback');
    final localSingboxImportSuccess = await _tryImportNormalizedSingboxLocalProfile(
      profileRepository: profileRepository,
      token: token,
      userOverride: userOverride,
    );
    if (localSingboxImportSuccess) {
      await _preferRemoteProfileAsActive(profileRepository: profileRepository, subscribeUrl: subscribeUrl);
      return true;
    }

    loggy.warning('normalized sing-box local import failed, trying v2ray local import fallback');
    final v2rayLocalImportSuccess = await _tryImportV2rayLocalProfile(
      profileRepository: profileRepository,
      token: token,
      userOverride: userOverride,
    );
    if (v2rayLocalImportSuccess) {
      await _preferRemoteProfileAsActive(profileRepository: profileRepository, subscribeUrl: subscribeUrl);
    }
    return v2rayLocalImportSuccess;
  }

  Future<void> _preferRemoteProfileAsActive({
    required ProfileRepository profileRepository,
    required String subscribeUrl,
  }) async {
    try {
      final profilesEither = await profileRepository
          .watchAll(sort: ProfilesSort.lastUpdate, sortMode: SortMode.descending)
          .first;
      final profiles = profilesEither.getOrElse((_) => <ProfileEntity>[]);

      RemoteProfileEntity? matchedRemoteProfile;
      for (final profile in profiles) {
        if (profile is! RemoteProfileEntity) {
          continue;
        }
        final profileUrl = profile.url.trim();
        final isMatchedSubscriptionProfile = profileUrl == subscribeUrl || profileUrl.contains(subscribeUrl);
        if (!isMatchedSubscriptionProfile) {
          continue;
        }
        matchedRemoteProfile = profile;
        break;
      }

      if (matchedRemoteProfile == null) {
        return;
      }

      final profileConfigFile = _ref.read(profilePathResolverProvider).file(matchedRemoteProfile.id);
      if (!await profileConfigFile.exists()) {
        loggy.warning('matched remote subscription profile has no config file, keeping current active profile');
        return;
      }

      final setActiveResult = await profileRepository.setAsActive(matchedRemoteProfile.id).run();
      setActiveResult.match(
        (failure) {
          loggy.warning('failed to set remote profile as active after import', failure);
        },
        (_) {
          _ref.invalidate(activeProfileProvider);
        },
      );
    } catch (error, stackTrace) {
      loggy.warning('failed to prefer remote profile as active', error, stackTrace);
    }
  }

  Future<bool> _tryUpsertRemoteProfile({
    required ProfileRepository profileRepository,
    required String subscribeUrl,
    required UserOverride? userOverride,
  }) async {
    try {
      final upsertRemoteResult = await profileRepository.upsertRemote(subscribeUrl, userOverride: userOverride).run();
      return upsertRemoteResult.match(
        (failure) {
          loggy.warning('failed to upsert remote subscription profile: $failure');
          return false;
        },
        (_) {
          loggy.info('remote subscription profile added successfully');
          return true;
        },
      );
    } catch (error, stackTrace) {
      loggy.warning('remote subscription profile import threw exception', error, stackTrace);
      return false;
    }
  }

  Future<bool> _tryImportNormalizedSingboxLocalProfile({
    required ProfileRepository profileRepository,
    required String token,
    required UserOverride? userOverride,
  }) async {
    try {
      final subscribeContent = await _api.getSubscribeContent(token);
      if (subscribeContent.trim().isEmpty) {
        loggy.warning('fallback sing-box subscription content is empty');
        return false;
      }

      final normalizedSubscriptionContent = _normalizeSubscriptionForCurrentCore(subscribeContent);
      final addLocalResult = await profileRepository
          .addLocal(normalizedSubscriptionContent, userOverride: userOverride)
          .run();
      return addLocalResult.match(
        (failure) {
          loggy.warning('failed to add normalized local subscription profile: $failure');
          return false;
        },
        (_) {
          loggy.info('normalized local subscription profile added successfully');
          return true;
        },
      );
    } catch (error, stackTrace) {
      loggy.warning('normalized sing-box local import threw exception', error, stackTrace);
      return false;
    }
  }

  Future<bool> _tryImportV2rayLocalProfile({
    required ProfileRepository profileRepository,
    required String token,
    required UserOverride? userOverride,
  }) async {
    try {
      final v2rayContent = await _api.getSubscribeContent(token, type: 'v2ray');
      if (v2rayContent.trim().isEmpty) {
        loggy.warning('fallback v2ray subscription content is empty');
        return false;
      }

      final decodedV2rayContent = _decodeBase64OrKeepOriginal(v2rayContent);
      final addLocalResult = await profileRepository.addLocal(decodedV2rayContent, userOverride: userOverride).run();
      return addLocalResult.match(
        (failure) {
          loggy.warning('failed to add v2ray local subscription profile: $failure');
          return false;
        },
        (_) {
          loggy.info('v2ray local subscription profile added successfully');
          return true;
        },
      );
    } catch (error, stackTrace) {
      loggy.warning('v2ray local import threw exception', error, stackTrace);
      return false;
    }
  }

  String _normalizeSubscriptionForCurrentCore(String rawSubscriptionContent) {
    try {
      final decodedJson = jsonDecode(rawSubscriptionContent);
      if (decodedJson is! Map<String, dynamic>) {
        return rawSubscriptionContent;
      }

      final outbounds = decodedJson['outbounds'];
      if (outbounds is! List) {
        return rawSubscriptionContent;
      }

      int changedOutboundCount = 0;
      for (final outbound in outbounds) {
        if (outbound is! Map<String, dynamic>) {
          continue;
        }

        final transport = outbound['transport'];
        final shouldRemoveTcpTransport =
            (transport is String && transport == 'tcp') || (transport is Map && transport['type'] == 'tcp');

        if (shouldRemoveTcpTransport) {
          outbound.remove('transport');
          changedOutboundCount += 1;
        }
      }

      if (changedOutboundCount > 0) {
        loggy.info(
          'normalized sing-box subscription for compatibility, removed tcp transport from $changedOutboundCount outbounds',
        );
      }
      return jsonEncode(decodedJson);
    } catch (_) {
      // Keep original content when it's not JSON or when normalization is not needed.
      return rawSubscriptionContent;
    }
  }

  String _decodeBase64OrKeepOriginal(String rawContent) {
    try {
      return utf8.decode(base64.decode(rawContent.trim()));
    } catch (_) {
      return rawContent;
    }
  }
}
