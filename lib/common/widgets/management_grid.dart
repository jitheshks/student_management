import 'package:flutter/material.dart';

/// Model for a single management option tile
class ManagementOption {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradient;
  final String? subtitle; // optional

  const ManagementOption({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.gradient,
    this.subtitle,
  });
}


/// Reusable Grid that arranges ManagementCards
class ManagementGrid extends StatelessWidget {
  final List<ManagementOption> options;
  final EdgeInsetsGeometry padding;

  const ManagementGrid({
    super.key,
    required this.options,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 360;
    final isShort = size.height < 640;
final mgmtAspect = isShort ? 0.68 : (isNarrow ? 0.70 : 0.72);

    

    return Padding(
      padding: padding,
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: options.length,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: mgmtAspect,
        ),
        itemBuilder: (context, index) {
          final o = options[index];
          return ManagementCard(
            label: o.label,
            icon: o.icon,
            onTap: o.onTap,
            gradient: o.gradient,
          );
        },
      ),
    );
  }
}

/// Reusable gradient card for each management option
class ManagementCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradient;
  final String? subtitle;

  const ManagementCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.gradient,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x30FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333),height: 1.25),
            ),
            const SizedBox(height: 4),
            subtitle == null
                ? const Text(
                    'Tap to view and manage',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.3),
                  )
                : Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.3),
                  ),
          ],
        ),
      ),
    );
  }
}

