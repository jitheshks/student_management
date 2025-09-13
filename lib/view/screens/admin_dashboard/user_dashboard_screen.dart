import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/controller/base_dashboard_controller.dart';


import 'package:student_management/common/widgets/management_grid.dart'; // reusable grid/card

class UserDashboard<T extends BaseDashboardController> extends StatelessWidget {
  final String title;
  final T Function(BuildContext) createController;

  const UserDashboard({
    super.key,
    required this.title,
    required this.createController,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: (ctx) => createController(ctx)..load(),
      child: _UserDashboardView<T>(title: title),
    );
  }
}

class _UserDashboardView<T extends BaseDashboardController> extends StatelessWidget {
  final String title;
  const _UserDashboardView({required this.title});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<T>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ctrl.logout(context),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF2F3F7),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(name: ctrl.displayName,),
              const SizedBox(height: 12),
              const _SectionTitle(icon: Icons.insights, title: 'Overview'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _OverviewRow(
                  students: ctrl.totalStudents,
                  staff: ctrl.totalStaff,
                ),
              ),
              const SizedBox(height: 12),
              const _SectionTitle(icon: Icons.settings_applications, title: 'Management'),
              // Reusable grid used here
              ManagementGrid(
                options: ctrl.managementOptions(context).map((m) {
                  final label = m['label'] as String;
                  return ManagementOption(
                    label: label,
                    icon: m['icon'] as IconData,
                    onTap: m['action'] as VoidCallback,
                    gradient: _gradientFor(label),
                    // subtitle: 'Tap to view and manage', // optional
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Keep gradient mapping consistent with previous design
  List<Color> _gradientFor(String label) {
    switch (label) {
      case 'Student Management':
        return const [Color(0xFF4CAF50), Color(0xFF45A049)];
      case 'Library Management':
        return const [Color(0xFFFF9800), Color(0xFFF57C00)];
      case 'Staff Management':
        return const [Color(0xFF2196F3), Color(0xFF1976D2)];
      case 'Fees Management':
      default:
        return const [Color(0xFF9C27B0), Color(0xFF7B1FA2)];
    }
  }
}

class _HeaderCard extends StatelessWidget {

  const _HeaderCard({required this.name});
   final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0x0FFFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0x22667EEA),
                    ),
                    child: const Icon(
                      Icons.waving_hand_rounded,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Opacity(
                          opacity: 0.9,
                          child: Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name.isNotEmpty ? name : 'Administrator',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3F667EEA),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final int students;
  final int staff;
  const _OverviewRow({required this.students, required this.staff});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 360;
    final isShort = size.height < 640;

    final kpiAspect = isShort ? 1.5 : (isNarrow ? 1.6 : 1.7);
    final numberSize = isShort ? 20.0 : 22.0;
    const labelSize = 12.0;

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: kpiAspect,
      ),
      children: [
        kpiCard('Total Students', students, numberSize, labelSize),
        kpiCard('Staff Members', staff, numberSize, labelSize),
      ],
    );
  }

  Widget kpiCard(
    String title,
    int value,
    double numberSize,
    double labelSize,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (_, v, __) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                v.toInt().toString(),
                style: TextStyle(
                  fontSize: numberSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF667EEA),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: labelSize,
                  color: const Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
