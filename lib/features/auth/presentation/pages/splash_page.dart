import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  static const Color primaryTeal = Color(0xFF14B8A6);
  static const Color darkTeal = Color(0xFF007A8A);
  static const Color veryLightTeal = Color(0xFFE6F7F6);
  static const Color mutedText = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      context.go(RoutePaths.onboarding);
    });

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ---------------------------------------------------------------
          // SOFT BACKGROUND GLOW
          // ---------------------------------------------------------------

          Positioned(
            top: -170,
            right: -120,
            child: Container(
              width: 390,
              height: 390,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: veryLightTeal.withValues(alpha: 0.9),
              ),
            ),
          ),

          Positioned(
            bottom: -180,
            left: -130,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: veryLightTeal.withValues(alpha: 0.65),
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // MAIN CONTENT
          // ---------------------------------------------------------------

          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // -----------------------------------------------------
                      // LOGO
                      // -----------------------------------------------------

                      Container(
                        width: 145,
                        height: 145,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(38),
                          border: Border.all(
                            color: primaryTeal.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: darkTeal.withValues(alpha: 0.10),
                              blurRadius: 35,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/homedoc_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // -----------------------------------------------------
                      // APP NAME
                      // -----------------------------------------------------

                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Home',
                              style: TextStyle(
                                color: darkTeal,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: 'Doc',
                              style: TextStyle(
                                color: primaryTeal,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 38,
                          height: 1.0,
                          letterSpacing: -1.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // -----------------------------------------------------
                      // TAGLINE
                      // -----------------------------------------------------

                      const Text(
                        'Healthcare at your doorstep.',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 15,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 42),

                      // -----------------------------------------------------
                      // LOADING INDICATOR
                      // -----------------------------------------------------

                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // BOTTOM BRAND TEXT
          // ---------------------------------------------------------------

          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    color: primaryTeal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'SMARTER CARE. HEALTHIER TOMORROW.',
                  style: TextStyle(
                    color: darkTeal,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}