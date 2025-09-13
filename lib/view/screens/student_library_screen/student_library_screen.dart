import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:student_management/common/widgets/custom_app_bar.dart';
import 'package:student_management/controller/student_dashboard_controller.dart';
import 'package:student_management/controller/student_library_controller.dart';

class StudentLibraryScreen extends StatelessWidget {
  final String id; // auth uid if filterByUserId=true, else students.id
  final bool filterByUserId;

  const StudentLibraryScreen({
    super.key,
    required this.id,
    this.filterByUserId = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) =>
              StudentLibraryController()
                ..load(id, filterByUserId: filterByUserId),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StudentLibraryController>();
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: CustomScrollView(
        slivers: [
          // ✅ Updated header with CustomSliverHeader
          CustomSliverHeader(
            icon: const Icon(Icons.menu_book, color: Color(0xFF1976D2)),
            title: const Text('Library History'),
            subtitle: Builder(
              builder: (context) {
                final c = context.watch<StudentLibraryController>();
                return Text('${c.items.length} Books Record');
              },
            ),
            actions: [
    Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Logout',
        onPressed: () => context.read<StudentDashboardController>().logout(context),
      ),
    ),
  ],
          ),

          if (c.loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (c.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Error: ${c.error}'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _BookCard(item: c.items[i]),
                  childCount: c.items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final StudentLibraryItem item;
  const _BookCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          Container(
            width: 60,
            height: 80,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child:
                item.coverUrl.isNotEmpty
                    ? Image.network(item.coverUrl, fit: BoxFit.cover)
                    : Container(color: const Color(0xFFE0E0E0)),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${item.author}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusBadge(
                  label: meta.label,
                  color: meta.color,
                  border: meta.border,
                  bg: meta.bg,
                ),
                const SizedBox(height: 8),
                _dateRow(
                  Icons.calendar_today_rounded,
                  'Borrowed: ${_fmt(item.borrowedAt)}',
                ),
                if (item.returnedAt != null)
                  _dateRow(
                    Icons.reply_rounded,
                    'Returned: ${_fmt(item.returnedAt!)}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) => DateFormat('d/M/yyyy').format(d);

  Widget _dateRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 14, color: const Color(0xFF666666)),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      ),
    ],
  );

  _StatusMeta _statusMeta(String s) {
    switch (s) {
      case 'returned':
        return _StatusMeta(
          label: 'Returned',
          color: const Color(0xFF4CAF50),
          border: const Color(0x4D4CAF50),
          bg: const Color(0x1A4CAF50),
        );
      case 'overdue':
        return _StatusMeta(
          label: 'Overdue',
          color: const Color(0xFFF44336),
          border: const Color(0x4DF44336),
          bg: const Color(0x1AF44336),
        );
      default:
        return _StatusMeta(
          label: 'Currently Borrowed',
          color: const Color(0xFF2196F3),
          border: const Color(0x4D2196F3),
          bg: const Color(0x1A2196F3),
        );
    }
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  final Color border;
  final Color bg;
  const _StatusMeta({
    required this.label,
    required this.color,
    required this.border,
    required this.bg,
  });
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color border;
  final Color bg;
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.border,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
