import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

abstract class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @mustBeOverridden
  Function get onNextPage;

  @mustBeOverridden
  Function get onPrevPage;
}
