enum UserRole { patient, doctor, admin, pharmacy, lab }

class UserModel {
  final String id;
  final String? phone;
  final String? displayName;
  final UserRole role;
  final bool isActive;
  final bool isProfileComplete;
  final bool onboardingComplete;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    this.phone,
    this.displayName,
    required this.role,
    this.isActive = true,
    this.isProfileComplete = false,
    this.onboardingComplete = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      phone: json['phone'] as String?,
      displayName: json['display_name'] as String? ?? json['name'] as String?,
      role: UserRole.values.firstWhere(
            (e) => e.name == json['role'],
        orElse: () => UserRole.patient,
      ),
      isActive: json['is_active'] as bool? ?? true,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (phone != null) 'phone': phone,
    if (displayName != null) 'display_name': displayName,
    'role': role.name,
    'is_active': isActive,
    'is_profile_complete': isProfileComplete,
    'onboarding_complete': onboardingComplete,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };

  UserModel copyWith({
    String? id,
    String? phone,
    String? displayName,
    UserRole? role,
    bool? isActive,
    bool? isProfileComplete,
    bool? onboardingComplete,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
