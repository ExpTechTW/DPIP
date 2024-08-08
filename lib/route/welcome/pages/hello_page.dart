import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WelcomeHelloPage extends StatelessWidget {
  const WelcomeHelloPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 80,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(width: 2, color: Colors.white),
            borderRadius: BorderRadius.circular(30),
            color: Colors.black38,
          ),
          padding: const EdgeInsets.all(20),
          child: const Column(
            children: <Widget>[
              SizedBox(height: 10),
              Flexible(
                flex: 1,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(seconds: 2),
                  child: Text(
                    '歡迎使用 DPIP',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Flexible(
                flex: 10,
                child: SingleChildScrollView(
                  child: Text(
                    'DPIP 是一款面向大眾的防災應用程式，使用它需要注意以下幾點：\n'
                    '1. 使用過程中可能遇到程式錯誤，如遇到錯誤請向開發人員回報。\n'
                    '2. 使用過程中，請務必謹慎閱讀提示和注意事項。\n'
                    '3. 任何不被官方所認可的行為均有可能承擔法律風險，請務必遵守相關規範。\n'
                    '4. 最後，如果覺得應用程式不錯，請分享給其他人，這是讓開發團隊維護下去的動力。\n'
                    '\nEmail：support@exptech.com.tw\n2024/07/21 01:01 初稿\n©2024 ExpTech Studio Ltd.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
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
