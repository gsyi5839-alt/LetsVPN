import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/adaptive_layout/my_adaptive_layout.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/custom_transition.dart';
import 'package:hiddify/core/router/go_router/refresh_listenable.dart';
import 'package:hiddify/features/about/widget/about_page.dart';
import 'package:hiddify/features/bundled_software/widget/bundled_software_page.dart';
import 'package:hiddify/features/home/widget/free_membership_page.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/home/widget/messages_page.dart';
import 'package:hiddify/features/home/widget/referral_page.dart';
import 'package:hiddify/features/home/widget/splash_page.dart';
import 'package:hiddify/features/intro/widget/intro_page.dart';
import 'package:hiddify/features/log/overview/logs_page.dart';
import 'package:hiddify/features/per_app_proxy/overview/per_app_proxy_page.dart';
import 'package:hiddify/features/profile/details/profile_details_page.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_page.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_page.dart';
import 'package:hiddify/features/settings/overview/sections/dns_options_page.dart';
import 'package:hiddify/features/settings/overview/sections/general_page.dart';
import 'package:hiddify/features/settings/overview/sections/inbound_options_page.dart';
import 'package:hiddify/features/settings/overview/sections/route_options_page.dart';
import 'package:hiddify/features/settings/overview/sections/tls_tricks_page.dart';
import 'package:hiddify/features/settings/overview/sections/warp_options_page.dart';
import 'package:hiddify/features/settings/overview/settings_page.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'routing_config_notifier.g.dart';

// each branch in go router has its own focus scope
final branchesScope = <String, FocusScopeNode>{
  'home': FocusScopeNode(),
  'profiles': FocusScopeNode(),
  'settings': FocusScopeNode(),
  'logs': FocusScopeNode(),
  'about': FocusScopeNode(),
};

// when the routing config is not yet initialized, this config is used
final loadingConfig = RoutingConfig(
  routes: <RouteBase>[GoRoute(path: '/home', builder: (context, state) => const SplashPage())],
);

// 强制显示 splash 页面至少 3 秒
final _splashTimerProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(seconds: 3));
});

String getNameOfBranch(bool isMobileBreakpoint, bool showProfilesAction, int index) => isMobileBreakpoint
    ? ['home', 'settings'][index]
    : ['home', if (showProfilesAction) 'profiles', 'settings', 'logs', 'about'][index];

int getIndexOfBranch(bool isMobileBreakpoint, bool showProfilesAction, String name) => isMobileBreakpoint
    ? ['home', 'settings'].indexOf(name)
    : ['home', if (showProfilesAction) 'profiles', 'settings', 'logs', 'about'].indexOf(name);

