import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/accessibility/accessibility_helper.dart';

/// The emergency entry point. Position and color NEVER vary by screen
/// (UX/UI Architecture v1 §34: "position, color — never varies"). The
/// emergency color token is reserved exclusively for this component so it
/// keeps its meaning everywhere it appears.
///
/// This widget only navigates/triggers [onTap] — the actual emergency flow
/// (Day 2 §25) is a separate, full-screen feature built later.
class EmergencyAction extends StatelessWidget {
  const EmergencyAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Emergency — request immediate help',
      child: Material(
        color: AppColors.emergency,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: A11y.emergencyTouchTarget,
            height: A11y.emergencyTouchTarget,
            child: Icon(Icons.emergency_outlined, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
