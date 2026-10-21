import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/network/dio_client_provider.dart';
import 'package:student_management/core/network/supabase_client_provider.dart';
import 'package:student_management/features/library/data/datasources/library_remote_data_source.dart';
import 'package:student_management/features/library/data/repositories/library_repository_impl.dart';
import 'package:student_management/features/library/domain/repositories/i_library_repository.dart';
import 'package:student_management/features/library/presentation/controllers/borrow_book_controller.dart';
import 'package:student_management/features/library/presentation/controllers/library_history_controller.dart';
import 'package:student_management/features/library/presentation/controllers/return_book_controller.dart';

/// Provides the remote data source for Library operations.
final libraryRemoteDataSourceProvider = Provider<LibraryRemoteDataSource>((
  ref,
) {
  final supabase = ref.watch(supabaseClientProvider);
  final dio = ref.watch(dioClientProvider);
  return LibraryRemoteDataSource(supabase: supabase, dio: dio);
});

/// Provides the canonical Library domain repository.
final libraryRepositoryProvider = Provider<ILibraryRepository>((ref) {
  final remoteDataSource = ref.watch(libraryRemoteDataSourceProvider);
  return LibraryRepositoryImpl(remoteDataSource);
});

/// Reactive controller managing global library borrow history, filtering, and sorting.
final libraryHistoryControllerProvider =
    AutoDisposeNotifierProvider<LibraryHistoryController, LibraryHistoryState>(
      LibraryHistoryController.new,
    );

/// Reactive controller managing book borrowing workflow.
final borrowBookControllerProvider =
    AutoDisposeNotifierProvider<BorrowBookController, BorrowBookState>(
      BorrowBookController.new,
    );

/// Reactive controller managing book returns workflow.
final returnBookControllerProvider =
    AutoDisposeNotifierProvider<ReturnBookController, ReturnBookState>(
      ReturnBookController.new,
    );