@Riverpod(keepAlive: true)
class RoutingConfigNotifier extends _$RoutingConfigNotifier {
  @override
  RoutingConfig build() {
    // splash 计时器未完成前，持续显示加载页
    final splashTimer = ref.watch(_splashTimerProvider);
    if (splashTimer is! AsyncData) return loadingConfig;

    final isMobileBreakpoint = ref.watch(isMobileBreakpointProvider);
    final bool showProfilesAction;
    if (isMobileBreakpoint == true) {
      showProfilesAction = false;
    } else {
      showProfilesAction = ref.watch(hasAnyProfileProvider).value ?? false;
    }
    if (isMobileBreakpoint == null) return loadingConfig;
    return RoutingConfig(
      redirect: (context, state) {
        final introCompleted = ref.read(Preferences.introCompleted);
        final isIntro = state.matchedLocation == '/intro';
        // fix path-parameters for deep link
        String? url;
        if (LinkParser.protocols.contains(state.uri.scheme)) {
          url = state.uri.toString();
        } else if (PlatformUtils.isDesktop && newUrlFromAppLink.isNotEmpty) {
          url = newUrlFromAppLink;
          newUrlFromAppLink = '';
        } else if (state.uri.queryParameters['url'] != null) {
          url = state.uri.queryParameters['url'];
        }

        if (!introCompleted && !PlatformUtils.isWindows) {
          return url != null ? '/intro?url=$url' : '/intro';
        } else if (isIntro) {
          if (url != null)
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(url: url),
            );
          return '/home';
        } else if (url != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(url: url),
          );
          return '/home';
        }
        return null;
      },
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (_, _, navigationShell) => MyAdaptiveLayout(
            navigationShell: navigationShell,
            isMobileBreakpoint: isMobileBreakpoint,
            showProfilesAction: showProfilesAction,
          ),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <GoRoute>[
                GoRoute(
                  name: 'home',
                  path: '/home',
                  builder: (_, _) => FocusScope(node: branchesScope['home'], child: const HomePage()),
                  routes: <GoRoute>[
                    GoRoute(
                      name: 'proxies',
                      path: '/proxies',
                      pageBuilder: (_, state) =>
                          customTransition(TransitionType.fade, state.pageKey, const ProxiesOverviewPage()),
                    ),
                    if (!isMobileBreakpoint) ...[
                      GoRoute(
                        name: 'referral',
                        path: '/referral',
                        pageBuilder: (_, state) =>
                            customTransition(TransitionType.fade, state.pageKey, const ReferralPage()),
                      ),
                      GoRoute(
                        name: 'freeMembership',
                        path: '/free-membership',
                        pageBuilder: (_, state) =>
                            customTransition(TransitionType.fade, state.pageKey, const FreeMembershipPage()),
                      ),
                      GoRoute(
                        name: 'messages',
                        path: '/messages',
                        pageBuilder: (_, state) =>
                            customTransition(TransitionType.fade, state.pageKey, const MessagesPage()),
                      ),
                    ],
                    if (isMobileBreakpoint)
                      GoRoute(
                        name: 'profileDetails',
                        path: '/profile-details/:id',
                        pageBuilder: (_, state) => customTransition(
                          TransitionType.fade,
                          state.pageKey,
                          ProfileDetailsPage(id: state.pathParameters['id']!),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (showProfilesAction)
              StatefulShellBranch(
                routes: <GoRoute>[
                  GoRoute(
                    name: 'profiles',
                    path: '/profiles',
                    builder: (_, _) => FocusScope(node: branchesScope['profiles'], child: const ProfilesPage()),
                    routes: <GoRoute>[
                      GoRoute(
                        name: 'profileDetails',
                        path: '/profiles/:id',
                        pageBuilder: (_, state) => customTransition(
                          TransitionType.fade,
                          state.pageKey,
                          ProfileDetailsPage(id: state.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            StatefulShellBranch(
              routes: <GoRoute>[
                GoRoute(
                  name: 'settings',
                  path: '/settings',
                  builder: (context, _) => FocusScope(
                    node: branchesScope['settings'],
                    child: PopScope(
                      canPop: false,
                      onPopInvokedWithResult: (_, _) => context.goNamed('home'),
                      child: SettingsPage(),
                    ),
                  ),
                  routes: <GoRoute>[
                    GoRoute(
                      name: 'general',
                      path: '/general',
                      pageBuilder: (_, state) =>
                          customTransition(TransitionType.slide, state.pageKey, const GeneralPage()),
                    ),
                    GoRoute(
                      name: 'routeOptions',
                      path: '/route-options',
                      pageBuilder: (_, state) =>
                          customTransition(TransitionType.slide, state.pageKey, const RouteOptionsPage()),
                      routes: <GoRoute>[
                        GoRoute(
                          name: 'perAppProxy',
                          path: '/per-app-proxy',
                          pageBuilder: (_, state) =>
                              customTransition(TransitionType.slide, state.pageKey, const PerAppProxyPage()),
                        ),
                      ],
                    ),
                    GoRoute(
                      name: 'dnsOptions',
                      path: '/dns-options',
                      pageBuilder: (_, state) =>
                          customTransition(TransitionType.slide, state.pageKey, const DnsOptionsPage()),
                    ),
                    GoRoute(
                      name: 'inboundOptions',
                      path: '/inbound-options',
                      pageBuilder: (_, state) =>
                          customTransition(TransitionType.slide, state.pageKey, const InboundOptionsPage()),
                    ),
                    GoRoute(
                      name: 'tlsTricks',
                      path: '/tls-tricks',
                      pageBuilder: (_, state) =>
                          customTransition(TransitionType.slide, state.pageKey, const TlsTricksPage()),
                    ),
                    GoRoute(
                      name: 'warpOptions',
                      path: '/warp-options',
                      pageBuilder: (_, state) =>
                          customTransition(TransitionType.slide, state.pageKey, const WarpOptionsPage()),
                    ),
                    if (isMobileBreakpoint) ...[
                      GoRoute(
                        name: 'logs',
                        path: '/logs',
                        pageBuilder: (_, state) =>
                            customTransition(TransitionType.slide, state.pageKey, const LogsPage()),
                      ),
                      GoRoute(
                        name: 'about',
                        path: '/about',
                        pageBuilder: (_, state) =>
                            customTransition(TransitionType.slide, state.pageKey, const AboutPage()),
                      ),
                    ],
                    if (!isMobileBreakpoint)
                      GoRoute(
                        name: 'bundledSoftware',
                        path: '/bundled-software',
                        pageBuilder: (_, state) =>
                            customTransition(TransitionType.slide, state.pageKey, const BundledSoftwarePage()),
                      ),
                  ],
                ),
              ],
            ),
            if (!isMobileBreakpoint) ...[
              StatefulShellBranch(
                routes: <GoRoute>[
                  GoRoute(
                    name: 'logs',
                    path: '/logs',
                    builder: (_, _) => FocusScope(node: branchesScope['logs'], child: const LogsPage()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <GoRoute>[
                  GoRoute(
                    name: 'about',
                    path: '/about',
                    builder: (_, _) => FocusScope(node: branchesScope['about'], child: const AboutPage()),
                  ),
                ],
              ),
            ],
          ],
        ),
        GoRoute(name: 'intro', path: '/intro', builder: (_, _) => const IntroPage()),
      ],
    );
  }
}
