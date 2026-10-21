import 'package:material_ui/material_ui.dart';
import 'package:student_management/core/constants/app_spacing.dart';

/// Standard screen breakpoint thresholds in logical pixels.
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 600.0;
  static const double tablet = 1024.0;
  static const double desktop = 1440.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}

/// A responsive wrapper widget that centers content and constrains its maximum
/// width on wide tablet and desktop screens while applying adaptive padding.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxContentWidth;
  final EdgeInsets? padding;
  final AlignmentGeometry alignment;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxContentWidth = 1200.0,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Factory for form pages (Login, Create Student, Edit Staff) where narrow
  /// readability is desired.
  const ResponsiveContent.form({
    super.key,
    required this.child,
    this.maxContentWidth = 560.0,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Factory for dashboards, reports, and table layouts.
  const ResponsiveContent.dashboard({
    super.key,
    required this.child,
    this.maxContentWidth = 1280.0,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Factory for dialogs and modal content.
  const ResponsiveContent.dialog({
    super.key,
    required this.child,
    this.maxContentWidth = 500.0,
    this.padding,
    this.alignment = Alignment.center,
  });

  /// Static helper to determine if current viewport is mobile width (<600px).
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppBreakpoints.mobile;

  /// Static helper to determine if current viewport is tablet width (600px–1024px).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppBreakpoints.mobile && width < AppBreakpoints.tablet;
  }

  /// Static helper to determine if current viewport is desktop width (>=1024px).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.tablet;

  /// Helper calculating responsive grid column count for card grids.
  static int responsiveGridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 4,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.tablet) return desktop;
    if (width >= AppBreakpoints.mobile) return tablet;
    return mobile;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final EdgeInsets resolvedPadding;
    if (padding != null) {
      resolvedPadding = padding!;
    } else if (screenWidth < AppBreakpoints.mobile) {
      resolvedPadding = AppSpacing.screenPadding;
    } else if (screenWidth < AppBreakpoints.tablet) {
      resolvedPadding = const EdgeInsets.symmetric(
        horizontal: AppSpacing.space24,
        vertical: AppSpacing.space20,
      );
    } else {
      resolvedPadding = const EdgeInsets.symmetric(
        horizontal: AppSpacing.space32,
        vertical: AppSpacing.space24,
      );
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}

/// Device classification according to project breakpoint thresholds.
enum ResponsiveDeviceType {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == ResponsiveDeviceType.mobile;
  bool get isTablet => this == ResponsiveDeviceType.tablet;
  bool get isDesktop => this == ResponsiveDeviceType.desktop;
}

/// Callback for [ResponsiveBuilder] providing constraints and device type.
typedef ResponsiveWidgetBuilder =
    Widget Function(
      BuildContext context,
      BoxConstraints constraints,
      ResponsiveDeviceType deviceType,
    );

/// A utility widget that provides device classification and constraints
/// via [LayoutBuilder] to eliminate scattered, hardcoded width checks.
class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType =
            constraints.maxWidth < AppBreakpoints.mobile
                ? ResponsiveDeviceType.mobile
                : constraints.maxWidth < AppBreakpoints.tablet
                ? ResponsiveDeviceType.tablet
                : ResponsiveDeviceType.desktop;

        return builder(context, constraints, deviceType);
      },
    );
  }
}
