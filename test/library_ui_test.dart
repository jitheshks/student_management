import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/features/library/domain/repositories/i_library_repository.dart';
import 'package:student_management/features/library/presentation/providers/library_providers.dart';
import 'package:student_management/features/library/presentation/screens/book_search_dialog.dart';
import 'package:student_management/features/library/presentation/screens/borrow_book_screen.dart';
import 'package:student_management/features/library/presentation/screens/library_history_screen.dart';
import 'package:student_management/features/library/presentation/screens/library_management_screen.dart';
import 'package:student_management/features/library/presentation/screens/return_book_screen.dart';
import 'package:student_management/features/students/domain/repositories/i_student_repository.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/shared/models/book.dart';
import 'package:student_management/shared/models/borrow_record.dart';
import 'package:student_management/shared/models/student.dart';
import 'package:student_management/shared/widgets/app_card.dart';

class FakeStudentRepository implements IStudentRepository {
  final List<Student> students = [
    Student(
      id: 'std-1',
      userId: 'auth-std-1',
      firstName: 'Alice',
      lastName: 'Smith',
      registerNumber: '10800001',
      standard: '10th',
      email: 'alice@school.com',
      phone: '1234567890',
      address: '123 Maple St',
      dob: DateTime(2008, 5, 12),
    ),
    Student(
      id: 'std-2',
      userId: 'auth-std-2',
      firstName: 'Bob',
      lastName: 'Jones',
      registerNumber: '10800002',
      standard: '9th',
      email: 'bob@school.com',
      phone: '9876543210',
      address: '456 Oak Ave',
      dob: DateTime(2009, 8, 20),
    ),
  ];

  @override
  Future<Student?> getStudentByRegisterNumber(String registerNumber) async {
    final match = students.where((s) => s.registerNumber == registerNumber);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<List<Student>> getStudents({
    String? standard,
    String? searchQuery,
    String? sortOrder = 'A-Z',
  }) async {
    return students;
  }

  @override
  Future<Student> getStudentById(String id) async =>
      students.firstWhere((s) => s.id == id);

  @override
  Future<void> createStudent({
    required Student student,
    required String password,
    File? avatarFile,
  }) async {}

  @override
  Future<void> updateStudent({
    required Student student,
    File? avatarFile,
  }) async {}

  @override
  Future<void> deleteStudent({
    required String studentId,
    required String authId,
    String? email,
  }) async {}

  @override
  Future<Map<String, int>> bulkDeleteStudents(List<Student> students) async => {
    'success': students.length,
    'fail': 0,
  };

  @override
  Future<String> generateNextRegisterNumber() async => '10800099';
}

class FakeLibraryRepository implements ILibraryRepository {
  final List<Book> books = [
    Book(
      id: 'bk-1',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      isbn: '9780743273565',
      coverUrl: '',
      copies: 5,
    ),
    Book(
      id: 'bk-2',
      title: '1984',
      author: 'George Orwell',
      isbn: '9780451524935',
      coverUrl: '',
      copies: 3,
    ),
    Book(
      id: 'bk-3',
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      isbn: '9780061120084',
      coverUrl: '',
      copies: 1,
    ),
  ];

  final List<BorrowRecord> borrowRecords = [
    BorrowRecord(
      id: 'rec-1',
      bookId: 'bk-1',
      bookTitle: 'The Great Gatsby',
      bookAuthor: 'F. Scott Fitzgerald',
      isbn: '9780743273565',
      coverUrl: '',
      userId: 'auth-std-1',
      studentRegisterNumber: '10800001',
      studentName: 'Alice Smith',
      standard: '10th',
      borrowedAt: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: DateTime.now().add(const Duration(days: 10)),
    ),
    BorrowRecord(
      id: 'rec-2',
      bookId: 'bk-2',
      bookTitle: '1984',
      bookAuthor: 'George Orwell',
      isbn: '9780451524935',
      coverUrl: '',
      userId: 'auth-std-2',
      studentRegisterNumber: '10800002',
      studentName: 'Bob Jones',
      standard: '9th',
      borrowedAt: DateTime(2026, 9, 1),
      dueDate: DateTime(2026, 9, 15),
      returnedAt: DateTime(2026, 9, 14),
    ),
    BorrowRecord(
      id: 'rec-3',
      bookId: 'bk-1',
      bookTitle: 'The Great Gatsby',
      bookAuthor: 'F. Scott Fitzgerald',
      isbn: '9780743273565',
      coverUrl: '',
      userId: 'auth-std-2',
      studentRegisterNumber: '10800002',
      studentName: 'Bob Jones',
      standard: '9th',
      borrowedAt: DateTime(2026, 8, 1),
      dueDate: DateTime(2026, 8, 15), // overdue
    ),
  ];

