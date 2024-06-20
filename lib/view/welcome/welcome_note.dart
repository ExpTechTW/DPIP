import 'package:dpip/view/welcome/welcome_earthquake.dart';
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
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text("注意事項"),
            ),
            body: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  // FutureBuilder(
                  //     future: rootBundle.loadString('assets/tos.md'),
                  //     builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  //       if (snapshot.hasData) {
                  //         return Markdown(data: snapshot.data!);
                  //       } else {
                  //         return const Center(child: CircularProgressIndicator());
                  //       }
                  //     }),
                  data != "" ? Expanded(child: Markdown(data: data)) : const Center(child: CircularProgressIndicator()),
                  Align(
                    alignment: Alignment.bottomRight,
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
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) => const WelcomeEarthquakePage()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: const Text(
                          "下一步",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                ]))));
  }
}
