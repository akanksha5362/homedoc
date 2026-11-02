import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';


class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  static const Color primaryTeal = Color(0xFF14B8A6);
  static const Color darkTeal = Color(0xFF007A8A);
  static const Color veryLightTeal = Color(0xFFE6F7F6);
  static const Color mutedText = Color(0xFF6B7280);

  final List<OnboardingData> _pages = const [
    OnboardingData(
      icon: Icons.home_rounded,
      title: 'Healthcare,\nright at home',
      description:
      'Get trusted healthcare services without the need to travel. HomeDoc brings care closer to you.',
    ),
    OnboardingData(
      icon: Icons.medical_services_rounded,
      title: 'Connect with\ndoctors easily',
      description:
      'Find doctors, book home visits and get professional medical care whenever you need it.',
    ),
    OnboardingData(
      icon: Icons.smart_toy_rounded,
      title: 'Your AI health\ncompanion',
      description:
      'Get quick health guidance, understand your symptoms and make informed healthcare decisions.',
    ),
    OnboardingData(
      icon: Icons.receipt_long_rounded,
      title: 'Keep your health\norganized',
      description:
      'Manage prescriptions, appointments and important health information in one convenient place.',
    ),
    OnboardingData(
      icon: Icons.favorite_rounded,
      title: 'Care that follows\nyou',
      description:
      'From everyday health needs to professional care, HomeDoc is designed to make healthcare simpler.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _goToRoleSelection();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _skip() {
    _goToRoleSelection();
  }

  void _goToRoleSelection() {
    context.go(RoutePaths.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // -------------------------------------------------------------
            // SOFT BACKGROUND GLOW
            // -------------------------------------------------------------

            Positioned(
              top: -130,
              right: -110,
              child: Container(
                width: 330,
                height: 330,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: veryLightTeal.withValues(alpha: 0.75),
                ),
              ),
            ),

            Positioned(
              bottom: -150,
              left: -130,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: veryLightTeal.withValues(alpha: 0.55),
                ),
              ),
            ),

            // -------------------------------------------------------------
            // TOP BAR
            // -------------------------------------------------------------

            Positioned(
              top: 8,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Small logo
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: primaryTeal.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: darkTeal.withValues(alpha: 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/homedoc_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Skip button
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: mutedText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -------------------------------------------------------------
            // ONBOARDING CONTENT
            // -------------------------------------------------------------

            Column(
              children: [
                const SizedBox(height: 75),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _pages[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ------------------------------------------------
                            // ILLUSTRATION / ICON AREA
                            // ------------------------------------------------

                            Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                color: veryLightTeal,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryTeal.withValues(alpha: 0.10),
                                    blurRadius: 35,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 175,
                                    height: 175,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [
                                        BoxShadow(
                                          color: darkTeal.withValues(
                                            alpha: 0.10,
                                          ),
                                          blurRadius: 25,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    item.icon,
                                    size: 85,
                                    color: primaryTeal,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 45),

                            // ------------------------------------------------
                            // TITLE
                            // ------------------------------------------------

                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: darkTeal,
                                fontSize: 29,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // ------------------------------------------------
                            // DESCRIPTION
                            // ------------------------------------------------

                            Text(
                              item.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: mutedText,
                                fontSize: 15,
                                height: 1.55,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // -----------------------------------------------------------
                // PAGE INDICATORS
                // -----------------------------------------------------------

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                        (index) {
                      final isActive = index == _currentPage;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 25 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? primaryTeal
                              : primaryTeal.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // -----------------------------------------------------------
                // NEXT / GET STARTED BUTTON
                // -----------------------------------------------------------

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? 'Get Started' : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            isLastPage
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // -----------------------------------------------------------
                // BRANDING
                // -----------------------------------------------------------

                const Text(
                  'SMARTER CARE. HEALTHIER TOMORROW.',
                  style: TextStyle(
                    color: darkTeal,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}