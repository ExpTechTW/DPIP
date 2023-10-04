import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class NotifyPage extends StatefulWidget {
  const NotifyPage({Key? key}) : super(key: key);

  @override
  _NotifyPage createState() => _NotifyPage();
}

class _NotifyPage extends State<NotifyPage> {
  List<Widget> _List_children = <Widget>[const SizedBox(height: 10)];
  bool n_alert = false;
  bool play_alert = false;
  final audioPlayer = AudioPlayer();

  @override
  void initState() {
    render();
    super.initState();
  }

  void play(String name) async {
    if (!play_alert) {
      play_alert = true;
      if (Platform.isAndroid) {
          await audioPlayer.setAudioSource(
            AudioSource.uri(
                Uri.parse('android.resource://com.exptech.dpip/raw/$name')),
          );
      } else if (Platform.isIOS) {
        await audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse('$name.wav')),
        );
      }
      await audioPlayer.play();
    } else {
      play_alert = false;
      await audioPlayer.stop();
      play(name);
    }
  }

  void render() async {
    _List_children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
        child: Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon:
                  const Icon(Icons.arrow_back, color: Colors.white70, size: 24),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      )
    ];
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("強震即時警報（警報）",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
          SizedBox(width: 5),
          Text("預估最大震度 5弱 以上",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w300))
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              play("eew_alert");
            },
            title: const Text(
              "所在地 預估震度 4級 以上",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: const Icon(
              Icons.play_circle_fill,
              color: Colors.blue,
              size: 30,
            ),
          ),
          const Divider(
              color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
          ListTile(
            onTap: () {
              play("eew_warn");
            },
            title: const Text(
              "所在地 預估震度 3級 以下",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: const Icon(
              Icons.play_circle_fill,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("地震速報（注意）",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
          SizedBox(width: 5),
          Text("預估最大震度 5弱 以下",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w300))
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              play("eew_warn");
            },
            title: const Text(
              "所在地 預估震度 3級 以上",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: const Icon(
              Icons.play_circle_fill,
              color: Colors.blue,
              size: 30,
            ),
          ),
          const Divider(
              color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
          const ListTile(
            title: Text(
              "所在地 預估震度 2級 以下",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: Icon(
              Icons.play_circle_fill,
              color: Colors.grey,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("震度速報",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
          SizedBox(width: 5),
          Text("地震觀測網自動觀測結果",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w300))
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              play("warn");
            },
            title: const Text(
              "所在地 實測震度 3級 以上",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: const Icon(
              Icons.play_circle_fill,
              color: Colors.blue,
              size: 30,
            ),
          ),
          const Divider(
              color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
          const ListTile(
            title: Text(
              "所在地 實測震度 2級 以下",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: Icon(
              Icons.play_circle_fill,
              color: Colors.grey,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("地震報告",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
          SizedBox(width: 5),
          Text("中央氣象署 地震報告",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w300))
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              play("warn");
            },
            title: const Text(
              "所在地 實測震度 3級 以上",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: const Icon(
              Icons.play_circle_fill,
              color: Colors.blue,
              size: 30,
            ),
          ),
          const Divider(
              color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
          const ListTile(
            title: Text(
              "所在地 實測震度 2級 以下",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: Icon(
              Icons.play_circle_fill,
              color: Colors.grey,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("大雷雨即時訊息",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              play("warn");
            },
            title: const Text(
              "所在地 發布 大雷雨即時訊息",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: const Icon(
              Icons.play_circle_fill,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("豪雨特報",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              play("warn");
            },
            title: const Text(
              "所在地 發布 豪雨特報",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: const Icon(
              Icons.play_circle_fill,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("大雨特報",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              play("warn");
            },
            title: const Text(
              "所在地 發布 大雨特報",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: const Icon(
              Icons.play_circle_fill,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("高溫資訊",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              "所在地 發布 高溫資訊",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: Icon(
              Icons.play_circle_fill,
              color: Colors.grey,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("陸上強風特報",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              "所在地 發布 陸上強風特報",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: Icon(
              Icons.play_circle_fill,
              color: Colors.grey,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("停班停課資訊",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              "所在地 發布 停班停課資訊",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: Icon(
              Icons.play_circle_fill,
              color: Colors.grey,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("海上陸上颱風警報",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              "發布 海上陸上颱風警報",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: Icon(
              Icons.play_circle_fill,
              color: Colors.grey,
              size: 30,
            ),
          ),
        ],
      ),
    ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: _List_children.toList(),
          ),
        ),
      ),
    );
  }
}
