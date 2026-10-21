import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_text_styles.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

void main() {
  group('1. Design System Tokens: Colors, Spacing & Radius', () {
    test('AppColors brand and semantic palette matches design tokens', () {
      expect(AppColors.primary, equals(const Color(0xFF4338CA)));
      expect(AppColors.accent, equals(const Color(0xFF0EA5E9)));
      expect(AppColors.success, equals(const Color(0xFF059669)));
      expect(AppColors.warning, equals(const Color(0xFFD97706)));
      expect(AppColors.error, equals(const Color(0xFFDC2626)));
      expect(AppColors.info, equals(const Color(0xFF2563EB)));

      expect(AppColors.slate900, equals(const Color(0xFF0F172A)));
      expect(AppColors.backgroundLight, equals(AppColors.slate50));
      expect(AppColors.backgroundDark, equals(AppColors.slate900));
    });

    test('AppSpacing values are properly structured', () {
      expect(AppSpacing.space4, equals(4.0));
      expect(AppSpacing.space8, equals(8.0));
      expect(AppSpacing.space12, equals(12.0));
      expect(AppSpacing.space16, equals(16.0));
      expect(AppSpacing.space20, equals(20.0));
      expect(AppSpacing.space24, equals(24.0));
      expect(AppSpacing.space32, equals(32.0));
      expect(AppSpacing.space40, equals(40.0));

      expect(AppSpacing.screenPadding, equals(const EdgeInsets.all(16.0)));
      expect(AppSpacing.cardPadding, equals(const EdgeInsets.all(16.0)));
    });

    test('AppRadius tokens and BorderRadius helpers are valid', () {
      expect(AppRadius.radius4, equals(4.0));
      expect(AppRadius.radius6, equals(6.0));
      expect(AppRadius.radius10, equals(10.0));
      expect(AppRadius.radius14, equals(14.0));
      expect(AppRadius.radiusFull, equals(999.0));

      expect(AppRadius.card, equals(BorderRadius.circular(14.0)));
      expect(AppRadius.button, equals(BorderRadius.circular(10.0)));
      expect(AppRadius.input, equals(BorderRadius.circular(10.0)));
    });

    test('AppTypography and AppTextStyles define clear scales', () {
      expect(AppTypography.headlineLarge.fontSize, equals(24.0));
      expect(AppTypography.titleMedium.fontSize, equals(16.0));
      expect(AppTypography.bodyMedium.fontSize, equals(14.0));

      expect(AppTextStyles.kpiValue.fontSize, equals(26.0));
      expect(AppTextStyles.kpiValue.fontWeight, equals(FontWeight.w700));
    });
  });

  group('2. AppTheme ThemeData Validation', () {
    test(
      'AppTheme.lightTheme initializes complete Material 3 component themes',
      () {
        final theme = AppTheme.lightTheme;

        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, equals(Brightness.light));
        expect(theme.colorScheme.primary, equals(AppColors.primary));
        expect(
          theme.scaffoldBackgroundColor,
          equals(AppColors.backgroundLight),
        );

        expect(
          theme.appBarTheme.backgroundColor,
          equals(AppColors.surfaceLight),
        );
        expect(theme.cardTheme.color, equals(AppColors.cardSurfaceLight));
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(theme.elevatedButtonTheme.style, isNotNull);
        expect(theme.outlinedButtonTheme.style, isNotNull);
        expect(theme.textButtonTheme.style, isNotNull);
        expect(
          theme.dialogTheme.backgroundColor,
          equals(AppColors.dialogSurfaceLight),
        );
        expect(
          theme.navigationBarTheme.backgroundColor,
          equals(AppColors.surfaceLight),
        );
        expect(
          theme.navigationRailTheme.backgroundColor,
          equals(AppColors.surfaceLight),
        );
        expect(theme.chipTheme.backgroundColor, equals(AppColors.slate100));
      },
    );

    test('AppTheme.darkTheme initializes dark Material 3 component themes', () {
      final theme = AppTheme.darkTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.backgroundDark));
      expect(theme.cardTheme.color, equals(AppColors.cardSurfaceDark));
      expect(theme.appBarTheme.backgroundColor, equals(AppColors.surfaceDark));
    });
  });

  group('3. AppStatusBadge Component Widget Tests', () {
    testWidgets('Renders semantic badge variants with proper labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppStatusBadge.paid(),
                AppStatusBadge.pending(),
                AppStatusBadge.overdue(),
                AppStatusBadge.active(),
                AppStatusBadge.returned(),
                AppStatusBadge.inactive(),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Returned'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets(
      'AppStatusBadge.fromString correctly parses raw database strings',
      (tester) async {
        final paidBadge = AppStatusBadge.fromString('paid');
        final overdueBadge = AppStatusBadge.fromString('OVERDUE');
        final borrowedBadge = AppStatusBadge.fromString(
          'borrowed',
          customLabel: 'On Loan',
        );

        expect(paidBadge.status, equals(BadgeStatus.paid));
        expect(overdueBadge.status, equals(BadgeStatus.overdue));
        expect(borrowedBadge.status, equals(BadgeStatus.active));
        expect(borrowedBadge.label, equals('On Loan'));
      },
    );
  });

  group('4. ResponsiveContent Component Widget Tests', () {
    testWidgets('ResponsiveContent constrains maxWidth and centers child', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContent.form(
              child: Text('Constrained Form Content'),
            ),
          ),
        ),
      );

      expect(find.text('Constrained Form Content'), findsOneWidget);

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(ResponsiveContent),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(constrainedBox.constraints.maxWidth, equals(560.0));
    });

    testWidgets(
      'AppBreakpoints helper calculations evaluate accurately across viewports',
      (tester) async {
        late bool mobileCheck;
        late bool tabletCheck;
        late bool desktopCheck;
        late int gridCols;

        Widget buildProbe() {
          return Builder(
            builder: (context) {
              mobileCheck = ResponsiveContent.isMobile(context);
              tabletCheck = ResponsiveContent.isTablet(context);
              desktopCheck = ResponsiveContent.isDesktop(context);
              gridCols = ResponsiveContent.responsiveGridColumns(context);
              return const SizedBox.shrink();
            },
          );
        }

        // 1. Mobile viewport (400px)
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(MaterialApp(home: buildProbe()));

        expect(mobileCheck, isTrue);
        expect(tabletCheck, isFalse);
        expect(desktopCheck, isFalse);
        expect(gridCols, equals(1));

        // 2. Tablet viewport (800px)
        tester.view.physicalSize = const Size(800, 1000);
        await tester.pumpWidget(MaterialApp(home: buildProbe()));

        expect(mobileCheck, isFalse);
        expect(tabletCheck, isTrue);
        expect(desktopCheck, isFalse);
        expect(gridCols, equals(2));

        // 3. Desktop viewport (1200px)
        tester.view.physicalSize = const Size(1200, 900);
        await tester.pumpWidget(MaterialApp(home: buildProbe()));

        expect(mobileCheck, isFalse);
        expect(tabletCheck, isFalse);
        expect(desktopCheck, isTrue);
        expect(gridCols, equals(4));

        tester.view.resetPhysicalSize();
      },
    );

    testWidgets(
      'ResponsiveBuilder and breakpoints evaluate correctly across all 8 representative viewports (320, 360, 390, 600, 768, 1024, 1280, 1440)',
      (tester) async {
        final expectedResults = <double, ResponsiveDeviceType>{
          320.0: ResponsiveDeviceType.mobile,
          360.0: ResponsiveDeviceType.mobile,
          390.0: ResponsiveDeviceType.mobile,
          600.0: ResponsiveDeviceType.tablet,
          768.0: ResponsiveDeviceType.tablet,
          1024.0: ResponsiveDeviceType.desktop,
          1280.0: ResponsiveDeviceType.desktop,
          1440.0: ResponsiveDeviceType.desktop,
        };

        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        for (final entry in expectedResults.entries) {
          final width = entry.key;
          final expectedType = entry.value;

          tester.view.physicalSize = Size(width, 800);

          ResponsiveDeviceType? observedType;
          double? observedWidth;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ResponsiveBuilder(
                  builder: (context, constraints, deviceType) {
                    observedType = deviceType;
                    observedWidth = constraints.maxWidth;
                    return Text('Width: ${constraints.maxWidth}');
                  },
                ),
              ),
            ),
          );

          expect(
            observedType,
            equals(expectedType),
            reason: 'Viewport width $width should resolve to $expectedType',
          );
          expect(
            observedWidth,
            equals(width),
            reason: 'Constraints width should match physical width $width',
          );
        }
      },
    );
  });
}
