import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'constants.dart';
import 'role_utils.dart';

class AuthResult {
  final bool success;
  final String? error;
  const AuthResult.ok() : success = true, error = null;
  const AuthResult.fail(this.error) : success = false;
}

/// Handles login/logout and token persistence.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<AuthResult> login(String username, String password) async {

    try {
      final resp = await dio.post(
        ApiConstants.adminLogin,
        data: {'username': username, 'password': password},
      );
      final data = resp.data as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      final token = data['token'] as String? ?? 'cookie-session';
      final csrfToken = data['csrf_token'] as String?;
      await prefs.setString(AppConstants.tokenKey, token);
      if (csrfToken != null) {
        await prefs.setString(AppConstants.csrfTokenKey, csrfToken);
      }
      await prefs.setString(AppConstants.usernameKey, data['username'] as String);
      await prefs.setString(
        AppConstants.roleKey,
        normalizeAdminRole(data['role'] as String? ?? 'teacher'),
      );
      await prefs.setInt(AppConstants.adminIdKey, data['admin_id'] as int? ?? 0);
      return const AuthResult.ok();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const AuthResult.fail(
          'Cannot reach API at ${ApiConstants.baseUrl}. Start backend or use --dart-define-from-file=.env.prod.',
        );
      }
      final msg = (e.response?.data as Map?)?['error'] as String?;
      return AuthResult.fail(msg ?? 'Login failed. Check credentials.');
    } catch (_) {
      return const AuthResult.fail('Unexpected login response format.');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ApiConstants.frontendOnly) {
      try {
        await dio.post(ApiConstants.adminLogout);
      } catch (_) {
        // Local logout should still clear browser state if the API is offline.
      }
    }
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.csrfTokenKey);
    await prefs.remove(AppConstants.usernameKey);
    await prefs.remove(AppConstants.roleKey);
    await prefs.remove(AppConstants.adminIdKey);
  }

  Future<StoredSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) {
      if (ApiConstants.frontendOnly && ApiConstants.autoLogin) {
        await prefs.setString(AppConstants.tokenKey, 'mock-auto-login-token');
        await prefs.setString(AppConstants.usernameKey, 'kow_admin');
        await prefs.setString(AppConstants.roleKey, 'superadmin');
        await prefs.setInt(AppConstants.adminIdKey, 1);
      } else {
        return null;
      }
    }

    return StoredSession(
      token: prefs.getString(AppConstants.tokenKey) ?? '',
      username: prefs.getString(AppConstants.usernameKey) ?? '',
      role: normalizeAdminRole(prefs.getString(AppConstants.roleKey) ?? 'superadmin'),
      adminId: prefs.getInt(AppConstants.adminIdKey) ?? 0,
    );
  }
}

class StoredSession {
  final String token;
  final String username;
  final String role;
  final int adminId;
  const StoredSession({
    required this.token,
    required this.username,
    required this.role,
    required this.adminId,
  });
}
