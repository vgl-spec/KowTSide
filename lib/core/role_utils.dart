String normalizeAdminRole(String role) {
  final value = role.trim().toLowerCase();
  if (value == 'admin') return 'superadmin';
  if (value == 'readonly') return 'teacher';
  if (value == 'superadmin' || value == 'teacher') return value;
  return value;
}

String roleDisplayName(String role) {
  switch (normalizeAdminRole(role)) {
    case 'superadmin':
      return 'Superadmin';
    case 'teacher':
      return 'Teacher';
    default:
      return role.isEmpty ? 'Unknown' : role;
  }
}

bool isSuperadminRole(String role) => normalizeAdminRole(role) == 'superadmin';
