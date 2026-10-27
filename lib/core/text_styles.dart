import 'package:flutter/material.dart';

import 'palette.dart';

/// One display face, one text face, four sizes that do all the work.
abstract final class AppText {
  static const serif = 'DMSerif';
  static const sans = 'Figtree';

  static TextStyle display(double size, {Color? color, double height = 1.0}) {
    return TextStyle(
      fontFamily: serif,
      fontSize: size,
      height: height,
      letterSpacing: -0.6,
      color: color ?? Palette.ink,
    );
  }

  static TextStyle serifItalic(
    double size, {
    Color? color,
    double height = 1.2,
  }) {
    return TextStyle(
      fontFamily: serif,
      fontStyle: FontStyle.italic,
      fontSize: size,
      height: height,
      letterSpacing: -0.2,
      color: color ?? Palette.ink,
    );
  }

  static TextStyle label(double size, {Color? color, double tracking = 1.7}) {
    return TextStyle(
      fontFamily: sans,
      fontSize: size,
      fontWeight: FontWeight.w600,
      letterSpacing: tracking,
      height: 1.2,
      color: color ?? Palette.inkSoft,
    );
  }

  static TextStyle body(
    double size, {
    Color? color,
    double height = 1.55,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: sans,
      fontSize: size,
      height: height,
      fontWeight: weight,
      color: color ?? Palette.inkSoft,
    );
  }

  static TextStyle ui(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w500,
    double height = 1.3,
  }) {
    return TextStyle(
      fontFamily: sans,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? Palette.ink,
    );
  }
}
