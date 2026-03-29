import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/home/widget/windows_localized_strings.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class FreeMembershipPage extends HookConsumerWidget {
  const FreeMembershipPage({super.key});

  static const Size _windowSize = Size(300, 514);
  static const Size _previousWindowSize = Size(300, 551);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final isLoading = useState(false);

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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    const Gap(24),
                    // 优惠券图标
                    Container(
                      width: 100,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFCC5F8F), Color(0xFFE87BAB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFCC5F8F).withValues(alpha: .3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // 锯齿圆形装饰
                          Positioned(
                            left: -10,
                            top: 24,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -10,
                            top: 24,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                windowsText(locale, 'free.badge'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(28),
                    // 标题
                    Text(
                      windowsText(locale, 'free.title'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                    ),
                    const Gap(10),
                    Text(
                      windowsText(locale, 'free.subtitle'),
                      style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(28),
                    // 按钮
                    SizedBox(
                      width: 200,
                      height: 44,
                      child: FilledButton(
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                isLoading.value = true;
                                await Future.delayed(const Duration(seconds: 1));
                                isLoading.value = false;
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFCC5F8F),
                          disabledBackgroundColor: const Color(0xFFE8A0BC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                windowsText(locale, 'free.button'),
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                      ),
                    ),
                    const Spacer(),
                    // 底部统计
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(
                            label: windowsText(locale, 'free.todayCount'),
                            value: '33306',
                            unit: locale.toString() == 'en' ? '' : windowsText(locale, 'common.peopleUnit'),
                          ),
                          _Divider(),
                          _StatItem(
                            label: windowsText(locale, 'free.totalHours'),
                            value: '24980',
                            unit: locale.toString() == 'en' ? '' : windowsText(locale, 'common.hoursUnit'),
                          ),
                        ],
                      ),
                    ),
                  ],
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
            ],
          ),
        ),
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFCC5F8F),
                ),
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
  }
}
