import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/features/home/widget/windows_localized_strings.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:window_manager/window_manager.dart';

class SplashPage extends HookWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final animController = useAnimationController(
      duration: const Duration(milliseconds: 3000),
    );
    useEffect(() {
      animController.forward();
      return null;
    }, const []);

    final progress = useAnimation(animController);

    final String statusText;
    if (progress < 0.35) {
      statusText = windowsText(locale, 'splash.initializing');
    } else if (progress < 0.65) {
      statusText = windowsText(locale, 'splash.network');
    } else {
      statusText = windowsText(locale, 'splash.sdk');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Windows 自定义标题栏
          if (PlatformUtils.isWindows) const _SplashTitleBar(),
          // 主内容区
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/app_icon_splash.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const Gap(28),
                const Text(
                  'LetsVPN',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2C2E),
                    letterSpacing: 1,
                  ),
                ),
                const Gap(14),
                Text(
                  windowsText(locale, 'splash.subtitle'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                    letterSpacing: 5,
                  ),
                ),
              ],
            ),
          ),
          // 底部进度条区域
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 0, 36, 10),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFD8D8D8),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4A90D9),
                    ),
                  ),
                ),
                const Gap(8),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          const Gap(30),
        ],
      ),
    );
  }
}

/// Windows 启动页专用标题栏
class _SplashTitleBar extends StatelessWidget {
  const _SplashTitleBar();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 38,
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          children: [
            const Text(
              'LetsVPN',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF141A21),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            _TitleBarBtn(
              onPressed: () => windowManager.minimize(),
              icon: Icons.remove_rounded,
              iconSize: 14,
            ),
            _TitleBarBtn(
              onPressed: () {},
              icon: Icons.open_in_full_rounded,
              iconSize: 10,
            ),
            _TitleBarBtn(
              onPressed: () => windowManager.close(),
              icon: Icons.close_rounded,
              iconSize: 14,
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBarBtn extends StatefulWidget {
  const _TitleBarBtn({
    required this.onPressed,
    required this.icon,
    required this.iconSize,
    this.isClose = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final double iconSize;
  final bool isClose;

  @override
  State<_TitleBarBtn> createState() => _TitleBarBtnState();
}

class _TitleBarBtnState extends State<_TitleBarBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color iconColor;
    if (_hovered) {
      bg = widget.isClose ? const Color(0xFFE81123) : const Color(0x16000000);
      iconColor = widget.isClose ? Colors.white : const Color(0xFF2C3440);
    } else {
      bg = Colors.transparent;
      iconColor = const Color(0xFF515C68);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 46,
          height: 38,
          color: bg,
          child: Icon(widget.icon, size: widget.iconSize, color: iconColor),
        ),
      ),
    );
  }
}
