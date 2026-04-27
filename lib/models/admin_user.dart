class AdminUser {
  final int adminId;
  final int teacherId;
  final String username;
  final String role;
  final String firstName;
  final String middleInitial;
  final String lastName;
  final bool isActive;
  final bool mustChangePassword;
  final bool mfaEnabled;

  const AdminUser({
    required this.adminId,
    required this.teacherId,
    required this.username,
    required this.role,
    required this.firstName,
    required this.middleInitial,
    required this.lastName,
    required this.isActive,
    required this.mustChangePassword,
    required this.mfaEnabled,
  });

  String get fullName => [
        firstName,
        if (middleInitial.isNotEmpty) middleInitial,
        lastName,
      ].join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  AdminUser copyWith({
    String? firstName,
    String? middleInitial,
    String? lastName,
    bool? isActive,
    bool? mustChangePassword,
  }) {
    return AdminUser(
      adminId: adminId,
      teacherId: teacherId,
      username: username,
      role: role,
      firstName: firstName ?? this.firstName,
      middleInitial: middleInitial ?? this.middleInitial,
      lastName: lastName ?? this.lastName,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      mfaEnabled: mfaEnabled,
    );
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      adminId: _readInt(json['admin_id']) ?? 0,
      teacherId: _readInt(json['teacher_id']) ?? 0,
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'teacher',
      firstName: json['first_name'] as String? ?? '',
      middleInitial: json['middle_initial'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      isActive: json['is_active'] == true || _readInt(json['is_active']) == 1,
      mustChangePassword:
          json['must_change_password'] == true ||
          _readInt(json['must_change_password']) == 1,
      mfaEnabled: json['mfa_enabled'] == true || _readInt(json['mfa_enabled']) == 1,
    );
  }
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
