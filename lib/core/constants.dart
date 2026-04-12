/// All API endpoint constants.
/// API_BASE_URL is injected at build time via --dart-define.
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static final bool frontendOnly =
      const String.fromEnvironment(
        'FRONTEND_ONLY',
        defaultValue: 'false',
      ).toLowerCase() ==
      'true';

  // Auth
  static String get adminLogin => '$baseUrl/api/auth/admin/login';

  // Admin
  static String get dashboard => '$baseUrl/api/admin/dashboard';
  static String get students => '$baseUrl/api/admin/students';
  static String student(int id) => '$baseUrl/api/admin/students/$id';
  static String get questions => '$baseUrl/api/admin/questions';
  static String question(int id) => '$baseUrl/api/admin/questions/$id';
  static String get devices => '$baseUrl/api/admin/devices';

  // Health
  static String get health => '$baseUrl/health';

  // WebSocket — swap http(s) → ws(s)
  static String get wsUrl =>
      '${baseUrl.replaceFirst(RegExp(r'^http'), 'ws')}/ws';
}

class AppConstants {
  static const String tokenKey = 'kow_admin_jwt';
  static const String usernameKey = 'kow_admin_username';
  static const String roleKey = 'kow_admin_role';
  static const String adminIdKey = 'kow_admin_id';
  static const String themeModeKey = 'kow_admin_theme_mode';
}
