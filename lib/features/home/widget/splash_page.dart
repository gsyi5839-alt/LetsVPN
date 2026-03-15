import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App 图标
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(22)),
              child: Image(
                image: AssetImage('assets/images/app_icon_splash.png'),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 18),
            // App 名称
            Text(
              '快连 VPN',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2C2E),
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 8),
            // 副标题
            Text(
              '永远能连上的 VPN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
              ),
            ),
            SizedBox(height: 80),
            // 加载指示器
            CupertinoActivityIndicator(
              radius: 14,
              color: Color(0xFFAAAAAA),
            ),
          ],
        ),
      ),
    );
  }
}
