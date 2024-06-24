import 'dart:io';

import 'package:dpip/view/welcome/welcome_earthquake.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class WelcomeNotePage extends StatefulWidget {
  const WelcomeNotePage({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _WelcomeNotePageState();
}

class _WelcomeNotePageState extends State<WelcomeNotePage> {
  String data = "";

  void loadTos() async {
    data = await rootBundle.loadString('assets/tos.md');
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadTos();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("注意事項"),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "請詳閱並同意以下條款",
                  style: TextStyle(fontSize: 16),
                ),
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(const Color(0xFF009E8B), Colors.transparent, 0.7)!,
                            Color.lerp(const Color(0xFF203864), Colors.transparent, 0.7)!
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: const Color(0xFF606060), width: 2),
                      ),
                      child: data.isNotEmpty
                          ? Markdown(data: data,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
                          h2: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
                          h3: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
                          listBullet: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
                        ),
                      )
                          : const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009E8B), Color(0xFF203864)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const WelcomeEarthquakePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                      child: const Text(
                        "同意並繼續",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text("注意事項"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "請詳閱並同意以下條款",
                  style: TextStyle(fontSize: 16),
                ),
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(const Color(0xFF009E8B), Colors.transparent, 0.7)!,
                            Color.lerp(const Color(0xFF203864), Colors.transparent, 0.7)!
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: const Color(0xFF606060), width: 2),
                      ),
                      child: data != ""
                          ? Markdown(data: data)
                          : const Center(
                              child: CircularProgressIndicator(),
                            ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009E8B), Color(0xFF203864)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const WelcomeEarthquakePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                      child: const Text(
                        "同意並繼續",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
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
}
