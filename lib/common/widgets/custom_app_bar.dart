import 'package:flutter/material.dart';

class CustomSliverHeader extends StatelessWidget {
  final double expandedHeight;
  final Widget icon;
  final Widget title;
  final Widget? subtitle;
  final List<Widget>? actions;

  const CustomSliverHeader({
    super.key,
    this.expandedHeight = 180,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // circular icon background
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(child: icon),
            ),
            const SizedBox(height: 4),
            DefaultTextStyle.merge(
              style: const TextStyle(fontWeight: FontWeight.w700),
              child: title,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                child: subtitle!,
              ),
            ],
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF90CAF9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
    );
  }
}
