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

  static final bool autoLogin =
      const String.fromEnvironment(
        'AUTO_LOGIN',
        defaultValue: 'false',
      ).toLowerCase() ==
      'true';

  // Auth
  static String get adminLogin => '$baseUrl/api/auth/admin/login';
  static String get adminLogout => '$baseUrl/api/auth/admin/logout';
  static String get csrf => '$baseUrl/api/auth/csrf';
  static String get mfaVerify => '$baseUrl/api/auth/admin/mfa/verify';

  // Admin
  static String get dashboard => '$baseUrl/api/admin/dashboard';
  static String get students => '$baseUrl/api/admin/students';
  static String student(int id) => '$baseUrl/api/admin/students/$id';
  static String get questions => '$baseUrl/api/admin/questions';
  static String question(int id) => '$baseUrl/api/admin/questions/$id';
  static String get questionUpload => '$baseUrl/api/admin/upload/image';
  static String get leaderboard => '$baseUrl/api/leaderboard';
  static String get content => '$baseUrl/api/content';
  static String get devices => '$baseUrl/api/admin/devices';
  static String get reports => '$baseUrl/api/admin/reports';
  static String get syncLogs => '$baseUrl/api/admin/sync-logs';
  static String get systemHealth => '$baseUrl/api/admin/system-health';
  static String get activityLogs => '$baseUrl/api/admin/activity-logs';
  static String get teacherUsers => '$baseUrl/api/admin/users/teachers';
  static String teacherUser(int id) => '$baseUrl/api/admin/users/teachers/$id';
  static String teacherPasswordReset(int id) =>
      '$baseUrl/api/admin/users/teachers/$id/reset-password';
  static String teacherStatus(int id) =>
      '$baseUrl/api/admin/users/teachers/$id/status';
  static String get questionImportGenerate =>
      '$baseUrl/api/admin/questions/import/generate';
  static String get questionImportCommit =>
      '$baseUrl/api/admin/questions/import/commit';

  // Health
  static String get health => '$baseUrl/health';

  // WebSocket — swap http(s) → ws(s)
  static String get wsUrl =>
      '${baseUrl.replaceFirst(RegExp(r'^http'), 'ws')}/ws';
}

class AppConstants {
  static const String tokenKey = 'kow_admin_jwt';
  static const String csrfTokenKey = 'kow_admin_csrf';
  static const String usernameKey = 'kow_admin_username';
  static const String roleKey = 'kow_admin_role';
  static const String adminIdKey = 'kow_admin_id';
  static const String themeModeKey = 'kow_admin_theme_mode';
}
