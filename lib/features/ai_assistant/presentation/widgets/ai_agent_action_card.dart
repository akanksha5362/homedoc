import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/healthcare/doctor_card.dart';
import '../../../../shared/models/doctor_model.dart';
import '../../data/models/agent_response.dart';
import '../../data/models/agent_risk_level.dart';

/// Renders exactly one [AgentAction] as real UI (Day 3.2 §17: "Flutter
/// should render appropriate UI from these structured actions") — this is
/// the mechanism, not a template for every action type doing something
/// today. Only SHOW_DOCTORS and EMERGENCY are backed by a real backend
/// response right now (see backend/README.md's tool inventory); every
/// other case renders an honest "not yet available" row rather than
/// silently doing nothing, so a future backend addition has an obvious
/// place to plug in.
class AIAgentActionCard extends StatelessWidget {
  const AIAgentActionCard({super.key, required this.action, this.onDoctorTap});

  final AgentAction action;
  final void Function(DoctorModel doctor)? onDoctorTap;

  @override
  Widget build(BuildContext context) {
    switch (action.type) {
      case AgentActionType.showDoctors:
        return _DoctorResultsList(action: action, onDoctorTap: onDoctorTap);
      case AgentActionType.emergency:
        // Rendered by the caller via EmergencyWarning instead (see
        // AiAssistantPage) — emergency breaks out of the normal action
        // list entirely, same principle as Day 3's AiCarePage.
        return const SizedBox.shrink();
      case AgentActionType.showAppointments:
      case AgentActionType.bookAppointment:
      case AgentActionType.showPrescription:
      case AgentActionType.startVideo:
      case AgentActionType.trackDoctor:
      case AgentActionType.setReminder:
      case AgentActionType.requestHomeVisit:
      case AgentActionType.escalateToDoctor:
      case AgentActionType.unknown:
        return _NotYetAvailableRow(action: action);
    }
  }
}

class _DoctorResultsList extends StatelessWidget {
  const _DoctorResultsList({required this.action, this.onDoctorTap});

  final AgentAction action;
  final void Function(DoctorModel doctor)? onDoctorTap;

  @override
  Widget build(BuildContext context) {
    final rawDoctors = (action.data['doctors'] as List<dynamic>? ?? []);
    final doctors = rawDoctors
        .map((d) => DoctorModel.fromJson(d as Map<String, dynamic>))
        .toList();

    if (doctors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text('No doctors found for that right now.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final doctor in doctors) ...[
          DoctorCard(doctor: doctor, onTap: () => onDoctorTap?.call(doctor)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _NotYetAvailableRow extends StatelessWidget {
  const _NotYetAvailableRow({required this.action});

  final AgentAction action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        '${action.type.name} — coming in a later implementation phase',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
