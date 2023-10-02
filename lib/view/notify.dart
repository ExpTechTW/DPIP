import 'package:flutter/material.dart';

class NotifyPage extends StatefulWidget {
  const NotifyPage({Key? key}) : super(key: key);

  @override
  _NotifyPage createState() => _NotifyPage();
}

class _NotifyPage extends State<NotifyPage> {
  final List<Widget> _List_children = <Widget>[const SizedBox(height: 10)];

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
