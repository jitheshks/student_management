import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/features/fees/domain/repositories/i_fees_repository.dart';
import 'package:student_management/features/fees/presentation/providers/fees_providers.dart';
import 'package:student_management/features/fees/presentation/screens/fees_dashboard_screen.dart';
import 'package:student_management/shared/models/fee_record.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/empty_state_view.dart';
import 'package:student_management/shared/widgets/error_view.dart';

class FakeFeesRepository implements IFeesRepository {
  FeesSummary summary;
  List<FeeRecord> records;
  bool shouldThrowSummaryError;
  bool shouldThrowRecordsError;

  FakeFeesRepository({
    FeesSummary? summary,
    List<FeeRecord>? records,
    this.shouldThrowSummaryError = false,
    this.shouldThrowRecordsError = false,
  }) : summary =
           summary ??
           const FeesSummary(
             totalCollected: 450000.0,
             totalPending: 150000.0,
             totalOverdue: 50000.0,
             totalStudents: 120,
             paidStudentsCount: 90,
           ),
       records = records ?? _defaultRecords();

  static List<FeeRecord> _defaultRecords() => [
    FeeRecord(
      id: 'fee-1',
      studentId: '10800001',
      title: 'Annual Tuition Fee',
      amount: 50000.0,
      paidAmount: 50000.0,
      dueAmount: 0.0,
      academicYear: '2025-2026',
      dueDate: DateTime(2026, 8, 15),
      paidDate: DateTime(2026, 8, 10),
      status: FeeStatus.paid,
      receiptNumber: 'REC-9001',
    ),
    FeeRecord(
      id: 'fee-2',
      studentId: '10800002',
      title: 'Laboratory Fee',
      amount: 15000.0,
      paidAmount: 5000.0,
      dueAmount: 10000.0,
      academicYear: '2025-2026',
      dueDate: DateTime(2026, 11, 30),
      paidDate: null,
      status: FeeStatus.pending,
      receiptNumber: null,
    ),
    FeeRecord(
      id: 'fee-3',
      studentId: '10800003',
      title: 'Library Security Deposit',
      amount: 8000.0,
      paidAmount: 0.0,
      dueAmount: 8000.0,
      academicYear: '2025-2026',
      dueDate: DateTime(2026, 9, 1),
      paidDate: null,
      status: FeeStatus.overdue,
      receiptNumber: null,
    ),
  ];

  @override
  Future<FeesSummary> getInstitutionalFeesSummary() async {
    if (shouldThrowSummaryError) {
      throw Exception('Database connection failure for summary.');
    }
    return summary;
  }

  @override
  Future<List<FeeRecord>> getAllFeeRecords() async {
    if (shouldThrowRecordsError) {
      throw Exception('Database query failure for records.');
    }
    return records;
  }

  @override
  Future<List<FeeRecord>> getStudentFeeRecords(String studentId) async {
    return records.where((r) => r.studentId == studentId).toList();
  }
}

