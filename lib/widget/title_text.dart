import 'package:flutter/material.dart';

class TitleText extends StatelessWidget {
  final String text;

  const TitleText({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 25),
      ),
    );
  }
}