  @override
  Future<List<Book>> searchBooks(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return books;
    return books
        .where(
          (b) =>
              b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q) ||
              b.isbn.contains(q),
        )
        .toList();
  }

  @override
  Future<int> getAvailableBookCopies(String isbn) async {
    final book = books.firstWhere(
      (b) => b.isbn == isbn,
      orElse:
          () => Book(
            id: '',
            title: '',
            author: '',
            isbn: isbn,
            coverUrl: '',
            copies: 4,
          ),
    );
    final activeLoans =
        borrowRecords
            .where((r) => r.isbn == isbn && r.returnedAt == null)
            .length;
    return (book.copies - activeLoans).clamp(0, 9999);
  }

  @override
  Future<void> borrowBook({
    required String studentAuthId,
    required String studentRegisterNumber,
    required Book book,
    required DateTime dueDate,
  }) async {
    final available = await getAvailableBookCopies(book.isbn);
    if (available <= 0) {
      throw ValidationException(
        'No available copies left for "${book.title}".',
      );
    }

    final newRecord = BorrowRecord(
      id: 'rec-${borrowRecords.length + 1}',
      bookId: book.id,
      bookTitle: book.title,
      bookAuthor: book.author,
      isbn: book.isbn,
      coverUrl: book.coverUrl,
      userId: studentAuthId,
      studentRegisterNumber: studentRegisterNumber,
      studentName: 'Alice Smith',
      standard: '10th',
      borrowedAt: DateTime.now(),
      dueDate: dueDate,
    );
    borrowRecords.add(newRecord);
  }

  @override
  Future<List<BorrowRecord>> getActiveLoansForStudent(
    String registerNumber,
  ) async {
    return borrowRecords
        .where(
          (r) =>
              r.studentRegisterNumber == registerNumber && r.returnedAt == null,
        )
        .toList();
  }

  @override
  Future<void> returnBook({
    required String borrowRecordId,
    required String bookId,
  }) async {
    final index = borrowRecords.indexWhere((r) => r.id == borrowRecordId);
    if (index == -1) {
      throw NotFoundException('Borrow record not found.');
    }

    final old = borrowRecords[index];
    borrowRecords[index] = BorrowRecord(
      id: old.id,
      bookId: old.bookId,
      bookTitle: old.bookTitle,
      bookAuthor: old.bookAuthor,
      isbn: old.isbn,
      coverUrl: old.coverUrl,
      userId: old.userId,
      studentRegisterNumber: old.studentRegisterNumber,
      studentName: old.studentName,
      standard: old.standard,
      borrowedAt: old.borrowedAt,
      dueDate: old.dueDate,
      returnedAt: DateTime.now(),
    );
  }

  @override
  Future<List<BorrowRecord>> getGlobalBorrowHistory({
    String? standard,
    String? statusFilter,
    String? sortOrder = 'A-Z',
  }) async {
    List<BorrowRecord> records = List.from(borrowRecords);

    if (standard != null && standard != 'All') {
      records = records.where((r) => r.standard == standard).toList();
    }

    if (statusFilter != null && statusFilter != 'All') {
      records =
          records
              .where(
                (r) =>
                    r.status.displayName.toLowerCase() ==
                    statusFilter.toLowerCase(),
              )
              .toList();
    }

    switch (sortOrder) {
      case 'Z-A':
        records.sort(
          (a, b) =>
              b.bookTitle.toLowerCase().compareTo(a.bookTitle.toLowerCase()),
        );
        break;
      case 'Register Number ↑':
        records.sort(
          (a, b) => a.studentRegisterNumber.compareTo(b.studentRegisterNumber),
        );
        break;
      case 'Register Number ↓':
        records.sort(
          (a, b) => b.studentRegisterNumber.compareTo(a.studentRegisterNumber),
        );
        break;
      case 'Due Date ↑':
        records.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case 'Due Date ↓':
        records.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        break;
      case 'A-Z':
      default:
        records.sort(
          (a, b) =>
              a.bookTitle.toLowerCase().compareTo(b.bookTitle.toLowerCase()),
        );
        break;
    }

    return records;
  }

