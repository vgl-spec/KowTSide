import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/role_utils.dart';
import 'core/student_id.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/activity_logs_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/student_detail_screen.dart';
import 'screens/students_screen.dart';
import 'screens/sync_logs_screen.dart';
import 'screens/system_health_screen.dart';
import 'screens/teacher_questions_screen.dart';
import 'screens/userbase_screen.dart';
import 'widgets/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

class KowAdminApp extends ConsumerStatefulWidget {
  const KowAdminApp({super.key});

  @override
  ConsumerState<KowAdminApp> createState() => _KowAdminAppState();
}

class _KowAdminAppState extends ConsumerState<KowAdminApp> {
  late final GoRouter _router;
  static const _bootstrapRoute = '/bootstrap';

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
  }

  NoTransitionPage<void> _page(GoRouterState state, Widget child) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  GoRouter _buildRouter() {
    return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: _bootstrapRoute,
      redirect: (context, state) {
        final auth = ref.read(authProvider);
        final location = state.matchedLocation;
        final isBootstrapRoute = location == _bootstrapRoute;
        if (auth.isLoading) {
          return isBootstrapRoute ? null : _bootstrapRoute;
        }

        final isLoggedIn = auth.isAuthenticated;
        final isLoginRoute = location == '/login';
        final isSuperadmin = isSuperadminRole(auth.role);
        final superadminOnly = {
          '/userbase',
          '/devices',
          '/sync-logs',
          '/system-health',
        };

        if (isBootstrapRoute) {
          return isLoggedIn ? '/dashboard' : '/login';
        }
        if (!isLoggedIn && !isLoginRoute) return '/login';
        if (isLoggedIn && isLoginRoute) return '/dashboard';
        if (isLoggedIn &&
            !isSuperadmin &&
            superadminOnly.any(
              (route) => state.matchedLocation.startsWith(route),
            )) {
          return '/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: _bootstrapRoute,
          pageBuilder: (context, state) =>
              _page(state, const _BootstrapScreen()),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => _page(state, const LoginScreen()),
        ),
        ShellRoute(
          navigatorKey: _shellKey,
          pageBuilder: (context, state, child) => _page(
            state,
            AppShell(currentRoute: state.matchedLocation, child: child),
          ),
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) =>
                  _page(state, const DashboardScreen()),
            ),
            GoRoute(
              path: '/students',
              pageBuilder: (context, state) =>
                  _page(state, const StudentsScreen()),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) {
                    final studId = parseStudentId(state.pathParameters['id']);
                    if (studId == null) {
                      throw const FormatException('Invalid student id.');
                    }
                    return _page(state, StudentDetailScreen(studId: studId));
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/questions',
              pageBuilder: (context, state) =>
                  _page(state, const TeacherQuestionsScreen()),
            ),
            GoRoute(
              path: '/reports',
              pageBuilder: (context, state) => _page(
                state,
                ReportsScreen(focusSection: state.uri.queryParameters['focus']),
              ),
            ),
            GoRoute(
              path: '/activity-logs',
              pageBuilder: (context, state) =>
                  _page(state, const ActivityLogsScreen()),
            ),
            GoRoute(
              path: '/userbase',
              pageBuilder: (context, state) =>
                  _page(state, const UserbaseScreen()),
            ),
            GoRoute(
              path: '/devices',
              pageBuilder: (context, state) =>
                  _page(state, const DevicesScreen()),
            ),
            GoRoute(
              path: '/sync-logs',
              pageBuilder: (context, state) =>
                  _page(state, const SyncLogsScreen()),
            ),
            GoRoute(
              path: '/system-health',
              pageBuilder: (context, state) =>
                  _page(state, const SystemHealthScreen()),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    ref.listen<AuthState>(authProvider, (previous, next) => _router.refresh());

    AppTheme.setThemeMode(themeMode);

    return MaterialApp.router(
      title: 'KOW Teacher Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      themeAnimationCurve: Curves.linear,
      routerConfig: _router,
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}
