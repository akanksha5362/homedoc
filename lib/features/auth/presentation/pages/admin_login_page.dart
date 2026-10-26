import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';

class AdminLoginPage extends StatefulWidget {
const AdminLoginPage({super.key});

@override
State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();

bool _obscurePassword = true;

static const Color primaryTeal = Color(0xFF14B8A6);
static const Color darkTeal = Color(0xFF007A8A);
static const Color lightTeal = Color(0xFFE6F7F6);
static const Color darkText = Color(0xFF1F2937);
static const Color mutedText = Color(0xFF6B7280);

@override
void dispose() {
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}

String? _validateEmail(String? value) {
final email = value?.trim() ?? '';

if (email.isEmpty) {
return 'Please enter your administrator email';
}

if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
    .hasMatch(email)) {
return 'Please enter a valid email address';
}

return null;
}

String? _validatePassword(String? value) {
if (value == null || value.isEmpty) {
return 'Please enter your password';
}

return null;
}

void _signIn() {
FocusScope.of(context).unfocus();

if (!_formKey.currentState!.validate()) {
return;
}

// Admin authentication must be verified by the backend.
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Admin authentication is not available yet. '
'Backend integration is required.',
),
behavior: SnackBarBehavior.floating,
),
);
}

void _forgotPassword() {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Admin password reset will be available '
'after backend integration.',
),
behavior: SnackBarBehavior.floating,
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.white,
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(
horizontal: 24,
vertical: 16,
),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
IconButton(
onPressed: () => context.go(
RoutePaths.roleSelection,
),
icon: const Icon(Icons.arrow_back_ios_new),
color: darkText,
tooltip: 'Back to role selection',
),

const SizedBox(height: 16),

Center(
child: Image.asset(
'assets/images/homedoc_logo.png',
height: 85,
errorBuilder: (context, error, stackTrace) {
return const Icon(
Icons.admin_panel_settings_rounded,
size: 72,
color: darkTeal,
);
},
),
),

const SizedBox(height: 24),

const Center(
child: Text(
'Administrator Access',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 27,
fontWeight: FontWeight.bold,
color: darkText,
),
),
),

const SizedBox(height: 8),

const Center(
child: Text(
'Sign in to manage and monitor HomeDoc AI.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 14,
height: 1.5,
color: mutedText,
),
),
),

const SizedBox(height: 24),

Container(
width: double.infinity,
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: lightTeal,
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: primaryTeal.withValues(alpha: 0.35),
),
),
child: const Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.shield_outlined,
color: darkTeal,
size: 23,
),
SizedBox(width: 10),
Expanded(
child: Text(
'Restricted area. Only authorized '
'administrators can access this portal.',
style: TextStyle(
color: darkText,
fontSize: 13,
height: 1.45,
),
),
),
],
),
),

const SizedBox(height: 28),

const Text(
'Administrator Email',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w600,
color: darkText,
),
),

const SizedBox(height: 8),

TextFormField(
controller: _emailController,
keyboardType: TextInputType.emailAddress,
textInputAction: TextInputAction.next,
autofillHints: const [AutofillHints.username],
validator: _validateEmail,
decoration: InputDecoration(
hintText: 'admin@example.com',
prefixIcon: const Icon(
Icons.email_outlined,
color: darkTeal,
),
filled: true,
fillColor: lightTeal.withValues(alpha: 0.45),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: const BorderSide(
color: Color(0xFFE5E7EB),
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: const BorderSide(
color: primaryTeal,
width: 1.5,
),
),
),
),

const SizedBox(height: 20),

const Text(
'Password',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w600,
color: darkText,
),
),

const SizedBox(height: 8),

TextFormField(
controller: _passwordController,
obscureText: _obscurePassword,
textInputAction: TextInputAction.done,
autofillHints: const [AutofillHints.password],
validator: _validatePassword,
onFieldSubmitted: (_) => _signIn(),
decoration: InputDecoration(
hintText: 'Enter your password',
prefixIcon: const Icon(
Icons.lock_outline_rounded,
color: darkTeal,
),
suffixIcon: IconButton(
onPressed: () {
setState(() {
_obscurePassword = !_obscurePassword;
});
},
icon: Icon(
_obscurePassword
? Icons.visibility_outlined
    : Icons.visibility_off_outlined,
),
),
filled: true,
fillColor: lightTeal.withValues(alpha: 0.45),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: const BorderSide(
color: Color(0xFFE5E7EB),
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: const BorderSide(
color: primaryTeal,
width: 1.5,
),
),
),
),

const SizedBox(height: 8),

Align(
alignment: Alignment.centerRight,
child: TextButton(
onPressed: _forgotPassword,
child: const Text(
'Forgot Password?',
style: TextStyle(
color: darkTeal,
fontWeight: FontWeight.w600,
),
),
),
),

const SizedBox(height: 16),

SizedBox(
width: double.infinity,
height: 54,
child: ElevatedButton(
onPressed: _signIn,
style: ElevatedButton.styleFrom(
backgroundColor: primaryTeal,
foregroundColor: Colors.white,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: const Text(
'Secure Admin Sign In',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
),
),

const SizedBox(height: 28),

const Divider(color: Color(0xFFE5E7EB)),

const SizedBox(height: 18),

const Center(
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.verified_user_outlined,
size: 18,
color: mutedText,
),
SizedBox(width: 7),
Flexible(
child: Text(
'No public administrator registration.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 12,
color: mutedText,
),
),
),
],
),
),

const SizedBox(height: 12),

const Center(
child: Text(
'Your access must be authorized by the '
'HomeDoc AI backend.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 12,
height: 1.5,
color: mutedText,
),
),
),
],
),
),
),
),
);
}
}
