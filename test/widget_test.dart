import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/shared/models/student.dart';
import 'package:student_management/shared/models/book.dart';
import 'package:student_management/shared/models/borrow_record.dart';
import 'package:student_management/shared/models/fee_record.dart';
import 'package:student_management/shared/widgets/app_button.dart';

void main() {
  group('Phase 0 Foundation Tests', () {
    testWidgets('ProviderScope and AppButton render properly', (WidgetTester tester) async {
      bool buttonTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: AppButton(
                  text: 'Test Button',
                  onPressed: () {
                    buttonTapped = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      await tester.pump();
      expect(buttonTapped, isTrue);
    });

    test('Domain models serialize and deserialize correctly', () {
      final student = Student(
        id: 'std-1',
        userId: 'uid-1',
        name: 'John Doe',
        registerNumber: 'REG1001',
        standard: '10th',
      );

      final studentJson = student.toJson();
      final parsedStudent = Student.fromJson(studentJson);
      expect(parsedStudent.name, equals('John Doe'));
      expect(parsedStudent.registerNumber, equals('REG1001'));

      final book = Book(
        id: 'b-1',
        title: 'Flutter in Action',
        author: 'Eric Windmill',
        isbn: '9781617296147',
        coverUrl: 'https://example.com/cover.jpg',
        copies: 5,
      );

      final bookJson = book.toJson();
      final parsedBook = Book.fromJson(bookJson);
      expect(parsedBook.title, equals('Flutter in Action'));
      expect(parsedBook.copies, equals(5));

      final borrowRecord = BorrowRecord(
        id: 'br-1',
        userId: 'uid-1',
        studentRegisterNumber: 'REG1001',
        bookId: 'b-1',
        bookTitle: 'Flutter in Action',
        bookAuthor: 'Eric Windmill',
        coverUrl: 'https://example.com/cover.jpg',
        isbn: '9781617296147',
        borrowedAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 14)),
      );

      expect(borrowRecord.isReturned, isFalse);
      expect(borrowRecord.status, equals(BorrowStatus.borrowed));
    });

    test('FeeRecord domain model maps Supabase fee_records schema correctly', () {
      final rawDbRow = {
        'id': 'fee-123',
        'student_id': 'std-999',
        'amount': 25000.0,
        'paid_amount': 15000.0,
        'due_amount': 10000.0,
        'status': 'unpaid',
        'installment_no': 2,
        'academic_year': '2025-2026',
        'paid_on': null,
      };

      final feeRecord = FeeRecord.fromJson(rawDbRow);
      expect(feeRecord.id, equals('fee-123'));
      expect(feeRecord.studentId, equals('std-999'));
      expect(feeRecord.amount, equals(25000.0));
      expect(feeRecord.paidAmount, equals(15000.0));
      expect(feeRecord.dueAmount, equals(10000.0));
      expect(feeRecord.status, equals(FeeStatus.pending));
      expect(feeRecord.installmentNo, equals(2));
      expect(feeRecord.academicYear, equals('2025-2026'));
      expect(feeRecord.title, contains('Installment 2 (2025-2026)'));
    });
  });
}
