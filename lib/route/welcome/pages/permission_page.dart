import 'package:flutter/material.dart';

class WelcomePermissionPage extends StatelessWidget {
  const WelcomePermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(height: 100),
          AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(seconds: 2),
            child: Text(
              '所需的資訊和權限列表',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '讀寫權限：用於儲存下載的圖片\n'
              '定位權限：用於取得使用者位置，判斷接收之警訊內容',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
