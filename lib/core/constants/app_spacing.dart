import 'package:material_ui/material_ui.dart';

/// Centralized layout spacing tokens and EdgeInsets helpers.
class AppSpacing {
  AppSpacing._();

  // Raw spacing values in logical pixels
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Semantic spacing names
  static const double xs = space4;
  static const double sm = space8;
  static const double md = space12;
  static const double lg = space16;
  static const double xl = space20;
  static const double xxl = space24;
  static const double xxxl = space32;
  static const double section = space40;

  // Shorthand spacing tokens
  static const double s4 = space4;
  static const double s8 = space8;
  static const double s12 = space12;
  static const double s16 = space16;
  static const double s20 = space20;
  static const double s24 = space24;
  static const double s32 = space32;
  static const double s40 = space40;
  static const double s48 = space48;

  // EdgeInsets helpers
  static const EdgeInsets zero = EdgeInsets.zero;
  static const EdgeInsets paddingAll4 = EdgeInsets.all(space4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(space8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(space12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(space16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(space20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(space24);
  static const EdgeInsets paddingAll32 = EdgeInsets.all(space32);

  // Shorthand padding aliases
  static const EdgeInsets paddingA4 = paddingAll4;
  static const EdgeInsets paddingA8 = paddingAll8;
  static const EdgeInsets paddingA12 = paddingAll12;
  static const EdgeInsets paddingA16 = paddingAll16;
  static const EdgeInsets paddingA20 = paddingAll20;
  static const EdgeInsets paddingA24 = paddingAll24;
  static const EdgeInsets paddingA32 = paddingAll32;

  static const EdgeInsets paddingH8 = EdgeInsets.symmetric(horizontal: space8);
  static const EdgeInsets paddingH12 = EdgeInsets.symmetric(
    horizontal: space12,
  );
  static const EdgeInsets paddingH16 = EdgeInsets.symmetric(
    horizontal: space16,
  );
  static const EdgeInsets paddingH24 = EdgeInsets.symmetric(
    horizontal: space24,
  );

  static const EdgeInsets paddingV8 = EdgeInsets.symmetric(vertical: space8);
  static const EdgeInsets paddingV12 = EdgeInsets.symmetric(vertical: space12);
  static const EdgeInsets paddingV16 = EdgeInsets.symmetric(vertical: space16);
  static const EdgeInsets paddingV24 = EdgeInsets.symmetric(vertical: space24);

  // Screen padding standard
  static const EdgeInsets screenPadding = EdgeInsets.all(space16);
  static const EdgeInsets cardPadding = EdgeInsets.all(space16);
  static const EdgeInsets dialogPadding = EdgeInsets.all(space24);

  // SizedBox vertical gap helpers
  static const SizedBox gapH4 = SizedBox(height: space4);
  static const SizedBox gapH8 = SizedBox(height: space8);
  static const SizedBox gapH12 = SizedBox(height: space12);
  static const SizedBox gapH16 = SizedBox(height: space16);
  static const SizedBox gapH20 = SizedBox(height: space20);
  static const SizedBox gapH24 = SizedBox(height: space24);
  static const SizedBox gapH32 = SizedBox(height: space32);
  static const SizedBox gapH40 = SizedBox(height: space40);

  // SizedBox horizontal gap helpers
  static const SizedBox gapW4 = SizedBox(width: space4);
  static const SizedBox gapW8 = SizedBox(width: space8);
  static const SizedBox gapW12 = SizedBox(width: space12);
  static const SizedBox gapW16 = SizedBox(width: space16);
  static const SizedBox gapW20 = SizedBox(width: space20);
  static const SizedBox gapW24 = SizedBox(width: space24);
  static const SizedBox gapW32 = SizedBox(width: space32);
}
