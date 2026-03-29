import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/home/widget/windows_localized_strings.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class _MessageItem {
  const _MessageItem({required this.title, required this.body});

  final String title;
  final String body;
}

class MessagesPage extends HookConsumerWidget {
  const MessagesPage({super.key});

  static const Size _windowSize = Size(700, 500);
  static const Size _previousWindowSize = Size(300, 551);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final messages = [
      _MessageItem(
        title: windowsText(locale, 'messages.geminiTitle'),
        body: windowsText(locale, 'messages.geminiBody'),
      ),
      _MessageItem(
        title: windowsText(locale, 'messages.securityTitle'),
        body: windowsText(locale, 'messages.securityBody'),
      ),
    ];

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
                  itemCount: messages.length,
                  separatorBuilder: (context, index) => const Gap(12),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
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
                  tooltip: windowsText(locale, 'common.back'),
                ),
              ),
              // 页面标题
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    windowsText(locale, 'messages.title'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
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
