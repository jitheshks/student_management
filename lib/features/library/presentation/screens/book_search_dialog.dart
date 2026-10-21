import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/features/library/presentation/providers/library_providers.dart';
import 'package:student_management/shared/models/book.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/empty_state_view.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class BookSearchDialog extends ConsumerStatefulWidget {
  const BookSearchDialog({super.key});

  @override
  ConsumerState<BookSearchDialog> createState() => _BookSearchDialogState();
}

class _BookSearchDialogState extends ConsumerState<BookSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(borrowBookControllerProvider.notifier).searchBooks(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(borrowBookControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Books',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxContentWidth: 800,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Search by Title, Author, or ISBN',
                  hintText: 'e.g. Harry Potter, 9780747532743',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(borrowBookControllerProvider.notifier)
                                  .clearSearchResults();
                              setState(() {});
                            },
                          )
                          : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space12,
                    vertical: 14,
                  ),
                ),
                onChanged: (text) {
                  setState(() {});
                  _onSearchChanged(text);
                },
                onSubmitted: (text) {
                  ref
                      .read(borrowBookControllerProvider.notifier)
                      .searchBooks(text);
                },
              ),
              AppSpacing.gapH12,
              Expanded(child: _buildResults(context, state, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, dynamic state, bool isDark) {
    if (state.isSearchingBooks) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Book> books = state.searchResults;

    if (_searchController.text.trim().isEmpty) {
      return const EmptyStateView(
        title: 'Search the Catalog',
        subtitle: 'Enter a book title, author, or ISBN above to find books.',
      );
    }

    if (books.isEmpty) {
      return EmptyStateView(
        title: 'No books found',
        subtitle:
            'No catalog items match "${_searchController.text.trim()}". Try checking spelling or search keywords.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.space16),
      itemCount: books.length,
      separatorBuilder: (context, index) => AppSpacing.gapH8,
      itemBuilder: (context, index) {
        final book = books[index];
        final bool isAvailable = book.copies > 0;

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.space12),
          onTap: () => Navigator.pop(context, book),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.roundedSm,
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    book.coverUrl.isNotEmpty
                        ? Image.network(
                          book.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, _, _) => Icon(
                                Icons.book,
                                size: 24,
                                color:
                                    isDark
                                        ? AppColors.slate500
                                        : AppColors.slate400,
                              ),
                        )
                        : Icon(
                          Icons.book,
                          size: 24,
                          color:
                              isDark ? AppColors.slate500 : AppColors.slate400,
                        ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${book.author}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSpacing.space8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'ISBN: ${book.isbn}',
                          style: AppTypography.labelSmall.copyWith(
                            color:
                                isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500,
                          ),
                        ),
                        if (isAvailable)
                          AppStatusBadge.active(
                            label: '${book.copies} available',
                            showDot: false,
                          )
                        else
                          const AppStatusBadge.inactive(
                            label: 'Unavailable',
                            showDot: false,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDark ? AppColors.slate500 : AppColors.slate400,
              ),
            ],
          ),
        );
      },
    );
  }
}
