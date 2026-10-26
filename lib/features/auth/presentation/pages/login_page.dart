import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isRegisterMode = false;

  static const Color darkTeal = Color(0xFF007A8A);
  static const Color primaryTeal = Color(0xFF14B8A6);
  static const Color lightTeal = Color(0xFFA7E3E1);
  static const Color veryLightTeal = Color(0xFFE6F7F6);
  static const Color darkText = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFD5E5E8);

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      return;
    }

    if (_isRegisterMode && _nameController.text.trim().isEmpty) {
      return;
    }

    ref.read(authStateProvider.notifier).sendOtp(
      phone: phone,
      displayName:
      _isRegisterMode ? _nameController.text.trim() : null,
    );
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      return;
    }

    ref.read(authStateProvider.notifier).verifyOtp(otp);
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft background glow
          Positioned(
            top: -130,
            right: -100,
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
            top: 180,
            left: -180,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lightTeal.withValues(alpha: 0.10),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // ---------------------------------------------------------
                  // LOGO
                  // ---------------------------------------------------------
                  Center(
                    child: Image.asset(
                      'assets/images/homedoc_logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ---------------------------------------------------------
                  // HEADING
                  // ---------------------------------------------------------
                  Text(
                    _isRegisterMode
                        ? 'Create your account'
                        : 'Welcome to HomeDoc 👋',
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                      letterSpacing: -0.7,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    _isRegisterMode
                        ? 'Start your personalized healthcare journey.'
                        : 'Sign in to continue your healthcare journey.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: mutedText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ---------------------------------------------------------
                  // NAME - REGISTER ONLY
                  // ---------------------------------------------------------
                  if (_isRegisterMode) ...[
                    _buildInput(
                      controller: _nameController,
                      label: 'Full name',
                      hint: 'Enter your name',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                    ),

                    const SizedBox(height: 16),
                  ],

                  // ---------------------------------------------------------
                  // PHONE
                  // ---------------------------------------------------------
                  _buildPhoneInput(),

                  // ---------------------------------------------------------
                  // OTP
                  // ---------------------------------------------------------
                  if (authState.isOtpSent) ...[
                    const SizedBox(height: 16),

                    _buildInput(
                      controller: _otpController,
                      label: 'Verification code',
                      hint: 'Enter 6-digit OTP',
                      icon: Icons.lock_outline_rounded,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                  ],

                  // ---------------------------------------------------------
                  // ERROR
                  // ---------------------------------------------------------
                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ---------------------------------------------------------
                  // MAIN BUTTON
                  // ---------------------------------------------------------
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authState.isSubmitting
                          ? null
                          : authState.isOtpSent
                          ? _verifyOtp
                          : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        primaryTeal.withValues(alpha: 0.55),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: authState.isSubmitting
                          ? const SizedBox(
                        height: 23,
                        width: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            authState.isOtpSent
                                ? 'Verify OTP'
                                : 'Send OTP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---------------------------------------------------------
                  // RESEND OTP
                  // ---------------------------------------------------------
                  if (authState.isOtpSent) ...[
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: authState.isSubmitting
                          ? null
                          : () {
                        _otpController.clear();

                        ref
                            .read(authStateProvider.notifier)
                            .sendOtp(
                          phone: _phoneController.text.trim(),
                          displayName: _isRegisterMode
                              ? _nameController.text.trim()
                              : null,
                        );
                      },
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: darkTeal,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // ---------------------------------------------------------
                  // DIVIDER
                  // ---------------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: borderColor,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: borderColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ---------------------------------------------------------
                  // CREATE ACCOUNT / LOGIN
                  // ---------------------------------------------------------
                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: authState.isSubmitting ? null : _toggleMode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: darkTeal,
                        side: const BorderSide(
                          color: primaryTeal,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _isRegisterMode
                            ? 'Already have an account? Log in'
                            : 'Create account',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ---------------------------------------------------------
                  // TRUST FEATURES
                  // ---------------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _TrustItem(
                        icon: Icons.verified_user_outlined,
                        text: 'Secure',
                      ),
                      SizedBox(width: 20),
                      _TrustItem(
                        icon: Icons.health_and_safety_outlined,
                        text: 'Trusted care',
                      ),
                      SizedBox(width: 20),
                      _TrustItem(
                        icon: Icons.lock_outline_rounded,
                        text: 'Private',
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ---------------------------------------------------------
                  // TERMS
                  // ---------------------------------------------------------
                  Text.rich(
                    TextSpan(
                      text: 'By continuing, you agree to HomeDoc\'s\n',
                      style: const TextStyle(
                        color: Color(0xFF8AA5B5),
                        fontSize: 12,
                        height: 1.5,
                      ),
                      children: const [
                        TextSpan(
                          text: 'terms and privacy policy.',
                          style: TextStyle(
                            color: darkTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // ---------------------------------------------------------
                  // BOTTOM BRAND LINE
                  // ---------------------------------------------------------
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 3,
                          decoration: BoxDecoration(
                            color: primaryTeal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'HEALTHCARE AT YOUR DOORSTEP.',
                          style: TextStyle(
                            color: darkTeal,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PHONE FIELD
  // -------------------------------------------------------------------------

  Widget _buildPhoneInput() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: borderColor,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: darkTeal.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),

          const Icon(
            Icons.phone_outlined,
            color: darkTeal,
            size: 22,
          ),

          const SizedBox(width: 12),

          const Text(
            '+91',
            style: TextStyle(
              color: darkText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 1,
            height: 30,
            color: borderColor,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(
                color: darkText,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter 10-digit mobile number',
                hintStyle: TextStyle(
                  color: Color(0xFF8AAFC0),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(width: 14),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // GENERIC INPUT
  // -------------------------------------------------------------------------

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    int? maxLength,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: borderColor,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: darkTeal.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),

          Icon(
            icon,
            color: darkTeal,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              style: const TextStyle(
                color: darkText,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF8AAFC0),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
            ),
          ),

          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xFF007A8A),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B8794),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}