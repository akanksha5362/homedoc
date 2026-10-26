import 'package:flutter/material.dart';
import '../../../../shared/widgets/states/app_empty_state.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health')),
      body: const AppEmptyState(
        message: 'Your health timeline, prescriptions, and records will appear here.',
        icon: Icons.timeline_outlined,
      ),
    );
  }
}
