import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class CustomMarker {
  final LatLng coordinate;
  final int zIndex;
  final double size;
  final Widget child;

  const CustomMarker({
    required this.coordinate,
    this.zIndex = 1,
    this.size = 20,
    required this.child,
  });
}
