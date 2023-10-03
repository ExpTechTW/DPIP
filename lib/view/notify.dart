import 'package:flutter/material.dart';

class NotifyPage extends StatefulWidget {
  const NotifyPage({Key? key}) : super(key: key);

  @override
  _NotifyPage createState() => _NotifyPage();
}

class _NotifyPage extends State<NotifyPage> {
  List<Widget> _List_children = <Widget>[const SizedBox(height: 10)];
  bool n_alert = false;

  @override
  void initState() {
    render();
    super.initState();
  }

  void render() async {
    _List_children = <Widget>[const SizedBox(height: 10)];
    _List_children.add(const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.warning_amber_outlined,color: Colors.red),
        SizedBox(width: 5),
        Text("緊急警報",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600))
      ],
    ));
    _List_children.add(
        Container(
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
                onTap: () {},
                title: const Text(
                  "強震即時警報",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                trailing: Switch(
                  value: n_alert,
                  onChanged: (bool value) {
                    setState(() {
                      n_alert = value;
                    });
                    render();
                  },
                  activeColor: Colors.blue[800],
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[300],
                  activeTrackColor: Colors.blue[200],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0, bottom: 10.0),
                child: Text(
                  "啟用或關閉強震即時警報。此功能將在強震發生時為您發送即時通知。",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const Divider(
                  color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
            ],
          ),
        )
    );
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.doorbell_outlined,color: Colors.amber),
        SizedBox(width: 5),
        Text("警訊通知",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600))
      ],
    ));
    _List_children.add(
        Container(
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
                onTap: () {},
                title: const Text(
                  "強震即時警報",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                trailing: Switch(
                  value: n_alert,
                  onChanged: (bool value) {
                    setState(() {
                      n_alert = value;
                    });
                    render();
                  },
                  activeColor: Colors.blue[800],
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[300],
                  activeTrackColor: Colors.blue[200],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0, bottom: 10.0),
                child: Text(
                  "啟用或關閉強震即時警報。此功能將在強震發生時為您發送即時通知。",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const Divider(
                  color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
            ],
          ),
        )
    );
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.speaker_notes_outlined,color: Colors.white),
        SizedBox(width: 5),
        Text("一般訊息",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600))
      ],
    ));
    _List_children.add(
        Container(
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
                onTap: () {},
                title: const Text(
                  "強震即時警報",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                trailing: Switch(
                  value: n_alert,
                  onChanged: (bool value) {
                    setState(() {
                      n_alert = value;
                    });
                    render();
                  },
                  activeColor: Colors.blue[800],
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[300],
                  activeTrackColor: Colors.blue[200],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0, bottom: 10.0),
                child: Text(
                  "啟用或關閉強震即時警報。此功能將在強震發生時為您發送即時通知。",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const Divider(
                  color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
            ],
          ),
        )
    );
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
