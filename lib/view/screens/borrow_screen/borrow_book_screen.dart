import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/common/widgets/custom_text_form_field.dart';
import 'package:student_management/controller/borrow_book_controller.dart';
import 'package:student_management/view/screens/search_books/search_books_screen.dart';

class BorrowBookScreen extends StatelessWidget {
  BorrowBookScreen({super.key});

  final TextEditingController _registerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow a Book')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<BorrowBookController>(
          builder: (context, libraryProvider, _) {
            final student = libraryProvider.studentDetails;
            final selectedBook = libraryProvider.selectedBookTitle;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Book Selection
                CustomTextFormField(
                  controller: TextEditingController(text: selectedBook ?? ''),
                  labelText: 'Select a Book',
                  prefixIcon: Icons.search,
                  readOnly: true,
                  onTap: () async {
                    final selected = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SearchBooksScreen()),
                    );
                    if (selected != null) {
                      libraryProvider.setSelectedBook(selected);
                    }
                  },
                ),
                const SizedBox(height: 16),

                /// Register Number Input
                /// Register Number Input with Search Icon
                CustomTextFormField(
                  controller: _registerController,
                  labelText: 'Enter Register Number',
                  prefixIcon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      final value = _registerController.text.trim();
                      if (value.isNotEmpty) {
                        libraryProvider.debounceStudentFetch(value);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter a register number"),
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                /// Student Name
                InfoField(
                  icon: Icons.person,
                  value:
                      student != null &&
                              student.firstName.isNotEmpty &&
                              student.lastName.isNotEmpty
                          ? '${student.firstName} ${student.lastName}'
                          : 'Student Name',
                  isValid:
                      student != null &&
                      student.firstName.isNotEmpty &&
                      student.lastName.isNotEmpty,
                ),

                const SizedBox(height: 8),

                /// Standard
                InfoField(
                  icon: Icons.school,
                  value:
                      (student != null && student.standard.isNotEmpty)
                          ? 'Standard: ${student.standard}'
                          : 'Standard',
                  isValid: student != null && student.standard.isNotEmpty,
                ),
              ],
            );
          },
        ),
      ),

      /// Borrow Button
      bottomNavigationBar: Consumer<BorrowBookController>(
        builder: (context, provider, _) {
          final student = provider.studentDetails;
          final selectedBook = provider.selectedBookTitle;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (student != null && selectedBook != null)
                        ? () async {
                          await provider.borrowBook(
                            selectedBook,
                            provider.selectedBookISBN!,
                          );

                          // After successful borrow, pop the screen
                          Navigator.pop(context);

                          // Optional: show confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Book borrowed successfully!"),
                            ),
                          );
                        }
                        : null,

                child: const Text('Borrow'),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Reusable UI Component
class InfoField extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isValid;

  const InfoField({
    super.key,
    required this.icon,
    required this.value,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isValid ? Colors.white : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isValid ? Colors.black : Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
