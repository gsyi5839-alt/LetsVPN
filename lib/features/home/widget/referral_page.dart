import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class ReferralPage extends HookConsumerWidget {
  const ReferralPage({super.key});

  static const Size _windowSize = Size(701, 500);
  static const Size _previousWindowSize = Size(300, 551);
  static const String _userId = '333275276';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    child: _ReferralLeftPanel(userId: _userId),
                  ),
                  // 分割线
                  const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                  // 右栏：奖励列表
                  const Expanded(child: _ReferralRightPanel()),
                ],
              ),
              // 顶部右侧"详细规则"链接
              const Positioned(
                top: 12,
                right: 16,
                child: _RulesButton(),
              ),
              // 返回按钮
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF888888)),
                  onPressed: () => context.goNamed('home'),
                  tooltip: '返回',
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
  const _ReferralLeftPanel({required this.userId});

  final String userId;

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
          const Text(
            '推荐朋友，领永久会员',
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
                const TextSpan(text: '好友安装快连后，填写您的 ID（'),
                TextSpan(
                  text: userId,
                  style: const TextStyle(color: Color(0xFFCC5F8F), fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '）即算推荐成功，当其每次获得会员，您均可获取 '),
                const TextSpan(
                  text: '20%',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFCC5F8F)),
                ),
                const TextSpan(text: ' 的时长！永久有效！'),
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
                  const SnackBar(content: Text('推荐码已复制'), duration: Duration(seconds: 2)),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCC5F8F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('推荐给好友', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const Spacer(),
          // 底部统计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _StatItem(label: '成功推荐', value: '0', unit: '人'),
              _StatDivider(),
              _StatItem(label: '累计获得', value: '0', unit: '小时'),
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
  const _ReferralRightPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我的奖励（只显示最近 10 条）',
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
                  const Text(
                    '暂时还未获得推荐奖励，快去推荐好友吧！',
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
  const _RulesButton();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.help_outline_rounded, size: 14, color: Color(0xFFCC5F8F)),
      label: const Text('详细规则', style: TextStyle(fontSize: 12, color: Color(0xFFCC5F8F))),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
      ),
    );
  }
}
