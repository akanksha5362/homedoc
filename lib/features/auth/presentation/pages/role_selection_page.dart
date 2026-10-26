import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';

enum HomeDocRole { patient, doctor, admin }

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  HomeDocRole? _selectedRole;

  static const Color primaryTeal = Color(0xFF14B8A6);
  static const Color darkTeal = Color(0xFF007A8A);
  static const Color lightTeal = Color(0xFFE6F7F6);
  static const Color darkText = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);

  void _continue() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    switch (_selectedRole!) {
      case HomeDocRole.patient:
        context.go(RoutePaths.auth);
        break;

      case HomeDocRole.doctor:
        context.go(RoutePaths.doctorLogin);
        break;

      case HomeDocRole.admin:
        context.go(RoutePaths.adminLogin);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                height: 260,
                width: 260,
                decoration: const BoxDecoration(
                  color: lightTeal,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  color: lightTeal.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RoutePaths.onboarding);
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: darkText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Welcome to HomeDoc',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'How would you like to use HomeDoc?',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: mutedText,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildRoleCard(
                            role: HomeDocRole.patient,
                            icon: Icons.person_outline_rounded,
                            title: 'Patient',
                            description:
                                'Find doctors, book appointments, '
                                'and manage your healthcare.',
                          ),
                          const SizedBox(height: 16),
                          _buildRoleCard(
                            role: HomeDocRole.doctor,
                            icon: Icons.medical_services_outlined,
                            title: 'Doctor',
                            description:
                                'Manage appointments, availability, '
                                'and patient care.',
                          ),
                          const SizedBox(height: 16),
                          _buildRoleCard(
                            role: HomeDocRole.admin,
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Admin',
                            description:
                                'Access administrative tools if your '
                                'account is authorized.',
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'Healthcare at your doorstep.',
                      style: TextStyle(
                        color: darkTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required HomeDocRole role,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final bool isSelected = _selectedRole == role;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected ? lightTeal : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? primaryTeal : const Color(0xFFD7E7E9),
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: isSelected ? primaryTeal : lightTeal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: isSelected ? Colors.white : darkTeal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? primaryTeal : mutedText,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