void main() {
  const targetWidths = [
    320.0,
    360.0,
    390.0,
    600.0,
    768.0,
    1024.0,
    1280.0,
    1440.0,
  ];

  Widget buildTestApp({
    required Widget child,
    required FakeFeesRepository feesRepo,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return ProviderScope(
      overrides: [feesRepositoryProvider.overrideWithValue(feesRepo)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: child,
      ),
    );
  }

  group('Batch 6: Fees Dashboard Responsive UI Tests', () {
    testWidgets(
      '1. FeesDashboardScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final repo = FakeFeesRepository();

          await tester.pumpWidget(
            buildTestApp(
              child: FeesDashboardScreen(key: ValueKey('fees-$width')),
              feesRepo: repo,
            ),
          );

          await tester.pumpAndSettle();

          // Verify Header
          expect(find.text('Fees Management'), findsOneWidget);
          expect(find.text('Financial Overview'), findsOneWidget);

          // Verify 4 KPI Cards
          expect(find.text('Billed'), findsWidgets);
          expect(find.text('Collected'), findsWidgets);
          expect(find.text('Outstanding'), findsWidgets);
          expect(find.text('Overdue'), findsWidgets);

          // Verify calculations: Billed is totalCollected + totalPending = 600,000
          expect(find.text('₹600,000'), findsOneWidget);
          expect(find.text('₹450,000'), findsOneWidget);
          expect(find.text('₹150,000'), findsOneWidget);
          expect(find.text('₹50,000'), findsWidgets);

          // Verify Filter Chips
          expect(find.text('All'), findsOneWidget);
          expect(find.text('Paid'), findsWidgets);
          expect(find.text('Pending'), findsWidgets);

          // Verify Fee Records
          expect(find.text('Annual Tuition Fee'), findsOneWidget);
          expect(find.text('Laboratory Fee'), findsOneWidget);
          expect(find.text('Library Security Deposit'), findsOneWidget);

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '2. KPI Cards handle large currency values (₹999,999,999) on narrow 320px viewport without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final hugeSummary = const FeesSummary(
          totalCollected: 750000000.0,
          totalPending: 249999999.0,
          totalOverdue: 99999999.0,
          totalStudents: 50000,
          paidStudentsCount: 38000,
        );

        final repo = FakeFeesRepository(summary: hugeSummary);

        await tester.pumpWidget(
          buildTestApp(child: const FeesDashboardScreen(), feesRepo: repo),
        );

        await tester.pumpAndSettle();

        expect(find.text('Billed'), findsWidgets);
        expect(find.text('₹999,999,999'), findsOneWidget);
        expect(find.text('₹750,000,000'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. Status filter chips filter records correctly on narrow 320px viewport',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = FakeFeesRepository();

        await tester.pumpWidget(
          buildTestApp(child: const FeesDashboardScreen(), feesRepo: repo),
        );

        await tester.pumpAndSettle();

        // Initially 'All' shows all 3 records
        expect(find.text('Annual Tuition Fee'), findsOneWidget);
        expect(find.text('Laboratory Fee'), findsOneWidget);
        expect(find.text('Library Security Deposit'), findsOneWidget);

        // Tap 'Paid' filter
        await tester.tap(find.widgetWithText(FilterChip, 'Paid'));
        await tester.pumpAndSettle();

        expect(find.text('Annual Tuition Fee'), findsOneWidget);
        expect(find.text('Laboratory Fee'), findsNothing);
        expect(find.text('Library Security Deposit'), findsNothing);

        // Tap 'Pending' filter
        await tester.tap(find.widgetWithText(FilterChip, 'Pending'));
        await tester.pumpAndSettle();

        expect(find.text('Annual Tuition Fee'), findsNothing);
        expect(find.text('Laboratory Fee'), findsOneWidget);
        expect(find.text('Library Security Deposit'), findsNothing);

        // Tap 'Overdue' filter
        await tester.tap(find.widgetWithText(FilterChip, 'Overdue'));
        await tester.pumpAndSettle();

        expect(find.text('Annual Tuition Fee'), findsNothing);
        expect(find.text('Laboratory Fee'), findsNothing);
        expect(find.text('Library Security Deposit'), findsOneWidget);

        // Tap 'All' filter to restore
        await tester.tap(find.widgetWithText(FilterChip, 'All'));
        await tester.pumpAndSettle();

        expect(find.text('Annual Tuition Fee'), findsOneWidget);
        expect(find.text('Laboratory Fee'), findsOneWidget);
        expect(find.text('Library Security Deposit'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '4. Search bar filters fee records by student ID, fee title, and receipt number',
      (tester) async {
        tester.view.physicalSize = const Size(360, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = FakeFeesRepository();

        await tester.pumpWidget(
          buildTestApp(child: const FeesDashboardScreen(), feesRepo: repo),
        );

        await tester.pumpAndSettle();

        // Search by student ID '10800002'
        await tester.enterText(find.byType(TextField).first, '10800002');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.text('Laboratory Fee'), findsOneWidget);
        expect(find.text('Annual Tuition Fee'), findsNothing);

        // Search by receipt 'REC-9001'
        await tester.enterText(find.byType(TextField).first, 'REC-9001');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.text('Annual Tuition Fee'), findsOneWidget);
        expect(find.text('Laboratory Fee'), findsNothing);

        // Clear search
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        expect(find.text('Annual Tuition Fee'), findsOneWidget);
        expect(find.text('Laboratory Fee'), findsOneWidget);
        expect(find.text('Library Security Deposit'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5. Empty state view renders properly when search has no matching records',
      (tester) async {
        tester.view.physicalSize = const Size(360, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = FakeFeesRepository();

        await tester.pumpWidget(
          buildTestApp(child: const FeesDashboardScreen(), feesRepo: repo),
        );

        await tester.pumpAndSettle();

        // Search query with no matches
        await tester.enterText(find.byType(TextField).first, 'nonexistent_fee');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.byType(EmptyStateView), findsOneWidget);
        expect(find.text('No fee records found'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '6. Error state view renders properly with Retry functionality on failure',
      (tester) async {
        tester.view.physicalSize = const Size(360, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = FakeFeesRepository(shouldThrowRecordsError: true);

        await tester.pumpWidget(
          buildTestApp(child: const FeesDashboardScreen(), feesRepo: repo),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ErrorView), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);

        // Resolve error and tap Try Again
        repo.shouldThrowRecordsError = false;
        await tester.tap(find.text('Try Again'));
        await tester.pumpAndSettle();

        expect(find.byType(ErrorView), findsNothing);
        expect(find.text('Annual Tuition Fee'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7. Dark mode and mobile landscape (800x400) render cleanly with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(800, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = FakeFeesRepository();

        await tester.pumpWidget(
          buildTestApp(
            child: const FeesDashboardScreen(),
            feesRepo: repo,
            themeMode: ThemeMode.dark,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Fees Management'), findsOneWidget);
        expect(find.text('Billed'), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('Annual Tuition Fee'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Annual Tuition Fee'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '8. FeesDashboardScreen is strictly read-only with no payment collection or mutation buttons',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = FakeFeesRepository();

        await tester.pumpWidget(
          buildTestApp(child: const FeesDashboardScreen(), feesRepo: repo),
        );

        await tester.pumpAndSettle();

        // Verify strictly read-only: No Pay, Collect, Edit, Delete, or Add buttons
        expect(find.text('Pay Now'), findsNothing);
        expect(find.text('Collect Fee'), findsNothing);
        expect(find.text('Assign Fee'), findsNothing);
        expect(find.text('Edit Fee'), findsNothing);
        expect(find.text('Delete Fee'), findsNothing);
        expect(find.byType(FloatingActionButton), findsNothing);

        // Verify semantic badges
        expect(find.byType(AppStatusBadge), findsNWidgets(3));

        expect(tester.takeException(), isNull);
      },
    );
  });
}
