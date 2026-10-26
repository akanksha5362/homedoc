/// Mirrors backend/app/schemas/auth.py RegisterRequest/LoginRequest.
class RegisterRequest {
  const RegisterRequest({
    required this.phone,
    required this.password,
    required this.displayName,
    this.role = 'patient',
  });

  final String phone;
  final String password;
  final String displayName;
  final String role;

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'password': password,
        'display_name': displayName,
        'role': role,
      };
}

class LoginRequest {
  const LoginRequest({required this.phone, required this.password});

  final String phone;
  final String password;

  Map<String, dynamic> toJson() => {'phone': phone, 'password': password};
}
