import 'dart:convert';
import 'dart:math';

import 'package:dartx/dartx.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/features/auth/data/auth_api_service.dart';
import 'package:hiddify/features/auth/model/auth_models.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_sort_enum.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:window_manager/window_manager.dart';

String _formatDateTimeValue(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  static const Size _collapsedWindowSize = Size(300, 551);
  static const Size _expandedWindowSize = Size(460, 551);
  static const double _mainPanelWidth = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!PlatformUtils.isDesktop) {
      return const _DefaultHomePage();
    }
    if (PlatformUtils.isWindows) {
      return const _WindowsDesktopHomePage();
    }

    final appInfo = ref.watch(appInfoProvider).requireValue;
    final authState = ref.watch(authNotifierProvider);
    final connectionState = ref.watch(connectionNotifierProvider).valueOrNull ?? const Disconnected();
    final activeProfile = ref.watch(activeProfileProvider).valueOrNull;
    final sideMenuExpanded = useState<bool>(false);
    final now = DateTime.now();
    final expireAt = activeProfile?.mapOrNull(remote: (value) => value.subInfo?.expire);
    final hasFutureExpireAt = expireAt != null && expireAt.isAfter(now);
    final hasExpiredExpireAt = expireAt != null && !expireAt.isAfter(now);
    final shouldShowExpiredMembership = hasExpiredExpireAt && !authState.isLoggedIn;
    final remainMinutes = hasFutureExpireAt ? max(expireAt!.difference(now).inMinutes, 0) : 0;
    final countdownDigits = hasFutureExpireAt ? _buildCountdownDigits(remainMinutes) : const ['∞', '∞', '∞'];
    final memberHeaderTitle = hasFutureExpireAt
        ? '会员剩余时长'
        : (shouldShowExpiredMembership ? '会员已过期，剩余时长 🛒' : '免费会员，剩余时长');
    final memberTimeUnit = hasFutureExpireAt ? '分钟' : '不限';
    final memberExpireText = hasFutureExpireAt ? _formatDateTimeValue(expireAt!) : '不限时';
    final isDisconnected = connectionState is Disconnected || connectionState is Disconnecting;
    final statusText = switch (connectionState) {
      Connected() => 'VPN 已连接',
      Connecting() => 'VPN 连接中',
      Disconnecting() => 'VPN 断开中',
      _ => 'VPN 已断开连接',
    };
    final quickActionText = isDisconnected ? '开启快连' : '断开连接';
    final currentWindowSize = sideMenuExpanded.value ? _expandedWindowSize : _collapsedWindowSize;

    useEffect(() {
      if (!PlatformUtils.isDesktop) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await windowManager.setMinimumSize(_collapsedWindowSize);
        await windowManager.setSize(currentWindowSize);
      });
      return null;
    }, [sideMenuExpanded.value]);

    useEffect(() {
      if (!PlatformUtils.isDesktop) {
        return null;
      }
      DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
        if (call.method == 'auth-updated') {
          await ref.read(authNotifierProvider.notifier).refreshFromStorageFromDisk();
          return true;
        }
        return null;
      });
      return () => DesktopMultiWindow.setMethodHandler(null);
    }, const []);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              width: currentWindowSize.width,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: _mainPanelWidth,
                        child: ColoredBox(
                          color: const Color(0xFFF2F2F2),
                          child: Column(
                            children: [
                              const Gap(18),
                              _CountDownHeader(
                                digits: countdownDigits,
                                titleText: memberHeaderTitle,
                                unitText: memberTimeUnit,
                                expireAtText: memberExpireText,
                              ),
                              const Gap(22),
                              _ConnectionStatusBadge(connectionState: connectionState),
                              const Gap(16),
                              Text(
                                statusText,
                                style: const TextStyle(
                                  fontSize: 42 / 1.6,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF232429),
                                ),
                              ),
                              const Gap(10),
                              const Text(
                                '网络： 自动',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF3B3B3B)),
                              ),
                              const Gap(18),
                              SizedBox(
                                width: 230,
                                height: 40,
                                child: FilledButton(
                                  onPressed: () async {
                                    await _handleQuickAction(ref: ref, isDisconnected: isDisconnected);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFCC5F8F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                                  ),
                                  child: Text(
                                    quickActionText,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24 / 1.6),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Padding(
                                padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                                child: Row(
                                  children: [
                                    Text('🤡', style: TextStyle(fontSize: 15)),
                                    Gap(6),
                                    Text(
                                      '神秘礼物猫咪~',
                                      style: TextStyle(
                                        color: Color(0xFFD25586),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (sideMenuExpanded.value)
                        Expanded(
                          child: _RightDrawerPanel(
                            appInfoVersion: '${appInfo.version}(${appInfo.buildNumber})',
                            authState: authState,
                            onAccountTap: () => showLoginDialog(context),
                            onChangeRegion: () => showCountrySelectionDialog(context),
                            onRecommend: () => context.goNamed('referral'),
                            onClaimMembership: () => context.goNamed('freeMembership'),
                            onMessages: () => context.goNamed('messages'),
                            onMobileDownload: () => UriUtils.tryLaunch(
                              Uri.parse(
                                'https://www.interhelp.net/letsvpn-world/en/articles/2780068-%E5%A6%82%E4%BD%95%E4%B8%8B%E8%BD%BD%E5%BE%97%E5%88%B0%E5%BF%AB%E8%BF%9E-vpn',
                              ),
                            ),
                            onSupport: () => UriUtils.tryLaunch(
                              Uri.parse(
                                'https://www.interhelp.net/letsvpn-world/en/collections/1611781-%E4%B8%AD%E6%96%87%E5%B8%AE%E5%8A%A9',
                              ),
                            ),
                            onUploadLogs: () => _showUploadLogsDialog(context),
                            onRenew: () => UriUtils.tryLaunch(Uri.parse('https://www.palyps.com/account')),
                            onLogout: () async {
                              await ref.read(connectionNotifierProvider.notifier).abortConnection();
                              await ref.read(authNotifierProvider.notifier).logout();
                              ref.invalidate(activeProfileProvider);
                              ref.read(inAppNotificationControllerProvider).showSuccessToast('已退出账号');
                            },
                            onExit: () async => await ref.read(windowNotifierProvider.notifier).exit(),
                          ),
                        ),
                    ],
                  ),
                  Positioned(
                    left: _mainPanelWidth - 8 - 34,
                    bottom: 6,
                    child: _MenuHandleButton(
                      expanded: sideMenuExpanded.value,
                      onTap: () {
                        sideMenuExpanded.value = !sideMenuExpanded.value;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _buildCountdownDigits(int remainMinutes) {
    final minuteDigits = remainMinutes.clamp(0, 999).toString().padLeft(3, '0');
    return minuteDigits.split('');
  }

  Future<void> _handleQuickAction({required WidgetRef ref, required bool isDisconnected}) async {
    if (isDisconnected) {
      if (PlatformUtils.isDesktop) {
        final currentServiceMode = ref.read(ConfigOptions.serviceMode);
        if (currentServiceMode == ServiceMode.proxy) {
          await ref.read(ConfigOptions.serviceMode.notifier).update(ServiceMode.systemProxy);
        }
      }

      var activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile == null) {
        final ensured = await ref.read(authNotifierProvider.notifier).ensureSubscriptionProfileForCurrentUser();
        if (ensured) {
          ref.invalidate(activeProfileProvider);
          activeProfile = await ref.read(activeProfileProvider.future);
        }
      }

      if (activeProfile == null) {
        final profileRepository = await ref.read(profileRepositoryProvider.future);
        final profilesEither = await profileRepository
            .watchAll(sort: ProfilesSort.lastUpdate, sortMode: SortMode.descending)
            .first;
        final profiles = profilesEither.getOrElse((_) => <ProfileEntity>[]);

        if (profiles.isNotEmpty) {
          await profileRepository.setAsActive(profiles.first.id).run();
          ref.invalidate(activeProfileProvider);
          activeProfile = await ref.read(activeProfileProvider.future);
        }
      }

      if (activeProfile == null) {
        ref.read(inAppNotificationControllerProvider).showErrorToast('暂无可用节点，请先登录后同步订阅。');
        return;
      }

      await _connectWithDesktopFallback(ref);
      return;
    }

    await ref.read(connectionNotifierProvider.notifier).toggleConnection();
  }

  Future<void> _connectWithDesktopFallback(WidgetRef ref) async {
    final connectionNotifier = ref.read(connectionNotifierProvider.notifier);
    await connectionNotifier.toggleConnection();

    if (!PlatformUtils.isDesktop) {
      return;
    }

    final currentServiceMode = ref.read(ConfigOptions.serviceMode);
    if (currentServiceMode != ServiceMode.tun) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1300));

    final connectionSnapshot = ref.read(connectionNotifierProvider);
    final connectionState = connectionSnapshot.valueOrNull;
    final connectFailed = connectionSnapshot.hasError || connectionState is Disconnected;
    if (!connectFailed) {
      return;
    }

    await ref.read(ConfigOptions.serviceMode.notifier).update(ServiceMode.systemProxy);
    await Future.delayed(const Duration(milliseconds: 250));
    ref.read(inAppNotificationControllerProvider).showInfoToast('极速模式连接失败，已自动切换到安全模式重试。');
    await connectionNotifier.toggleConnection();

    await Future.delayed(const Duration(milliseconds: 1300));
    final retrySnapshot = ref.read(connectionNotifierProvider);
    final retryState = retrySnapshot.valueOrNull;
    final retryFailed = retrySnapshot.hasError || retryState is Disconnected;
    if (retryFailed) {
      ref.read(inAppNotificationControllerProvider).showErrorToast('连接失败，请切换国家节点或使用自动匹配最快网络。');
    }
  }
}

enum _WindowsMenuSection { home, region, referral, freeMembership, messages, settings }

class _WindowsDesktopHomePage extends HookConsumerWidget {
  const _WindowsDesktopHomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfo = ref.watch(appInfoProvider).requireValue;
    final authState = ref.watch(authNotifierProvider);
    final activeProfile = ref.watch(activeProfileProvider).valueOrNull;
    final connectionState = ref.watch(connectionNotifierProvider).valueOrNull ?? const Disconnected();
    final selectedSection = useState(_WindowsMenuSection.home);

    final selectedCountryIndex = (ref.watch(Preferences.selectedCountryIndex).clamp(0, _kCountries.length - 1)) as int;
    final selectedCountryName = _kCountries[selectedCountryIndex].$2;
    final serviceMode = ref.watch(ConfigOptions.serviceMode);
    final autoStartState = ref.watch(autoStartNotifierProvider);
    final sharedPrefs = ref.watch(sharedPreferencesProvider).requireValue;
    final persistedLocale = sharedPrefs.getString("locale");

    final now = DateTime.now();
    final expireAt = activeProfile?.mapOrNull(remote: (value) => value.subInfo?.expire);
    final hasFutureExpireAt = expireAt != null && expireAt.isAfter(now);
    final remainMinutes = hasFutureExpireAt ? max(expireAt!.difference(now).inMinutes, 0) : 0;
    final countdownDigits = hasFutureExpireAt
        ? remainMinutes.clamp(0, 9999).toString().padLeft(4, '0').split('')
        : const ['0', '0', '0', '0'];
    final memberHeaderTitle = hasFutureExpireAt ? '会员剩余时长(分钟)' : '会员已过期，剩余时长(分钟)';
    final memberExpireText = hasFutureExpireAt ? _formatDateTimeValue(expireAt!) : '不限时';

    final isDisconnected = connectionState is Disconnected || connectionState is Disconnecting;
    final statusText = switch (connectionState) {
      Connected() => 'VPN 已连接',
      Connecting() => 'VPN 连接中',
      Disconnecting() => 'VPN 断开中',
      _ => 'VPN 已断开连接',
    };
    final quickActionText = isDisconnected ? '开启快连' : '断开连接';

    final accountName = authState.account?.trim();
    final hasAccountName = accountName != null && accountName.isNotEmpty;
    final accountDisplayName = authState.isLoggedIn ? (hasAccountName ? accountName : '已登录账户') : '未登录账户';
    final accountId = authState.uuid?.trim().isNotEmpty == true ? authState.uuid!.trim() : '441337052';
    final localeDropdownValue =
        persistedLocale != null && AppLocale.values.any((locale) => locale.name == persistedLocale)
        ? persistedLocale
        : 'system';

    return Scaffold(
      backgroundColor: const Color(0xFFDCE2E8),
      body: SafeArea(
        child: Column(
          children: [
            _WindowsTitleBar(
              title: 'LetsVPN (ID: $accountId )',
              onToggleMenu: () {},
              onMinimize: () async => await windowManager.minimize(),
              onToggleMaximize: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              onClose: () async => await ref.read(windowNotifierProvider.notifier).exit(),
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 246,
                    color: const Color(0xFFB9C4CE),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF8D98A4), width: 4),
                                      color: const Color(0xFFCFD6DD),
                                    ),
                                    child: const Icon(Icons.person, size: 50, color: Color(0xFF9AA4AE)),
                                  ),
                                  const Gap(14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          accountDisplayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 34 / 1.6,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1F2328),
                                          ),
                                        ),
                                        const Gap(6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(999),
                                            color: Colors.white,
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.diamond_rounded, size: 13, color: Color(0xFF9BA5AF)),
                                              Gap(4),
                                              Text(
                                                '已过期',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF9BA5AF),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(12),
                              Text(
                                '到期时间: $memberExpireText',
                                style: const TextStyle(
                                  color: Color(0xFF1F2328),
                                  fontSize: 13 / 1.6 * 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0x44FFFFFF)),
                        _WindowsSidebarItem(
                          icon: Icons.home_outlined,
                          title: '首页',
                          selected: selectedSection.value == _WindowsMenuSection.home,
                          onTap: () => selectedSection.value = _WindowsMenuSection.home,
                        ),
                        _WindowsSidebarItem(
                          icon: Icons.public_rounded,
                          title: '变更国家和地区',
                          selected: selectedSection.value == _WindowsMenuSection.region,
                          onTap: () => selectedSection.value = _WindowsMenuSection.region,
                        ),
                        _WindowsSidebarItem(
                          icon: Icons.card_giftcard_outlined,
                          title: '推荐有奖',
                          selected: selectedSection.value == _WindowsMenuSection.referral,
                          showRedDot: true,
                          onTap: () => selectedSection.value = _WindowsMenuSection.referral,
                        ),
                        _WindowsSidebarItem(
                          icon: Icons.credit_card_outlined,
                          title: '免费领会员',
                          selected: selectedSection.value == _WindowsMenuSection.freeMembership,
                          onTap: () => selectedSection.value = _WindowsMenuSection.freeMembership,
                        ),
                        _WindowsSidebarItem(
                          icon: Icons.notifications_none_rounded,
                          title: '消息中心',
                          selected: selectedSection.value == _WindowsMenuSection.messages,
                          badgeText: '2',
                          onTap: () => selectedSection.value = _WindowsMenuSection.messages,
                        ),
                        _WindowsSidebarItem(
                          icon: Icons.settings_outlined,
                          title: '软件设置',
                          selected: selectedSection.value == _WindowsMenuSection.settings,
                          onTap: () => selectedSection.value = _WindowsMenuSection.settings,
                        ),
                        _WindowsSidebarItem(
                          icon: Icons.support_agent_outlined,
                          title: '在线客服',
                          selected: false,
                          onTap: () => UriUtils.tryLaunch(
                            Uri.parse(
                              'https://www.interhelp.net/letsvpn-world/en/collections/1611781-%E4%B8%AD%E6%96%87%E5%B8%AE%E5%8A%A9',
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: SizedBox(
                            height: 38,
                            child: FilledButton(
                              onPressed: () => UriUtils.tryLaunch(Uri.parse('https://www.palyps.com/account')),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1F69C9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                              ),
                              child: const Text(
                                '续费会员',
                                style: TextStyle(fontSize: 32 / 1.6, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const Gap(14),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(56, 0, 56, 20),
                          child: Row(
                            children: [
                              Text(
                                '版本号： ${appInfo.presentVersion}',
                                style: const TextStyle(color: Color(0xFF3A4148), fontSize: 14),
                              ),
                              const Spacer(),
                              const Icon(Icons.refresh_rounded, size: 19, color: Color(0xFF3A4148)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(34, 12, 34, 20),
                      child: switch (selectedSection.value) {
                        _WindowsMenuSection.home => _WindowsHomeSection(
                          countdownDigits: countdownDigits,
                          memberHeaderTitle: memberHeaderTitle,
                          connectionState: connectionState,
                          statusText: statusText,
                          selectedCountryName: selectedCountryName,
                          quickActionText: quickActionText,
                          onQuickAction: () async => await _handleQuickAction(ref: ref, isDisconnected: isDisconnected),
                        ),
                        _WindowsMenuSection.region => _WindowsRegionSection(
                          selectedIndex: selectedCountryIndex,
                          serviceMode: serviceMode,
                          onSelectCountry: (index) async => await _applyCountrySelection(ref, index),
                          onModeChanged: (mode) async =>
                              await ref.read(ConfigOptions.serviceMode.notifier).update(mode),
                        ),
                        _WindowsMenuSection.referral => _WindowsReferralSection(userId: accountId),
                        _WindowsMenuSection.freeMembership => const _WindowsFreeMembershipSection(),
                        _WindowsMenuSection.messages => const _WindowsMessagesSection(),
                        _WindowsMenuSection.settings => _WindowsSettingsSection(
                          autoStartEnabled: autoStartState.valueOrNull ?? false,
                          onAutoStartChanged: (enabled) async {
                            if (enabled) {
                              await ref.read(autoStartNotifierProvider.notifier).enable();
                            } else {
                              await ref.read(autoStartNotifierProvider.notifier).disable();
                            }
                          },
                          localeDropdownValue: localeDropdownValue,
                          onLocaleChanged: (value) async {
                            if (value == 'system') {
                              await sharedPrefs.remove("locale");
                              ref.invalidate(localePreferencesProvider);
                              return;
                            }
                            final locale = AppLocale.values.firstWhere(
                              (item) => item.name == value,
                              orElse: () => AppLocale.en,
                            );
                            await ref.read(localePreferencesProvider.notifier).changeLocale(locale);
                          },
                          currentVersion: appInfo.presentVersion,
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleQuickAction({required WidgetRef ref, required bool isDisconnected}) async {
    if (isDisconnected) {
      final currentServiceMode = ref.read(ConfigOptions.serviceMode);
      if (currentServiceMode == ServiceMode.proxy) {
        await ref.read(ConfigOptions.serviceMode.notifier).update(ServiceMode.systemProxy);
      }

      var activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile == null) {
        final ensured = await ref.read(authNotifierProvider.notifier).ensureSubscriptionProfileForCurrentUser();
        if (ensured) {
          ref.invalidate(activeProfileProvider);
          activeProfile = await ref.read(activeProfileProvider.future);
        }
      }

      if (activeProfile == null) {
        final profileRepository = await ref.read(profileRepositoryProvider.future);
        final profilesEither = await profileRepository
            .watchAll(sort: ProfilesSort.lastUpdate, sortMode: SortMode.descending)
            .first;
        final profiles = profilesEither.getOrElse((_) => <ProfileEntity>[]);

        if (profiles.isNotEmpty) {
          await profileRepository.setAsActive(profiles.first.id).run();
          ref.invalidate(activeProfileProvider);
          activeProfile = await ref.read(activeProfileProvider.future);
        }
      }

      if (activeProfile == null) {
        ref.read(inAppNotificationControllerProvider).showErrorToast('暂无可用节点，请先登录后同步订阅。');
        return;
      }

      await _connectWithDesktopFallback(ref);
      return;
    }

    await ref.read(connectionNotifierProvider.notifier).toggleConnection();
  }

  Future<void> _connectWithDesktopFallback(WidgetRef ref) async {
    final connectionNotifier = ref.read(connectionNotifierProvider.notifier);
    await connectionNotifier.toggleConnection();

    final currentServiceMode = ref.read(ConfigOptions.serviceMode);
    if (currentServiceMode != ServiceMode.tun) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1300));

    final connectionSnapshot = ref.read(connectionNotifierProvider);
    final connectionState = connectionSnapshot.valueOrNull;
    final connectFailed = connectionSnapshot.hasError || connectionState is Disconnected;
    if (!connectFailed) {
      return;
    }

    await ref.read(ConfigOptions.serviceMode.notifier).update(ServiceMode.systemProxy);
    await Future.delayed(const Duration(milliseconds: 250));
    ref.read(inAppNotificationControllerProvider).showInfoToast('极速模式连接失败，已自动切换到安全模式重试。');
    await connectionNotifier.toggleConnection();

    await Future.delayed(const Duration(milliseconds: 1300));
    final retrySnapshot = ref.read(connectionNotifierProvider);
    final retryState = retrySnapshot.valueOrNull;
    final retryFailed = retrySnapshot.hasError || retryState is Disconnected;
    if (retryFailed) {
      ref.read(inAppNotificationControllerProvider).showErrorToast('连接失败，请切换国家节点或使用自动匹配最快网络。');
    }
  }
}

class _WindowsTitleBar extends StatelessWidget {
  const _WindowsTitleBar({
    required this.title,
    required this.onToggleMenu,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
  });

  final String title;
  final VoidCallback onToggleMenu;
  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 34,
        color: const Color(0xFFDCE2E8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2328), fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: onToggleMenu,
              icon: const Icon(Icons.menu_rounded, size: 18, color: Color(0xFF646B73)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: onMinimize,
              icon: const Icon(Icons.remove_rounded, size: 18, color: Color(0xFF646B73)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: onToggleMaximize,
              icon: const Icon(Icons.open_in_full_rounded, size: 14, color: Color(0xFF646B73)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF646B73)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowsSidebarItem extends StatelessWidget {
  const _WindowsSidebarItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.badgeText,
    this.showRedDot = false,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final String? badgeText;
  final bool showRedDot;

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFF1B73DE);
    final textColor = selected ? selectedColor : const Color(0xFF1F2328);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: selected ? const Border(left: BorderSide(color: Color(0xFF1B73DE), width: 5)) : null,
          color: selected ? const Color(0xFFD6DEE6) : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 26 / 1.2, color: textColor),
                if (showRedDot)
                  const Positioned(
                    right: -4,
                    top: -3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFFF302A), shape: BoxShape.circle),
                      child: SizedBox(width: 7, height: 7),
                    ),
                  ),
              ],
            ),
            const Gap(16),
            Text(
              title,
              style: TextStyle(fontSize: 34 / 1.6, fontWeight: FontWeight.w500, color: textColor),
            ),
            if (badgeText != null) ...[
              const Gap(8),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: Color(0xFFFA1E1B), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  badgeText!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WindowsHomeSection extends StatelessWidget {
  const _WindowsHomeSection({
    required this.countdownDigits,
    required this.memberHeaderTitle,
    required this.connectionState,
    required this.statusText,
    required this.selectedCountryName,
    required this.quickActionText,
    required this.onQuickAction,
  });

  final List<String> countdownDigits;
  final String memberHeaderTitle;
  final ConnectionStatus connectionState;
  final String statusText;
  final String selectedCountryName;
  final String quickActionText;
  final VoidCallback onQuickAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '首页',
              style: TextStyle(fontSize: 54 / 1.6, fontWeight: FontWeight.w700, color: Color(0xFF15181C)),
            ),
            const Spacer(),
            Container(
              width: 330,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      '尊敬的老用户，欢迎回来。',
                      style: TextStyle(fontSize: 16 / 1.2, color: Color(0xFF2B2F33), fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.close_rounded, size: 20, color: Color(0xFF71767C)),
                ],
              ),
            ),
          ],
        ),
        const Gap(10),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                memberHeaderTitle,
                style: const TextStyle(fontSize: 18 / 1.4, color: Color(0xFF1F2328), fontWeight: FontWeight.w500),
              ),
              const Gap(8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final digit in countdownDigits)
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(left: 3),
                      color: const Color(0xFFD6DBE2),
                      alignment: Alignment.center,
                      child: Text(
                        digit,
                        style: const TextStyle(
                          fontSize: 24 / 1.4,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2328),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Center(
          child: SizedBox(
            width: 580,
            child: Row(
              children: [
                _ConnectionStatusBadge(connectionState: connectionState),
                const Gap(34),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 58 / 1.6,
                          color: Color(0xFF111418),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(14),
                      Text(
                        '网络： $selectedCountryName',
                        style: const TextStyle(
                          fontSize: 40 / 1.6,
                          color: Color(0xFF111418),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(26),
                      SizedBox(
                        width: 300,
                        height: 48,
                        child: FilledButton(
                          onPressed: onQuickAction,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD6568B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                          ),
                          child: Text(
                            quickActionText,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 42 / 1.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _WindowsRegionSection extends StatelessWidget {
  const _WindowsRegionSection({
    required this.selectedIndex,
    required this.serviceMode,
    required this.onSelectCountry,
    required this.onModeChanged,
  });

  final int selectedIndex;
  final ServiceMode serviceMode;
  final ValueChanged<int> onSelectCountry;
  final ValueChanged<ServiceMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final countryIndexByName = <String, int>{for (var i = 0; i < _kCountries.length; i++) _kCountries[i].$2: i};
    List<int> indicesOf(List<String> names) {
      return names.map((name) => countryIndexByName[name]).whereType<int>().toList();
    }

    final groups = <(String, List<int>)>[
      ('亚洲', indicesOf(const ['阿联酋', '香港', '印尼', '印度', '日本', '韩国', '澳门', '马来西亚', '菲律宾', '新加坡', '泰国', '台湾', '越南'])),
      ('欧洲', indicesOf(const ['瑞士', '德国', '西班牙', '法国', '爱尔兰', '意大利', '荷兰', '挪威', '波兰', '俄罗斯', '瑞典', '土耳其', '英国'])),
      ('非洲', indicesOf(const ['尼日利亚'])),
      ('大洋洲', indicesOf(const ['澳大利亚'])),
      ('北美洲', indicesOf(const ['加拿大', '墨西哥', '美国'])),
      ('南美洲', indicesOf(const ['阿根廷', '巴西'])),
    ];

    Widget buildCountryOptions(List<int> indexes) {
      return Wrap(
        spacing: 20,
        runSpacing: 4,
        children: [
          for (final countryIndex in indexes)
            SizedBox(
              width: 190,
              child: InkWell(
                onTap: () => onSelectCountry(countryIndex),
                child: Row(
                  children: [
                    Radio<int>(
                      value: countryIndex,
                      groupValue: selectedIndex,
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) => onSelectCountry(countryIndex),
                    ),
                    Text(
                      '${_kCountries[countryIndex].$1} ${_kCountries[countryIndex].$2}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '变更国家和地区',
          style: TextStyle(fontSize: 54 / 1.6, fontWeight: FontWeight.w700, color: Color(0xFF15181C)),
        ),
        const Gap(20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCCD2D9))),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '选择模式',
                      style: TextStyle(fontSize: 40 / 1.6, fontWeight: FontWeight.w600),
                    ),
                    const Gap(10),
                    RadioListTile<ServiceMode>(
                      dense: true,
                      value: ServiceMode.tun,
                      groupValue: serviceMode,
                      onChanged: (mode) => onModeChanged(mode ?? ServiceMode.tun),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('极速模式', style: TextStyle(fontSize: 18)),
                      subtitle: const Text('智能分流，仅代理需要翻墙的网络流量，不影响本地资源访问。', style: TextStyle(fontSize: 14)),
                    ),
                    RadioListTile<ServiceMode>(
                      dense: true,
                      value: ServiceMode.systemProxy,
                      groupValue: serviceMode,
                      onChanged: (mode) => onModeChanged(mode ?? ServiceMode.systemProxy),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('安全模式', style: TextStyle(fontSize: 18)),
                      subtitle: const Text('代理全部网络流量，改变 IP 地址，安全性极强。', style: TextStyle(fontSize: 14)),
                    ),
                    const Divider(height: 28),
                    const Text(
                      '选择网络',
                      style: TextStyle(fontSize: 40 / 1.6, fontWeight: FontWeight.w600),
                    ),
                    const Gap(6),
                    SizedBox(
                      width: 240,
                      child: InkWell(
                        onTap: () => onSelectCountry(0),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 0,
                              groupValue: selectedIndex,
                              visualDensity: VisualDensity.compact,
                              onChanged: (_) => onSelectCountry(0),
                            ),
                            const Text('🌐 自动匹配最快网络', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 22),
                    for (final (title, indexes) in groups) ...[
                      if (indexes.isNotEmpty) ...[
                        Text(
                          title,
                          style: const TextStyle(fontSize: 38 / 1.6, fontWeight: FontWeight.w500),
                        ),
                        const Gap(6),
                        buildCountryOptions(indexes),
                        const Divider(height: 22),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WindowsReferralSection extends StatelessWidget {
  const _WindowsReferralSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '推荐有奖',
          style: TextStyle(fontSize: 54 / 1.6, fontWeight: FontWeight.w700, color: Color(0xFF15181C)),
        ),
        const Gap(18),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 17 / 1.3, color: Color(0xFF1D2024), height: 1.8),
            children: [
              const TextSpan(text: '好友安装快连后，填写您的ID（'),
              TextSpan(
                text: userId,
                style: const TextStyle(color: Color(0xFF2457A6), fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '）即算推荐成功；\n当其每次获得会员，您均可赚取 '),
              const TextSpan(
                text: '20%',
                style: TextStyle(fontSize: 20, color: Color(0xFF2457A6), fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' 的时长！永久有效！'),
            ],
          ),
        ),
        const Gap(14),
        SizedBox(
          width: 300,
          height: 46,
          child: FilledButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: userId)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F69C9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            ),
            child: const Text(
              '推荐给好友',
              style: TextStyle(fontSize: 20 / 1.4, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const Gap(24),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: Column(
                  children: const [
                    _WindowsMetricCard(title: '成功推荐', value: '0人'),
                    Gap(12),
                    _WindowsMetricCard(title: '累计获得', value: '0小时'),
                    Gap(12),
                    _WindowsMetricCard(title: '累计白嫖', value: '0\$'),
                  ],
                ),
              ),
              const Gap(14),
              const Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFE6E6ED)),
                  child: Center(
                    child: Text(
                      '暂无推荐奖励记录，快去推荐好友吧！',
                      style: TextStyle(fontSize: 18 / 1.6, color: Color(0xFF999BA3)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WindowsMetricCard extends StatelessWidget {
  const _WindowsMetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFE6E6ED)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 20 / 1.5, color: Color(0xFF1D2024)),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(fontSize: 50 / 1.5, color: Color(0xFF1B73DE), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowsFreeMembershipSection extends StatelessWidget {
  const _WindowsFreeMembershipSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '免费领会员',
          style: TextStyle(fontSize: 54 / 1.6, fontWeight: FontWeight.w700, color: Color(0xFF15181C)),
        ),
        const Gap(18),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Container(
                    width: 220,
                    height: 160,
                    decoration: BoxDecoration(color: const Color(0xFFEDEFF5), borderRadius: BorderRadius.circular(80)),
                    child: const Icon(Icons.workspace_premium_rounded, size: 106, color: Color(0xFF5F95F8)),
                  ),
                  const Gap(16),
                  const Text(
                    '免费领会员',
                    style: TextStyle(fontSize: 58 / 1.8, fontWeight: FontWeight.w700),
                  ),
                  const Gap(8),
                  const Text(
                    '每天都来点一点，免费会员随便领！',
                    style: TextStyle(fontSize: 34 / 1.8, color: Color(0xFF2B2F34)),
                  ),
                  const Gap(16),
                  SizedBox(
                    width: 240,
                    height: 46,
                    child: FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F69C9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      ),
                      child: const Text(
                        '试试运气',
                        style: TextStyle(fontSize: 22 / 1.4, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const Gap(24),
                  Row(
                    children: const [
                      Expanded(
                        child: _WindowsStatPanel(title: '今日领取人数', value: '38094人'),
                      ),
                      Gap(20),
                      Expanded(
                        child: _WindowsStatPanel(title: '累计领取会员', value: '32554小时'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WindowsStatPanel extends StatelessWidget {
  const _WindowsStatPanel({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE6E6ED)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22 / 1.6, color: Color(0xFF1D2024)),
            ),
            const Gap(24),
            Text(
              value,
              style: const TextStyle(fontSize: 58 / 1.8, color: Color(0xFF1B73DE), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowsMessagesSection extends StatelessWidget {
  const _WindowsMessagesSection();

  @override
  Widget build(BuildContext context) {
    const messages = [
      ('搞定 Gemini 报错，看这篇就够了', 'Gemini 频繁报错、提示地区不支持？快连已完成专项优化，教你三招彻底告别这些抓狂时刻。'),
      ('保护您的快连 VPN 服务不被盗取', '请您认准官方渠道充值，并且妥善保管好您的订单号，这是快连 VPN 售后的唯一保障，千万不要将订单号泄露给其他人。'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '消息中心',
          style: TextStyle(fontSize: 54 / 1.6, fontWeight: FontWeight.w700, color: Color(0xFF15181C)),
        ),
        const Gap(18),
        Expanded(
          child: ListView.separated(
            itemCount: messages.length,
            separatorBuilder: (_, _) => const Gap(16),
            itemBuilder: (context, index) {
              final (title, body) = messages[index];
              return Container(
                decoration: const BoxDecoration(color: Color(0xFFEFEFF1)),
                padding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 8, height: 82, color: const Color(0xFF1B73DE)),
                    const Gap(12),
                    const Icon(Icons.info_rounded, color: Color(0xFF1B73DE), size: 32),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 21 / 1.5,
                              color: Color(0xFF171A1E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            body,
                            style: const TextStyle(fontSize: 17 / 1.5, color: Color(0xFF92969C), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xFFFF1D1D), shape: BoxShape.circle),
                        child: SizedBox(width: 8, height: 8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WindowsSettingsSection extends HookConsumerWidget {
  const _WindowsSettingsSection({
    required this.autoStartEnabled,
    required this.onAutoStartChanged,
    required this.localeDropdownValue,
    required this.onLocaleChanged,
    required this.currentVersion,
  });

  final bool autoStartEnabled;
  final ValueChanged<bool> onAutoStartChanged;
  final String localeDropdownValue;
  final ValueChanged<String> onLocaleChanged;
  final String currentVersion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeOptions = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(value: 'system', child: Text('跟随系统')),
      ...AppLocale.values.map((locale) => DropdownMenuItem<String>(value: locale.name, child: Text(locale.localeName))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '软件设置',
          style: TextStyle(fontSize: 54 / 1.6, fontWeight: FontWeight.w700, color: Color(0xFF15181C)),
        ),
        const Gap(20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCCD2D9))),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: ListView(
              children: [
                const Text(
                  '开机启动',
                  style: TextStyle(fontSize: 42 / 1.6, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text('系统占用资源较少，建议开启开机自动启动。', style: TextStyle(fontSize: 16, color: Color(0xFF1F2328))),
                    ),
                    Switch.adaptive(value: autoStartEnabled, onChanged: onAutoStartChanged),
                    const Text('开启', style: TextStyle(fontSize: 18, color: Color(0xFF1F2328))),
                  ],
                ),
                const Divider(height: 28),
                const Text(
                  '显示语言',
                  style: TextStyle(fontSize: 42 / 1.6, fontWeight: FontWeight.w600),
                ),
                const Gap(10),
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<String>(
                    value: localeDropdownValue,
                    items: localeOptions,
                    onChanged: (value) {
                      if (value != null) {
                        onLocaleChanged(value);
                      }
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const Divider(height: 28),
                const Text(
                  '关于我们',
                  style: TextStyle(fontSize: 42 / 1.6, fontWeight: FontWeight.w600),
                ),
                const Gap(10),
                Row(
                  children: [
                    Text('当前版本： $currentVersion', style: const TextStyle(fontSize: 18, color: Color(0xFF1F2328))),
                    const Gap(36),
                    InkWell(
                      onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.appCastUrl)),
                      child: const Text(
                        '检查更新',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF1B73DE),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF1B73DE),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                InkWell(
                  onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.privacyPolicyUrl)),
                  child: const Text('隐私协议', style: TextStyle(fontSize: 18, color: Color(0xFF1B73DE))),
                ),
                const Gap(8),
                InkWell(
                  onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.termsAndConditionsUrl)),
                  child: const Text('服务条款', style: TextStyle(fontSize: 18, color: Color(0xFF1B73DE))),
                ),
                const Gap(8),
                const Text('版权所有 © LetsVPN 团队', style: TextStyle(fontSize: 18, color: Color(0xFF1F2328))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DefaultHomePage extends HookConsumerWidget {
  const _DefaultHomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Assets.images.logo.svg(height: 24),
            const Gap(8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: t.common.appTitle),
                  const TextSpan(text: ' '),
                  const WidgetSpan(child: _DefaultAppVersionLabel(), alignment: PlaceholderAlignment.middle),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            key: const ValueKey('profile_quick_settings'),
            label: t.pages.home.quickSettings,
            child: IconButton(
              icon: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
              onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
            ),
          ),
          const Gap(8),
          Semantics(
            key: const ValueKey('profile_add_button'),
            label: t.pages.profiles.add,
            child: IconButton(
              icon: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
              onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
            ),
          ),
          const Gap(8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/world_map.png'),
            fit: BoxFit.cover,
            opacity: 0.09,
            colorFilter: theme.brightness == Brightness.dark
                ? ColorFilter.mode(Colors.white.withValues(alpha: .15), BlendMode.srcIn)
                : ColorFilter.mode(Colors.grey.withValues(alpha: 1), BlendMode.srcATop),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: CustomScrollView(
                  slivers: [
                    MultiSliver(
                      children: [
                        switch (activeProfile) {
                          AsyncData(value: final profile?) => ProfileTile(
                            profile: profile,
                            isMain: true,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Theme.of(context).colorScheme.surfaceContainer,
                          ),
                          _ => const Text(''),
                        },
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [ConnectionButton(), ActiveProxyDelayIndicator()],
                                ),
                              ),
                              ActiveProxyFooter(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultAppVersionLabel extends HookConsumerWidget {
  const _DefaultAppVersionLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.common.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}

class _CountDownHeader extends StatelessWidget {
  const _CountDownHeader({
    required this.digits,
    required this.titleText,
    required this.unitText,
    required this.expireAtText,
  });

  final List<String> digits;
  final String titleText;
  final String unitText;
  final String expireAtText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          titleText,
          style: const TextStyle(color: Color(0xFFCD5F8F), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const Gap(6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final digit in digits) ...[
              Container(
                width: 30,
                height: 36,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  border: Border.all(color: const Color(0xFFCFCFCF)),
                ),
                child: Text(
                  digit,
                  style: const TextStyle(fontSize: 30 / 1.6, fontWeight: FontWeight.w700, color: Color(0xFF2A2A2A)),
                ),
              ),
            ],
            const Gap(6),
            Text(
              unitText,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2A2A2A)),
            ),
          ],
        ),
        const Gap(8),
        Text(
          '到期时间: $expireAtText',
          style: const TextStyle(fontSize: 20 / 1.6, fontWeight: FontWeight.w500, color: Color(0xFF2A2A2A)),
        ),
      ],
    );
  }
}

class _ConnectionStatusBadge extends StatefulWidget {
  const _ConnectionStatusBadge({required this.connectionState});

  final ConnectionStatus connectionState;

  @override
  State<_ConnectionStatusBadge> createState() => _ConnectionStatusBadgeState();
}

class _ConnectionStatusBadgeState extends State<_ConnectionStatusBadge> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.connectionState is Connected;
    final isTransitioning = widget.connectionState is Connecting || widget.connectionState is Disconnecting;
    final isConnecting = widget.connectionState is Connecting;

    final Color outerRingColor;
    final Color innerRingColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;

    if (isConnected) {
      outerRingColor = const Color(0x22CF5F91);
      innerRingColor = const Color(0x33CF5F91);
      borderColor = const Color(0xFFCF5F91);
      iconColor = const Color(0xFFCF5F91);
      icon = Icons.link_rounded;
    } else if (isConnecting) {
      outerRingColor = const Color(0x22CC5F8F);
      innerRingColor = const Color(0x33CC5F8F);
      borderColor = const Color(0xFFCC5F8F);
      iconColor = const Color(0xFFCC5F8F);
      icon = Icons.sync_rounded;
    } else if (widget.connectionState is Disconnecting) {
      outerRingColor = const Color(0x22FF9800);
      innerRingColor = const Color(0x33FF9800);
      borderColor = const Color(0xFFFF9800);
      iconColor = const Color(0xFFFF9800);
      icon = Icons.sync_rounded;
    } else {
      outerRingColor = const Color(0x22CF5F91);
      innerRingColor = const Color(0x33CF5F91);
      borderColor = const Color(0xFFCF5F91);
      iconColor = const Color(0xFFCF5F91);
      icon = Icons.link_off_rounded;
    }

    Widget iconWidget = Icon(icon, color: iconColor, size: 56);
    if (isTransitioning) {
      iconWidget = RotationTransition(turns: _rotationController, child: iconWidget);
    }

    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外圈光源 - 沿圆形路径缓慢旋转
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final angle = -_glowController.value * 2 * pi;
              return Transform.translate(offset: Offset(7.0 * cos(angle), 7.0 * sin(angle)), child: child);
            },
            child: Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(shape: BoxShape.circle, color: outerRingColor),
            ),
          ),
          // 内圈 - 居中静止
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(shape: BoxShape.circle, color: innerRingColor),
          ),
          // 中心圆 + 图标
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(color: borderColor.withValues(alpha: .2), blurRadius: 16, offset: const Offset(0, 8)),
              ],
            ),
            child: iconWidget,
          ),
        ],
      ),
    );
  }
}

void _showUploadLogsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 260,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9B79F0), Color(0xFF5B9BF8)],
                  ),
                ),
                child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 32),
              ),
              const Gap(14),
              const Text(
                '上传日志',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
              const Gap(8),
              const Text(
                '请先和客服沟通后再上传日志，日志用于分析您在 APP 使用中遇到的问题。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
              ),
              const Gap(20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF333333),
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFCC5F8F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('上传日志'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showCountrySelectionDialog(BuildContext context) async {
  if (!context.mounted) {
    return;
  }

  if (PlatformUtils.isDesktop) {
    final window = await DesktopMultiWindow.createWindow(jsonEncode({'type': 'country-selection'}));
    await window.setFrame(Offset.zero & const Size(300, 500));
    await window.center();
    await window.setTitle('选择国家');
    if (PlatformUtils.isMacOS) {
      await window.resizable(false);
    }
    await window.show();
    return;
  }

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black26,
    builder: (ctx) => const _CountrySelectionDialog(),
  );
}

Future<void> showLoginDialog(BuildContext context) async {
  if (!context.mounted) {
    return;
  }

  if (PlatformUtils.isDesktop) {
    final window = await DesktopMultiWindow.createWindow(jsonEncode({'type': 'login-account'}));
    await window.setFrame(Offset.zero & const Size(700, 600));
    await window.center();
    await window.setTitle('登录账户');
    if (PlatformUtils.isMacOS) {
      await window.resizable(false);
    }
    await window.show();
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.none,
      child: const LoginAccountView(),
    ),
  );
}

class _MenuHandleButton extends StatelessWidget {
  const _MenuHandleButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: expanded ? '收起侧边栏' : '展开侧边栏',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_MenuLine(), Gap(3), _MenuLine(), Gap(3), _MenuLine()],
              ),
              Positioned(
                top: 4,
                right: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFFF3A2F), shape: BoxShape.circle),
                  child: SizedBox(width: 7, height: 7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuLine extends StatelessWidget {
  const _MenuLine();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFCC5F8F)),
      child: SizedBox(width: 20, height: 2),
    );
  }
}

class _RightDrawerPanel extends StatelessWidget {
  const _RightDrawerPanel({
    required this.appInfoVersion,
    required this.authState,
    required this.onAccountTap,
    required this.onChangeRegion,
    required this.onRecommend,
    required this.onClaimMembership,
    required this.onMessages,
    required this.onMobileDownload,
    required this.onSupport,
    required this.onUploadLogs,
    required this.onRenew,
    required this.onLogout,
    required this.onExit,
  });

  final String appInfoVersion;
  final AuthState authState;
  final VoidCallback onAccountTap;
  final VoidCallback onChangeRegion;
  final VoidCallback onRecommend;
  final VoidCallback onClaimMembership;
  final VoidCallback onMessages;
  final VoidCallback onMobileDownload;
  final VoidCallback onSupport;
  final VoidCallback onUploadLogs;
  final VoidCallback onRenew;
  final VoidCallback onLogout;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final accountName = authState.account?.trim();
    final hasAccountName = accountName != null && accountName.isNotEmpty;
    final accountDisplayName = authState.isLoggedIn ? (hasAccountName ? accountName : '已登录账户') : '未登录账户';

    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0x22888888))),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC0A068), Color(0xB89C8B74), Color(0xB69384AB), Color(0xB85A5A5A)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
        child: LayoutBuilder(
          builder: (context, constraints) => ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFABB8C5), width: 3),
                                  ),
                                  child: const Icon(Icons.person, size: 36, color: Color(0xFFABB8C5)),
                                ),
                                Positioned(
                                  bottom: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: authState.isLoggedIn ? const Color(0xFF28C840) : Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: authState.isLoggedIn ? const Color(0xFF28C840) : const Color(0xFFE3E3E3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          authState.isLoggedIn ? Icons.check_circle : Icons.diamond_outlined,
                                          size: 12,
                                          color: authState.isLoggedIn ? Colors.white : const Color(0xFF9EA4AA),
                                        ),
                                        const Gap(4),
                                        Text(
                                          authState.isLoggedIn ? '已登录' : '已过期',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700).copyWith(
                                            color: authState.isLoggedIn ? Colors.white : const Color(0xFF9EA4AA),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(18),
                            GestureDetector(
                              onTap: onAccountTap,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      accountDisplayName ?? '未登录账户',
                                      style: const TextStyle(
                                        fontSize: 26 / 1.6,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Gap(4),
                                    const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.black87),
                                  ],
                                ),
                              ),
                            ),
                            const Gap(8),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('ID: 333275276', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                Gap(4),
                                Icon(Icons.copy_rounded, size: 14, color: Colors.black87),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      _RightMenuItem(icon: Icons.public_rounded, title: '变更国家和地区', onTap: onChangeRegion),
                      _RightMenuItem(icon: Icons.card_giftcard_rounded, title: '推荐有奖', onTap: onRecommend),
                      _RightMenuItem(icon: Icons.card_membership_rounded, title: '免费领会员', onTap: onClaimMembership),
                      _RightMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: '消息中心',
                        badgeText: '2',
                        onTap: onMessages,
                      ),
                      _RightMenuItem(icon: Icons.link_rounded, title: '手机端下载', onTap: onMobileDownload),
                      _RightMenuItem(icon: Icons.support_agent_rounded, title: '在线客服', onTap: onSupport),
                      _RightMenuItem(icon: Icons.upload_file_rounded, title: '上传日志', onTap: onUploadLogs),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 30,
                        child: FilledButton(
                          onPressed: onRenew,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF121212),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: const BorderSide(color: Color(0xFFCC5F8F), width: 1.2),
                            ),
                          ),
                          child: const Text('续费会员', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      if (authState.isLoggedIn) ...[
                        const Gap(8),
                        SizedBox(
                          width: double.infinity,
                          height: 30,
                          child: FilledButton(
                            onPressed: onLogout,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF212121),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: const BorderSide(color: Color(0xFFD7D7D7), width: 1),
                              ),
                            ),
                            child: const Text('退出账号', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ],
                      const Gap(8),
                      SizedBox(
                        width: double.infinity,
                        height: 30,
                        child: FilledButton(
                          onPressed: onExit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD1D1D1),
                            foregroundColor: const Color(0xFF212121),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: const Text('退出程序', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const Gap(10),
                      Text('版本：$appInfoVersion', style: const TextStyle(fontSize: 12, color: Color(0xFF303030))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RightMenuItem extends StatelessWidget {
  const _RightMenuItem({required this.icon, required this.title, required this.onTap, this.badgeText});

  final IconData icon;
  final String title;
  final String? badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 33,
          child: Row(
            children: [
              Icon(icon, color: const Color(0x33555555), size: 20),
              const Gap(12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15 / 1.6 * 1.15,
                  color: Color(0xFF1B1B1B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badgeText != null) ...[
                const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: const BoxDecoration(color: Color(0xFFFE3B30), shape: BoxShape.circle),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 图3：变更国家/地区对话框 ────────────────────────────────────────────────

const _kCountries = [
  ('🌐', '自动匹配最快网络'),
  ('🇦🇷', '阿根廷'),
  ('🇮🇪', '爱尔兰'),
  ('🇦🇪', '阿联酋'),
  ('🇦🇺', '澳大利亚'),
  ('🇲🇴', '澳门'),
  ('🇧🇷', '巴西'),
  ('🇩🇪', '德国'),
  ('🇷🇺', '俄罗斯'),
  ('🇫🇷', '法国'),
  ('🇵🇭', '菲律宾'),
  ('🇰🇷', '韩国'),
  ('🇳🇱', '荷兰'),
  ('🇨🇦', '加拿大'),
  ('🇲🇾', '马来西亚'),
  ('🇺🇸', '美国'),
  ('🇲🇽', '墨西哥'),
  ('🇳🇬', '尼日利亚'),
  ('🇯🇵', '日本'),
  ('🇸🇪', '瑞典'),
  ('🇨🇭', '瑞士'),
  ('🇹🇭', '泰国'),
  ('🇹🇼', '台湾'),
  ('🇹🇷', '土耳其'),
  ('🇬🇧', '英国'),
  ('🇭🇰', '香港'),
  ('🇪🇸', '西班牙'),
  ('🇸🇬', '新加坡'),
  ('🇮🇹', '意大利'),
  ('🇮🇳', '印度'),
  ('🇮🇩', '印尼'),
  ('🇻🇳', '越南'),
  ('🇵🇱', '波兰'),
  ('🇳🇴', '挪威'),
];

Future<void> _applyCountrySelection(WidgetRef ref, int index) async {
  await ref.read(Preferences.selectedCountryIndex.notifier).update(index);

  final profileRepository = await ref.read(profileRepositoryProvider.future);
  final profilesEither = await profileRepository
      .watchAll(sort: ProfilesSort.lastUpdate, sortMode: SortMode.descending)
      .first;
  final profiles = profilesEither.getOrElse((_) => <ProfileEntity>[]);
  if (profiles.isEmpty) {
    ref.read(inAppNotificationControllerProvider).showErrorToast('暂无可用节点，请先登录并同步订阅。');
    return;
  }

  ProfileEntity? targetProfile;
  if (index == 0) {
    targetProfile = profiles.firstOrNull;
  } else {
    final countryName = _kCountries[index].$2;
    final countryFlag = _kCountries[index].$1;
    targetProfile = profiles.where((profile) => profile.name.contains(countryName)).firstOrNull;
    targetProfile ??= profiles.where((profile) => profile.name.contains(countryFlag)).firstOrNull;
  }
  targetProfile ??= profiles.firstOrNull;

  if (targetProfile == null) {
    return;
  }

  await profileRepository.setAsActive(targetProfile.id).run();
  ref.invalidate(activeProfileProvider);
  ref.read(inAppNotificationControllerProvider).showSuccessToast('已切换节点：${targetProfile.name}');
}

class _CountrySelectionDialog extends ConsumerStatefulWidget {
  const _CountrySelectionDialog();

  @override
  ConsumerState<_CountrySelectionDialog> createState() => _CountrySelectionDialogState();
}

class _CountrySelectionDialogState extends ConsumerState<_CountrySelectionDialog> {
  Offset _dragOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final serviceMode = ref.watch(ConfigOptions.serviceMode);
    final modeIndex = serviceMode == ServiceMode.tun ? 1 : 0;
    final persistedSelectedIndex = ref.watch(Preferences.selectedCountryIndex);
    final selectedIndex = persistedSelectedIndex.clamp(0, _kCountries.length - 1) as int;

    return Transform.translate(
      offset: _dragOffset,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: _CountrySelectionContent(
          selectedIndex: selectedIndex,
          modeIndex: modeIndex,
          onSelectCountry: (index) async {
            await _applyCountrySelection(ref, index);
          },
          onToggleMode: () async {
            final targetMode = modeIndex == 1 ? ServiceMode.systemProxy : ServiceMode.tun;
            await ref.read(ConfigOptions.serviceMode.notifier).update(targetMode);
          },
          onClose: () => Navigator.of(context).pop(),
          onDragUpdate: (details) => setState(() => _dragOffset += details.delta),
        ),
      ),
    );
  }
}

/// 独立窗口版国家选择视图，供桌面端 DesktopMultiWindow 使用
class CountrySelectionView extends ConsumerStatefulWidget {
  const CountrySelectionView({super.key, this.onClose});

  final Future<void> Function()? onClose;

  @override
  ConsumerState<CountrySelectionView> createState() => _CountrySelectionViewState();
}

class _CountrySelectionViewState extends ConsumerState<CountrySelectionView> {
  @override
  Widget build(BuildContext context) {
    final serviceMode = ref.watch(ConfigOptions.serviceMode);
    final modeIndex = serviceMode == ServiceMode.tun ? 1 : 0;
    final persistedSelectedIndex = ref.watch(Preferences.selectedCountryIndex);
    final selectedIndex = persistedSelectedIndex.clamp(0, _kCountries.length - 1) as int;

    return SizedBox(
      width: 300,
      height: 500,
      child: Material(
        color: const Color(0xFFF3F3F3),
        child: _CountrySelectionContent(
          selectedIndex: selectedIndex,
          modeIndex: modeIndex,
          onSelectCountry: (index) async {
            await _applyCountrySelection(ref, index);
          },
          onToggleMode: () async {
            final targetMode = modeIndex == 1 ? ServiceMode.systemProxy : ServiceMode.tun;
            await ref.read(ConfigOptions.serviceMode.notifier).update(targetMode);
          },
          onClose: () async {
            if (widget.onClose != null) {
              await widget.onClose!();
            } else if (mounted) {
              Navigator.of(context).pop();
            }
          },
          useWindowDrag: true,
          showCustomTitleBar: false,
        ),
      ),
    );
  }
}

/// 国家选择的共享内容组件
class _CountrySelectionContent extends StatelessWidget {
  const _CountrySelectionContent({
    required this.selectedIndex,
    required this.modeIndex,
    required this.onSelectCountry,
    required this.onToggleMode,
    required this.onClose,
    this.onDragUpdate,
    this.useWindowDrag = false,
    this.showCustomTitleBar = true,
  });

  final int selectedIndex;
  final int modeIndex;
  final ValueChanged<int> onSelectCountry;
  final VoidCallback onToggleMode;
  final VoidCallback onClose;
  final GestureDragUpdateCallback? onDragUpdate;
  final bool useWindowDrag;
  final bool showCustomTitleBar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 500,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: const Color(0xFFF3F3F3),
          child: Column(
            children: [
              // 可拖动标题栏 + 关闭按钮（独立窗口模式下隐藏，使用原生标题栏）
              if (showCustomTitleBar)
                GestureDetector(
                  onPanStart: useWindowDrag ? (_) => windowManager.startDragging() : null,
                  onPanUpdate: useWindowDrag ? null : onDragUpdate,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.move,
                    child: Container(
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F3F3),
                        border: Border(bottom: BorderSide(color: Color(0xFFDCDCDC))),
                      ),
                      child: Row(
                        children: [
                          const Gap(8),
                          GestureDetector(
                            onTap: onClose,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(color: Color(0xFFFF5F57), shape: BoxShape.circle),
                              child: const Center(child: Icon(Icons.close_rounded, size: 10, color: Color(0x99000000))),
                            ),
                          ),
                          const Gap(6),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(color: Color(0xFFFEBC2E), shape: BoxShape.circle),
                          ),
                          const Gap(6),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(color: Color(0xFF28C840), shape: BoxShape.circle),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F3F3),
                  border: Border(bottom: BorderSide(color: Color(0xFFD8D8D8))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '安全模式',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: modeIndex == 0 ? const Color(0xFFC45F8D) : const Color(0xFF2F2F2F),
                      ),
                    ),
                    const Gap(10),
                    GestureDetector(
                      onTap: onToggleMode,
                      child: Container(
                        width: 90,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9B8CC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          alignment: modeIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFC65E8C), width: 1.2),
                            ),
                            child: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFC65E8C)),
                          ),
                        ),
                      ),
                    ),
                    const Gap(10),
                    Text(
                      '极速模式',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: modeIndex == 1 ? const Color(0xFFC45F8D) : const Color(0xFF2F2F2F),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  itemCount: _kCountries.length,
                  itemBuilder: (context, index) {
                    final (flag, name) = _kCountries[index];
                    final selected = selectedIndex == index;
                    return InkWell(
                      onTap: () => onSelectCountry(index),
                      child: SizedBox(
                        height: 56,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              if (index == 0)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC65E8C),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                  child: const Icon(Icons.public_rounded, color: Colors.white, size: 18),
                                )
                              else
                                Text(flag, style: const TextStyle(fontSize: 28)),
                              const Gap(14),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF1B1B1B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                width: 23,
                                height: 23,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? const Color(0xFFC65E8C) : const Color(0xFFB8B8B8),
                                    width: 1.5,
                                  ),
                                ),
                                child: selected
                                    ? const Center(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(color: Color(0xFFC65E8C), shape: BoxShape.circle),
                                          child: SizedBox(width: 10, height: 10),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 登录弹窗 ────────────────────────────────────────────────────────────────

/// 登录弹窗页面模式
enum _LoginPage { welcome, login, register }

class LoginAccountView extends ConsumerStatefulWidget {
  const LoginAccountView({super.key, this.onClose});

  final Future<void> Function()? onClose;

  @override
  ConsumerState<LoginAccountView> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<LoginAccountView> {
  _LoginPage _page = _LoginPage.welcome;
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();
    final notifier = ref.read(authNotifierProvider.notifier);

    final bool success;
    if (_page == _LoginPage.login) {
      success = await notifier.login(account, password);
    } else {
      success = await notifier.register(account, password);
    }
    if (success && mounted) {
      await _notifyMainWindowAuthUpdated();
      await _closePanel();
    }
  }

  Future<void> _submitBrowserAuth() async {
    final success = await ref.read(authNotifierProvider.notifier).loginWithBrowserAuth();
    if (success && mounted) {
      await _notifyMainWindowAuthUpdated();
      await _closePanel();
    }
  }

  Future<void> _notifyMainWindowAuthUpdated() async {
    if (!PlatformUtils.isDesktop) {
      return;
    }
    for (final mainWindowId in const [0, 1, 2, 3, 4]) {
      try {
        await DesktopMultiWindow.invokeMethod(mainWindowId, 'auth-updated');
        return;
      } catch (_) {}
    }
  }

  Future<void> _closePanel() async {
    if (widget.onClose != null) {
      await widget.onClose!.call();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return SizedBox(
      width: 700,
      height: 600,
      child: Material(color: Colors.white, child: _buildContentLayout(authState)),
    );
  }

  Widget _buildContentLayout(AuthState authState) {
    return Row(
      children: [
        _buildLeftPanel(authState),
        Container(width: 0.5, color: const Color(0xFFE0E0E0)),
        Expanded(child: _page == _LoginPage.welcome ? _buildWelcomePanel(authState) : _buildAuthFormPanel(authState)),
      ],
    );
  }

  /// 左侧面板：用户头像、设备ID、会员信息
  Widget _buildLeftPanel(AuthState authState) {
    const leftWidth = 180.0;
    final membershipLevelText = authState.isLoggedIn ? '免费会员' : '未登录';
    final membershipLevelColor = authState.isLoggedIn ? const Color(0xFF28C840) : const Color(0xFFCC5F8F);
    final remainingTimeText = authState.isLoggedIn ? '不限时' : '--';

    return SizedBox(
      width: leftWidth,
      child: ColoredBox(
        color: const Color(0xFFF9F9F9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // 头像 + 已过期徽章
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDDDDDD), width: 2),
                      color: const Color(0xFFF0F0F0),
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFFBBBBBB), size: 48),
                  ),
                  Positioned(
                    bottom: -2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: authState.isLoggedIn ? const Color(0xFF28C840) : const Color(0xFFCC5F8F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              authState.isLoggedIn ? Icons.check_circle : Icons.favorite,
                              color: Colors.white,
                              size: 10,
                            ),
                            const Gap(2),
                            Text(
                              authState.isLoggedIn ? '已登录' : '已过期',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Text(
                authState.isLoggedIn ? (authState.account ?? '本机设备') : '本机设备',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
              const Gap(6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '333275276'));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('ID 已复制'), duration: Duration(seconds: 1)));
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('ID: 333275276', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                      const Gap(4),
                      Icon(Icons.copy_rounded, size: 13, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // 会员等级
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.diamond_rounded, color: Color(0xFFCC5F8F), size: 18),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('会员等级', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                          const Gap(2),
                          Text(
                            membershipLevelText,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: membershipLevelColor),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
                  ],
                ),
              ),
              const Gap(10),
              // 剩余时间
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.access_time_rounded, color: Color(0xFFCC5F8F), size: 18),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('剩余时间', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                          const Gap(2),
                          Text(
                            remainingTimeText,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: membershipLevelColor),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
                  ],
                ),
              ),
              const Gap(12),
            ],
          ),
        ),
      ),
    );
  }

  /// 右侧欢迎面板（未登录首页）
  Widget _buildWelcomePanel(AuthState authState) {
    final isLoggedIn = authState.isLoggedIn;
    final accountName = authState.account?.trim();
    final hasAccountName = accountName != null && accountName.isNotEmpty;
    final String welcomeTitle = isLoggedIn ? (hasAccountName ? accountName! : '已登录账户') : '未登录账户';
    final String welcomeDescription = isLoggedIn ? '当前账号已登录，您可以关闭窗口返回主界面。' : '您可以登录或注册一个账户，在不同设备间共享会员时长。';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            welcomeTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const Spacer(flex: 2),
          // 设备图示
          Center(
            child: SizedBox(
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 120,
                      height: 85,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC5F8F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCC5F8F).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Gap(4),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCC5F8F).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 80,
                    child: Container(
                      width: 90,
                      height: 65,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC5F8F).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCC5F8F).withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const Gap(3),
                          Container(
                            width: 80,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCC5F8F).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 80,
                    child: Container(
                      width: 45,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC5F8F).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Container(
                          width: 35,
                          height: 55,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCC5F8F).withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              welcomeDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF888888), height: 1.6),
            ),
          ),
          const Spacer(flex: 2),
          if (isLoggedIn) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: _closePanel,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFCC5F8F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text(
                  '完成',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
            const Gap(10),
          ] else ...[
            // 注册 & 登录 按钮
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => setState(() {
                              _page = _LoginPage.register;
                              _accountController.clear();
                              _passwordController.clear();
                              ref.read(authNotifierProvider.notifier).clearError();
                            }),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCC5F8F), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      child: const Text(
                        '注册',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFCC5F8F)),
                      ),
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => setState(() {
                              _page = _LoginPage.login;
                              _accountController.clear();
                              _passwordController.clear();
                              ref.read(authNotifierProvider.notifier).clearError();
                            }),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFCC5F8F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      child: const Text(
                        '登录',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: authState.isLoading ? null : _submitBrowserAuth,
                icon: authState.isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('浏览器授权登录'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCC5F8F), width: 1),
                  foregroundColor: const Color(0xFFCC5F8F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            if (authState.error != null) ...[
              const Gap(10),
              Text(
                authState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFFE53935)),
              ),
            ],
          ],
          const Gap(16),
        ],
      ),
    );
  }

  /// 右侧登录/注册表单面板
  Widget _buildAuthFormPanel(AuthState authState) {
    final isLogin = _page == _LoginPage.login;
    final title = isLogin ? '登录账户' : '注册账户';
    final submitText = isLogin ? '登录' : '注册';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 返回按钮 + 标题
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _page = _LoginPage.welcome),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF666666)),
                    ),
                  ),
                ),
                const Gap(12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
            const Spacer(),
            // 账号输入框
            TextFormField(
              controller: _accountController,
              validator: AuthApiService.validateAccount,
              decoration: InputDecoration(
                labelText: '账号',
                hintText: '6-20位字母或数字',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFCC5F8F)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCC5F8F), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.next,
            ),
            const Gap(16),
            // 密码输入框
            TextFormField(
              controller: _passwordController,
              validator: AuthApiService.validatePassword,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '6-20位字母或数字',
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFCC5F8F)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF999999),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCC5F8F), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitForm(),
            ),
            const Gap(12),
            // 错误提示
            if (authState.error != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 16),
                    const Gap(8),
                    Expanded(
                      child: Text(authState.error!, style: const TextStyle(fontSize: 13, color: Color(0xFFE53935))),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            // 提交按钮
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: authState.isLoading ? null : _submitForm,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFCC5F8F),
                  disabledBackgroundColor: const Color(0xFFCC5F8F).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        submitText,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
            const Gap(12),
            // 切换登录/注册
            Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  _page = isLogin ? _LoginPage.register : _LoginPage.login;
                  ref.read(authNotifierProvider.notifier).clearError();
                }),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text.rich(
                    TextSpan(
                      text: isLogin ? '没有账号？' : '已有账号？',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                      children: [
                        TextSpan(
                          text: isLogin ? '立即注册' : '立即登录',
                          style: const TextStyle(color: Color(0xFFCC5F8F), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Gap(10),
            Center(
              child: TextButton.icon(
                onPressed: authState.isLoading ? null : _submitBrowserAuth,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('改用浏览器授权登录'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFCC5F8F)),
              ),
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }
}
