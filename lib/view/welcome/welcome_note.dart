import 'package:dpip/view/welcome/welcome_earthquake.dart';
import 'package:flutter/material.dart';

class WelcomeNotePage extends StatefulWidget {
  const WelcomeNotePage({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _WelcomeNotePageState();
}

class _WelcomeNotePageState extends State<WelcomeNotePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text("注意事項"),
            ),
            body: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("內文"),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) => const WelcomeEarthquakePage()));
                          },
                          child: const Text("下一步")))
                ]))));
  }
}
