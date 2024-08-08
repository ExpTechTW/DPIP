import 'package:flutter/material.dart';

class WelcomePermissionPage extends StatelessWidget {
  const WelcomePermissionPage({super.key});

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
                    '所需的資訊和權限列表',
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
                    '讀寫權限：用於儲存下載的圖片\n'
                    '定位權限：用於取得使用者位置，判斷接收之警訊內容',
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
