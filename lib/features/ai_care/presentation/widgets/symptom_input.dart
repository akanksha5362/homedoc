import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';

/// Pure input widget — receives controllers, exposes nothing beyond text
/// entry. Submission/business logic lives in [AiCarePage] via the
/// controller/provider (Day 3 §17: components don't call APIs).
class SymptomInput extends StatelessWidget {
  const SymptomInput({
    super.key,
    required this.symptomsController,
    required this.durationController,
    required this.symptomsLabel,
    required this.durationLabel,
    required this.symptomsHint,
  });

  final TextEditingController symptomsController;
  final TextEditingController durationController;
  final String symptomsLabel;
  final String durationLabel;
  final String symptomsHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: symptomsLabel,
          controller: symptomsController,
          maxLines: 4,
          hintText: symptomsHint,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: durationLabel,
          controller: durationController,
        ),
      ],
    );
  }
}
