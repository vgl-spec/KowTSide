import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth_service.dart';
import '../core/constants.dart';
import '../core/role_utils.dart';
import '../core/websocket_service.dart';

class AuthState {
  final String? token;
  final String username;
  final String role;
  final int adminId;
  final bool isLoading;

  const AuthState({
    this.token,
    this.username = '',
    this.role = 'superadmin',
    this.adminId = 0,
    this.isLoading = true,
  });

  bool get isAuthenticated => token != null;
  bool get isSuperadmin => isSuperadminRole(role);

  AuthState copyWith({
    String? token,
    String? username,
    String? role,
    int? adminId,
    bool? isLoading,
  }) => AuthState(
        token: token ?? this.token,
        username: username ?? this.username,
        role: role ?? this.role,
        adminId: adminId ?? this.adminId,
        isLoading: isLoading ?? this.isLoading,
      );

  static const unauthenticated = AuthState(isLoading: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restoreFuture = _restore();
  }

  late final Future<void> _restoreFuture;

  Future<void> _restore() async {
    final session = await AuthService.instance.loadSession();
    if (session != null) {
      if (!ApiConstants.frontendOnly) {
        WebSocketService.instance.connect(session.token);
      }
      state = AuthState(
        token: session.token,
        username: session.username,
        role: normalizeAdminRole(session.role),
        adminId: session.adminId,
        isLoading: false,
      );
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<String?> login(String username, String password) async {
    // Avoid a race where startup restore overwrites a fresh login state.
    await _restoreFuture;
    state = state.copyWith(isLoading: true);
    final result = await AuthService.instance.login(username, password);
    if (result.success) {
      final session = await AuthService.instance.loadSession();
      if (session != null) {
        if (!ApiConstants.frontendOnly) {
          WebSocketService.instance.connect(session.token);
        }
        state = AuthState(
          token: session.token,
          username: session.username,
          role: normalizeAdminRole(session.role),
          adminId: session.adminId,
          isLoading: false,
        );
        return null; // no error
      }

      state = AuthState.unauthenticated;
      return 'Login succeeded but session was not saved. Please try again.';
    } else {
      state = state.copyWith(isLoading: false);
      return result.error;
    }
  }

  Future<void> logout() async {
    if (!ApiConstants.frontendOnly) {
      WebSocketService.instance.disconnect();
    }
    await AuthService.instance.logout();
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