  @override
  Future<List<BorrowRecord>> getStudentBorrowHistory(
    String studentAuthId,
  ) async {
    return borrowRecords.where((r) => r.userId == studentAuthId).toList();
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
    FakeLibraryRepository? libraryRepo,
    FakeStudentRepository? studentRepo,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return ProviderScope(
      overrides: [
        if (libraryRepo != null)
          libraryRepositoryProvider.overrideWithValue(libraryRepo),
        if (studentRepo != null)
          studentRepositoryProvider.overrideWithValue(studentRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: child,
      ),
    );
  }

  group('Batch 5: Library Management Responsive UI Tests', () {
    testWidgets(
      '1. LibraryManagementScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final libRepo = FakeLibraryRepository();

          await tester.pumpWidget(
            buildTestApp(
              child: const LibraryManagementScreen(),
              libraryRepo: libRepo,
            ),
          );

          await tester.pumpAndSettle();

          expect(find.text('Library Management'), findsOneWidget);
          expect(find.text('Borrow Book'), findsOneWidget);
          expect(find.text('Return Book'), findsOneWidget);
          expect(find.text('Library History Page'), findsOneWidget);
          expect(find.byIcon(Icons.menu_book), findsOneWidget);
          expect(find.byIcon(Icons.assignment_returned), findsOneWidget);
          expect(find.byIcon(Icons.history), findsOneWidget);

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '2. LibraryManagementScreen handles mobile landscape (800x400) and dark mode cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(800, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final libRepo = FakeLibraryRepository();

        await tester.pumpWidget(
          buildTestApp(
            child: const LibraryManagementScreen(),
            libraryRepo: libRepo,
            themeMode: ThemeMode.dark,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Library Management'), findsOneWidget);
        expect(find.text('Borrow Book'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. BorrowBookScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final libRepo = FakeLibraryRepository();
          final stdRepo = FakeStudentRepository();

          await tester.pumpWidget(
            buildTestApp(
              child: const BorrowBookScreen(),
              libraryRepo: libRepo,
              studentRepo: stdRepo,
            ),
          );

          await tester.pumpAndSettle();

          expect(find.text('Borrow a Book'), findsOneWidget);
          expect(find.text('1. Select Book'), findsOneWidget);
          expect(find.text('2. Student Verification'), findsOneWidget);
          expect(find.text('3. Loan Due Date'), findsOneWidget);
          expect(find.text('Return Due Date'), findsOneWidget);
          expect(find.text('Tap to search and select a book'), findsOneWidget);

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '4. BorrowBookScreen verifies student, selects book and submits loan without overflow on 320px width',
      (tester) async {
        tester.view.physicalSize = const Size(320, 750);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final libRepo = FakeLibraryRepository();
        final stdRepo = FakeStudentRepository();

        await tester.pumpWidget(
          buildTestApp(
            child: const BorrowBookScreen(),
            libraryRepo: libRepo,
            studentRepo: stdRepo,
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify button is disabled for submit initially
        final submitFinder = find.widgetWithText(ElevatedButton, 'Borrow Book');
        expect(submitFinder, findsOneWidget);
        final submitBtn = tester.widget<ElevatedButton>(submitFinder);
        expect(submitBtn.onPressed, isNull);

        // 2. Verify student by entering registration number
        await tester.enterText(find.byType(TextFormField).first, '10800001');
        await tester.tap(find.text('Verify'));
        await tester.pumpAndSettle();

        expect(find.text('Alice Smith'), findsOneWidget);
        expect(find.text('Class: 10th  •  Reg: 10800001'), findsOneWidget);

        // 3. Select a book using controller provider
        final container = ProviderScope.containerOf(
          tester.element(find.byType(BorrowBookScreen)),
        );
        container
            .read(borrowBookControllerProvider.notifier)
            .setSelectedBook(libRepo.books.first);
        await tester.pumpAndSettle();

        expect(find.text('The Great Gatsby'), findsOneWidget);
        expect(find.text('by F. Scott Fitzgerald'), findsOneWidget);

        // 4. Submit button is now enabled
        final enabledSubmit = tester.widget<ElevatedButton>(submitFinder);
        expect(enabledSubmit.onPressed, isNotNull);

        // 5. Submit borrow
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5. BookSearchDialog renders cleanly and performs catalog search across viewports',
      (tester) async {
        for (final width in [320.0, 768.0, 1024.0]) {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final libRepo = FakeLibraryRepository();

          await tester.pumpWidget(
            buildTestApp(
              child: BookSearchDialog(key: ValueKey('dialog-$width')),
              libraryRepo: libRepo,
            ),
          );

          await tester.pumpAndSettle();

          expect(find.text('Search Books'), findsOneWidget);
          expect(find.text('Search the Catalog'), findsOneWidget);

          // Enter search query
          await tester.enterText(find.byType(TextField), 'Gatsby');
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pumpAndSettle();

          expect(find.text('The Great Gatsby'), findsOneWidget);
          expect(find.text('by F. Scott Fitzgerald'), findsOneWidget);

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '6. ReturnBookScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final libRepo = FakeLibraryRepository();
          final stdRepo = FakeStudentRepository();

          await tester.pumpWidget(
            buildTestApp(
              child: const ReturnBookScreen(),
              libraryRepo: libRepo,
              studentRepo: stdRepo,
            ),
          );

          await tester.pumpAndSettle();

          expect(find.text('Return Books'), findsOneWidget);
          expect(find.text('Enter Registration Number'), findsOneWidget);
          expect(
            find.text(
              'Enter a student registration number\nto view active borrowed books.',
            ),
            findsOneWidget,
          );

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '7. ReturnBookScreen searches student loans, displays overdue badges, and handles return dialog on 320px width',
      (tester) async {
        tester.view.physicalSize = const Size(320, 750);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final libRepo = FakeLibraryRepository();
        final stdRepo = FakeStudentRepository();

        await tester.pumpWidget(
          buildTestApp(
            child: const ReturnBookScreen(),
            libraryRepo: libRepo,
            studentRepo: stdRepo,
          ),
        );

        await tester.pumpAndSettle();

        // Search for student with active overdue loan
        await tester.enterText(find.byType(TextFormField).first, '10800002');
        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();

        // The active loan card should appear
        expect(find.text('The Great Gatsby'), findsOneWidget);
        expect(find.text('by F. Scott Fitzgerald'), findsOneWidget);
        expect(find.text('OVERDUE'), findsOneWidget);
        expect(find.text('Return Book'), findsOneWidget);

        // Tap Return Book to trigger confirmation dialog
        await tester.tap(find.text('Return Book'));
        await tester.pumpAndSettle();

        expect(find.text('Confirm Book Return'), findsOneWidget);
        expect(
          find.text(
            'Are you sure you want to mark "The Great Gatsby" as returned?',
          ),
          findsOneWidget,
        );

        // Confirm return
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Return Book').last,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '8. LibraryHistoryScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final libRepo = FakeLibraryRepository();
          final stdRepo = FakeStudentRepository();

          await tester.pumpWidget(
            buildTestApp(
              child: const LibraryHistoryScreen(),
              libraryRepo: libRepo,
              studentRepo: stdRepo,
            ),
          );

          await tester.pumpAndSettle();

          expect(find.text('Library History'), findsOneWidget);
          expect(find.text('The Great Gatsby'), findsWidgets);
          expect(find.text('1984'), findsOneWidget);
          expect(find.text('Alice Smith (10800001)'), findsOneWidget);
          expect(find.text('Bob Jones (10800002)'), findsWidgets);
          expect(find.text('Class: 10th'), findsOneWidget);
          expect(find.text('Borrowed'), findsOneWidget);
          expect(find.text('Returned'), findsOneWidget);
          expect(find.text('Overdue'), findsOneWidget);

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '9. LibraryHistoryScreen search and filtering work on narrow (320px) viewport without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final libRepo = FakeLibraryRepository();
        final stdRepo = FakeStudentRepository();

        await tester.pumpWidget(
          buildTestApp(
            child: const LibraryHistoryScreen(),
            libraryRepo: libRepo,
            studentRepo: stdRepo,
          ),
        );

        await tester.pumpAndSettle();

        // Search for '1984'
        await tester.enterText(find.byType(TextField).first, '1984');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppCard, '1984'), findsOneWidget);
        expect(find.text('The Great Gatsby'), findsNothing);

        // Clear search
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        expect(find.text('The Great Gatsby'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '10. LibraryHistoryScreen mobile landscape (800x400) and dark mode render cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(800, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final libRepo = FakeLibraryRepository();
        final stdRepo = FakeStudentRepository();

        await tester.pumpWidget(
          buildTestApp(
            child: const LibraryHistoryScreen(),
            libraryRepo: libRepo,
            studentRepo: stdRepo,
            themeMode: ThemeMode.dark,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Library History'), findsOneWidget);
        expect(find.text('The Great Gatsby'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
