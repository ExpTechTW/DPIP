import 'package:flutter/material.dart';

class WelcomeDisclaimerPage extends StatelessWidget {
  const WelcomeDisclaimerPage({super.key});

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
                    '免責聲明',
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
                    '1. ExpTech Studio Ltd. 將盡力確保提供之資訊、資料及畫面準確無誤，但不能保證其絕對無誤。氣象相關資訊使用時請以中央氣象署發布之內容為準。\n'
                    '2. 不得將 ExpTech Studio Ltd. 提供之程式碼、資訊、資料及畫面，以任何方式進行不當之廣告、宣傳、陳述或騷擾行為。\n'
                    '3. 不得將 ExpTech Studio Ltd. 提供之程式碼、資訊、資料及畫面進行轉售，或以不當之名義進行再分發。'
                    '4. 您所提供的註冊資訊及其他於利用服務時所提供之個人資料，ExpTech Studio Ltd. 將依【隱私權暨個人資料保護政策】進行蒐集、利用與保護。'
                    '\n詳情請至: https://exptech.com.tw/tos 查看',
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
