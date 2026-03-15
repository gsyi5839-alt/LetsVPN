import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class _MessageItem {
  const _MessageItem({required this.title, required this.body});

  final String title;
  final String body;
}

const _kMessages = [
  _MessageItem(
    title: '搞定 Gemini 报错，看这篇就够了',
    body: 'Gemini 频繁报错、提示地区不支持？快连已完成专项优化，教你三招彻底告别这些抓狂时刻。',
  ),
  _MessageItem(
    title: '保护您的快连 VPN 服务不被盗取',
    body: '请您认准官方渠道充值，并且妥善保管好您的订单号，这是快连 VPN 售后的唯一保障。',
  ),
];

class MessagesPage extends HookConsumerWidget {
  const MessagesPage({super.key});

  static const Size _windowSize = Size(700, 500);
  static const Size _previousWindowSize = Size(300, 551);

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
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SizedBox(
          width: _windowSize.width,
          height: _windowSize.height,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
                child: ListView.separated(
                  itemCount: _kMessages.length,
                  separatorBuilder: (context, index) => const Gap(12),
                  itemBuilder: (context, index) {
                    final msg = _kMessages[index];
                    return _MessageCard(message: msg);
                  },
                ),
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
              // 页面标题
              const Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '消息中心',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final _MessageItem message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧蓝色分割条
            Container(
              width: 3,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Gap(12),
            // 蓝色 info 图标
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_rounded, color: Colors.white, size: 16),
            ),
            const Gap(12),
            // 标题 + 正文
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    message.body,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Gap(8),
            // 未读红点
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3A2F),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
