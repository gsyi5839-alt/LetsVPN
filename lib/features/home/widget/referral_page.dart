import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/home/widget/windows_localized_strings.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class ReferralPage extends HookConsumerWidget {
  const ReferralPage({super.key});

  static const Size _windowSize = Size(701, 500);
  static const Size _previousWindowSize = Size(300, 551);
  static const String _userId = '333275276';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await windowManager.setSize(_windowSize);
      });
      return () {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await windowManager.setSize(_previousWindowSize);
        });
      };
    }, []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: _windowSize.width,
          height: _windowSize.height,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 左栏：推荐说明
                  SizedBox(
                    width: 340,
                    child: _ReferralLeftPanel(userId: _userId, locale: locale),
                  ),
                  // 分割线
                  const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                  // 右栏：奖励列表
                  Expanded(child: _ReferralRightPanel(locale: locale)),
                ],
              ),
              // 顶部右侧"详细规则"链接
              Positioned(
                top: 12,
                right: 16,
                child: _RulesButton(locale: locale),
              ),
              // 返回按钮
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF888888)),
                  onPressed: () => context.goNamed('home'),
                  tooltip: windowsText(locale, 'common.back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferralLeftPanel extends StatelessWidget {
  const _ReferralLeftPanel({required this.userId, required this.locale});

  final String userId;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        children: [
          // 礼盒图标
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFCC5F8F), size: 48),
          ),
          const Gap(18),
          // 标题
          Text(
            windowsText(locale, 'referral.title'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            textAlign: TextAlign.center,
          ),
          const Gap(12),
          // 说明文字
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.6),
              children: [
                TextSpan(text: windowsText(locale, 'referral.detailText', params: {'id': userId})),
              ],
            ),
          ),
          const Gap(24),
          // 推荐按钮
          SizedBox(
            width: 200,
            height: 42,
            child: FilledButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: userId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(windowsText(locale, 'referral.copied')), duration: const Duration(seconds: 2)),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCC5F8F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(windowsText(locale, 'referral.share'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const Spacer(),
          // 底部统计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                label: windowsText(locale, 'referral.successCount'),
                value: '0',
                unit: locale.toString() == 'en' ? '' : windowsText(locale, 'common.peopleUnit'),
              ),
              _StatDivider(),
              _StatItem(
                label: windowsText(locale, 'referral.totalEarned'),
                value: '0',
                unit: locale.toString() == 'en' ? '' : windowsText(locale, 'common.hoursUnit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
        const Gap(4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFCC5F8F)),
              ),
              TextSpan(
                text: unit,
                style: const TextStyle(fontSize: 12, color: Color(0xFFCC5F8F)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
  }
}

class _ReferralRightPanel extends StatelessWidget {
  const _ReferralRightPanel({required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            windowsText(locale, 'referral.myRewards'),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
          ),
          const Gap(24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined, size: 56, color: const Color(0xFFCCCCCC)),
                  const Gap(12),
                  Text(
                    windowsText(locale, 'referral.empty'),
                    style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesButton extends StatelessWidget {
  const _RulesButton({required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.help_outline_rounded, size: 14, color: Color(0xFFCC5F8F)),
      label: Text(windowsText(locale, 'referral.rules'), style: const TextStyle(fontSize: 12, color: Color(0xFFCC5F8F))),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
      ),
    );
  }
}
