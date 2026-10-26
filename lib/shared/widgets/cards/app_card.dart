import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

/// One consistent card shell reused everywhere a "card" concept appears
/// (Day 2 §33: "differentiated by content, not by new card styles").
/// Do NOT create a bespoke Container-with-BoxDecoration per feature —
/// wrap content in this instead.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final card = Card(child: Padding(padding: padding, child: child));
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}
