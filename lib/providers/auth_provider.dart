import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../core/constants.dart';
import '../core/role_utils.dart';
import '../core/websocket_service.dart';

class AuthState {
  final String? token;
  final String authMode;
  final String username;
  final String role;
  final int adminId;
  final bool isLoading;

  const AuthState({
    this.token,
    this.authMode = '',
    this.username = '',
    this.role = 'superadmin',
    this.adminId = 0,
    this.isLoading = true,
  });

  bool get isAuthenticated => token != null && token!.trim().isNotEmpty;
  bool get isSuperadmin => isSuperadminRole(role);

  AuthState copyWith({
    String? token,
    String? authMode,
    String? username,
    String? role,
    int? adminId,
    bool? isLoading,
  }) => AuthState(
    token: token ?? this.token,
    authMode: authMode ?? this.authMode,
    username: username ?? this.username,
    role: role ?? this.role,
    adminId: adminId ?? this.adminId,
    isLoading: isLoading ?? this.isLoading,
  );

  static const unauthenticated = AuthState(isLoading: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _unauthorizedSub = ApiClient.instance.unauthorizedEvents.listen((_) async {
      if (!state.isAuthenticated) return;
      await _setUnauthenticated();
    });
    _restoreFuture = _restore();
  }

  late final Future<void> _restoreFuture;
  StreamSubscription<void>? _unauthorizedSub;

  Future<void> _restore() async {
    final session = await AuthService.instance.loadSession();
    if (session != null) {
      if (!ApiConstants.frontendOnly && session.token != 'cookie-session') {
        WebSocketService.instance.connect(session.token);
      }
      state = AuthState(
        token: session.token,
        authMode: session.authMode,
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
    await _restoreFuture;
    state = state.copyWith(isLoading: true);
    final result = await AuthService.instance.login(username, password);
    if (result.success) {
      final session = await AuthService.instance.loadSession();
      if (session != null) {
        if (!ApiConstants.frontendOnly && session.token != 'cookie-session') {
          WebSocketService.instance.connect(session.token);
        }
        state = AuthState(
          token: session.token,
          authMode: session.authMode,
          username: session.username,
          role: normalizeAdminRole(session.role),
          adminId: session.adminId,
          isLoading: false,
        );
        return null;
      }

      state = AuthState.unauthenticated;
      return 'Login succeeded but session was not saved. Please try again.';
    } else {
      state = state.copyWith(isLoading: false);
      return result.error;
    }
  }

  Future<void> logout() async {
    await _setUnauthenticated();
  }

  Future<void> _setUnauthenticated() async {
    WebSocketService.instance.disconnect();
    await AuthService.instance.logout();
    state = AuthState.unauthenticated;
  }

  @override
  void dispose() {
    _unauthorizedSub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
