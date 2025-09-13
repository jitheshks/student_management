import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/controller/borrow_book_controller.dart';
import 'package:student_management/controller/search_book_provider.dart';

class SearchBooksScreen extends StatelessWidget {
  const SearchBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchBookProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Search Books')),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: searchProvider.searchController,
              decoration: InputDecoration(
                labelText: "Search by Title, ISBN, or Author",
                border: OutlineInputBorder(),
                suffixIcon:
                    searchProvider.searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => searchProvider.clearSearch(),
                        )
                        : null,
              ),
            ),
          ),
          // 📚 Book Results
          Expanded(
            child: Consumer<BorrowBookController>(
              builder: (context, libraryProvider, _) {
                return searchProvider.hasSearched
                    ? libraryProvider.books.isEmpty
                        ? libraryProvider.isLoading
                            ? Center(child: Text("Searching..."))
                            : Center(
                              child: Text(
                                "No books found. Try another search.",
                              ),
                            )
                        : ListView.builder(
                          itemCount: libraryProvider.books.length,
                          itemBuilder: (context, index) {
                            final book = libraryProvider.books[index];
                            final isAlreadyBorrowed =
                                book['isAlreadyBorrowed'] ?? false;
                            final availableCopies =
                                book['availableCopies'] ?? 0;
                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: ListTile(
                                leading:
                                    book['coverImage'] != null
                                        ? Image.network(
                                          book['coverImage'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(Icons.book, size: 50),
                                        )
                                        : Icon(Icons.book, size: 50),
                                title: Text(book['title']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Author: ${book['author']}'),
                                    Text('ISBN: ${book['isbn']}'),
                                    Text('Available Copies: $availableCopies'),
                                    if (isAlreadyBorrowed)
                                      Text(
                                        'You have already borrowed this book',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing:
                                    availableCopies > 0 && !isAlreadyBorrowed
                                        ? ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context, {
                                              'title': book['title'],
                                              'isbn': book['isbn'],
                                            });
                                          },
                                          child: Text("Select"),
                                        )
                                        : ElevatedButton(
                                          onPressed: null, // disables button
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey,
                                          ),
                                          child: Text(
                                            isAlreadyBorrowed
                                                ? "Already Borrowed"
                                                : "Not Available",
                                          ),
                                        ),
                              ),
                            );
                          },
                        )
                    : Center(
                      child: Text("Search books by title, author, or ISBN."),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}
