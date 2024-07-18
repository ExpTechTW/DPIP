import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class Marker extends StatefulWidget {
  final Point initialPosition;
  final LatLng coordinate;
  final double size;
  final int zIndex;
  final void Function(MarkerState) addMarkerState;
  final Widget child;

  const Marker({
    super.key,
    required this.initialPosition,
    required this.coordinate,
    this.size = 20.0,
    this.zIndex = 1,
    required this.addMarkerState,
    required this.child,
  });

  @override
  State<Marker> createState() => MarkerState();
}

class MarkerState extends State<Marker> {
  late Point _position = widget.initialPosition;
  late final ratio = Platform.isIOS ? 1.0 : MediaQuery.of(context).devicePixelRatio;

  void updatePosition(Point<num> point) {
    setState(() {
      _position = point;
    });
  }

  LatLng getCoordinate() {
    return widget.coordinate;
  }

  @override
  void initState() {
    super.initState();
    widget.addMarkerState(this);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.x / ratio - widget.size / 2,
      top: _position.y / ratio - widget.size / 2,
      child: widget.child,
    );
  }
}
