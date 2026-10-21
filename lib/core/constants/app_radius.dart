import 'package:material_ui/material_ui.dart';

/// Centralized border radius tokens and BorderRadius helpers.
class AppRadius {
  AppRadius._();

  // Raw radius values in logical pixels
  static const double radius4 = 4.0;
  static const double radius6 = 6.0;
  static const double radius8 = 8.0;
  static const double radius10 = 10.0;
  static const double radius12 = 12.0;
  static const double radius14 = 14.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radiusFull = 999.0;

  // Semantic radius aliases
  static const double xs = radius4;
  static const double sm = radius6;
  static const double md = radius10;
  static const double lg = radius14;
  static const double xl = radius20;
  static const double xxl = radius24;
  static const double pill = radiusFull;

  // Shorthand radius tokens
  static const double r4 = radius4;
  static const double r6 = radius6;
  static const double r8 = radius8;
  static const double r10 = radius10;
  static const double r12 = radius12;
  static const double r14 = radius14;
  static const double r16 = radius16;
  static const double r20 = radius20;
  static const double r24 = radius24;
  static const double rFull = radiusFull;

  // BorderRadius helpers
  static const BorderRadius zero = BorderRadius.zero;
  static final BorderRadius roundedXs = BorderRadius.circular(radius4);
  static final BorderRadius roundedSm = BorderRadius.circular(radius6);
  static final BorderRadius roundedMd = BorderRadius.circular(radius10);
  static final BorderRadius roundedLg = BorderRadius.circular(radius14);
  static final BorderRadius roundedXl = BorderRadius.circular(radius20);
  static final BorderRadius roundedXxl = BorderRadius.circular(radius24);
  static final BorderRadius roundedFull = BorderRadius.circular(radiusFull);

  // Component-specific border radii
  static final BorderRadius card = BorderRadius.circular(radius14);
  static final BorderRadius button = BorderRadius.circular(radius10);
  static final BorderRadius input = BorderRadius.circular(radius10);
  static final BorderRadius dialog = BorderRadius.circular(radius16);
  static final BorderRadius badge = BorderRadius.circular(radiusFull);
  static final BorderRadius bottomSheet = const BorderRadius.vertical(
    top: Radius.circular(radius20),
  );
}
