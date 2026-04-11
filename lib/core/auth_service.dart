import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'constants.dart';

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
    if (ApiConstants.frontendOnly) {
      final isAdmin =
          username == 'kow_admin' && password == 'Admin@KOW2026';
      final isReadonly =
          username == 'kow_readonly' && password == 'Readonly@KOW2026';
      if (!isAdmin && !isReadonly) {
        return const AuthResult.fail(
          'Frontend-only mode credentials: kow_admin / Admin@KOW2026',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.tokenKey,
        'mock-token-${DateTime.now().millisecondsSinceEpoch}',
      );
      await prefs.setString(AppConstants.usernameKey, username);
      await prefs.setString(
        AppConstants.roleKey,
        isReadonly ? 'readonly' : 'admin',
      );
      await prefs.setInt(AppConstants.adminIdKey, isReadonly ? 2 : 1);
      return const AuthResult.ok();
    }

    try {
      final resp = await dio.post(
        ApiConstants.adminLogin,
        data: {'username': username, 'password': password},
      );
      final data = resp.data as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, data['token'] as String);
      await prefs.setString(AppConstants.usernameKey, data['username'] as String);
      await prefs.setString(AppConstants.roleKey, data['role'] as String);
      await prefs.setInt(AppConstants.adminIdKey, data['admin_id'] as int);
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
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.usernameKey);
    await prefs.remove(AppConstants.roleKey);
    await prefs.remove(AppConstants.adminIdKey);
  }

  Future<StoredSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) return null;
    return StoredSession(
      token: token,
      username: prefs.getString(AppConstants.usernameKey) ?? '',
      role: prefs.getString(AppConstants.roleKey) ?? 'admin',
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
