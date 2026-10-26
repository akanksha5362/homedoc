import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// A distinct "AI is working" state (UX/UI Architecture v1 §31/§39) — not
/// a generic [CircularProgressIndicator], so users learn to recognize
/// "AI is thinking" versus "the app is loading" by sight.
///
/// Kept as a simple pulsing dot for the foundation; a richer animation can
/// replace the internals later without changing the call sites.
class AIThinkingIndicator extends StatefulWidget {
  const AIThinkingIndicator({super.key, required this.message});

  /// Caller-supplied, localized text (e.g. `AppLocalizations.of(context)!.aiThinking`).
  /// No hardcoded default here — this widget must not own user-facing copy
  /// (Day 3 AI prompt, Step 10).
  final String message;

  @override
  State<AIThinkingIndicator> createState() => _AIThinkingIndicatorState();
}

class _AIThinkingIndicatorState extends State<AIThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _controller.drive(CurveTween(curve: Curves.easeInOut)),
          child: const Icon(Icons.spa_outlined, size: 18, color: AppColors.ai),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(widget.message, style: AppTypography.bodyMuted),
      ],
    );
  }
}
