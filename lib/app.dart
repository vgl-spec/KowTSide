import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/students_screen.dart';
import 'screens/student_detail_screen.dart';
import 'screens/questions_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/content_versions_screen.dart';
import 'screens/audit_log_screen.dart';
import 'screens/sync_logs_screen.dart';
import 'screens/system_health_screen.dart';
import 'widgets/app_shell.dart';
import 'core/theme.dart';
import 'providers/theme_provider.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

class KowAdminApp extends ConsumerStatefulWidget {
  const KowAdminApp({super.key});

  @override
  ConsumerState<KowAdminApp> createState() => _KowAdminAppState();
}

class _KowAdminAppState extends ConsumerState<KowAdminApp> {
  late final GoRouter _router;

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
      initialLocation: '/dashboard',
      redirect: (context, state) {
        final auth = ref.read(authProvider);
        if (auth.isLoading) return null;
        final isLoggedIn = auth.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login';
        if (!isLoggedIn && !isLoginRoute) return '/login';
        if (isLoggedIn && isLoginRoute) return '/dashboard';
        return null;
      },
      routes: [
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
                    final studId = int.parse(state.pathParameters['id']!);
                    return _page(state, StudentDetailScreen(studId: studId));
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/questions',
              pageBuilder: (context, state) =>
                  _page(state, const QuestionsScreen()),
            ),
            GoRoute(
              path: '/devices',
              pageBuilder: (context, state) =>
                  _page(state, const DevicesScreen()),
            ),
            GoRoute(
              path: '/reports',
              pageBuilder: (context, state) =>
                  _page(state, const ReportsScreen()),
            ),
            GoRoute(
              path: '/content-versions',
              pageBuilder: (context, state) =>
                  _page(state, const ContentVersionsScreen()),
            ),
            GoRoute(
              path: '/audit-log',
              pageBuilder: (context, state) =>
                  _page(state, const AuditLogScreen()),
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
      title: 'KOW Admin',
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
