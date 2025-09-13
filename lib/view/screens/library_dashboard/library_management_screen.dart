import 'package:flutter/material.dart';
import 'package:student_management/common/widgets/management_grid.dart';

class LibraryManagement extends StatelessWidget {
  const LibraryManagement({super.key});

  @override
  Widget build(BuildContext context) {
    // Define your library options
    final List<Map<String, dynamic>> libraryOptions = [
      {'label': 'Borrow Book', 'icon': Icons.menu_book, 'route': '/borrowBook'},
      {'label': 'Return Book', 'icon': Icons.add_circle_outline, 'route': '/returnBook'},
      {'label': 'Library History Page', 'icon': Icons.history, 'route': '/libraryHistory'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Management'),
        centerTitle: true,
        // Optional: match dashboard gradient AppBar
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      // Use the reusable ManagementGrid
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ManagementGrid(
          options: libraryOptions.map((o) {
            final label = o['label'] as String;
            return ManagementOption(
              label: label,
              icon: o['icon'] as IconData,
              onTap: () => Navigator.pushNamed(context, o['route'] as String),
              gradient: _libraryGradientFor(label),
              // subtitle: 'Open', // optional override
            );
          }).toList(),
        ),
      ),
    );
  }

  // Gradient helper to match the dashboard palette
  List<Color> _libraryGradientFor(String label) {
    switch (label) {
      case 'Borrow Book':
        return const [Color(0xFF4CAF50), Color(0xFF45A049)]; // green
      case 'Return Book':
        return const [Color(0xFF2196F3), Color(0xFF1976D2)]; // blue
      case 'Library History Page':
        return const [Color(0xFFFF9800), Color(0xFFF57C00)]; // orange
      default:
        return const [Color(0xFF9C27B0), Color(0xFF7B1FA2)]; // purple
    }
  }
}
