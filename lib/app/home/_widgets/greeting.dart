import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';

class Greeting extends StatelessWidget {
  const Greeting({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .all(16),
      child: TitleText.large('夜深了'),
    );
  }
}
