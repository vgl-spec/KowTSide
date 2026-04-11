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

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter _buildRouter(AuthState auth) => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/dashboard',
      redirect: (context, state) {
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
          builder: (_, _) => const LoginScreen(),
        ),
        ShellRoute(
          navigatorKey: _shellKey,
          builder: (context, state, child) => AppShell(
            currentRoute: state.matchedLocation,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/students',
              builder: (_, _) => const StudentsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => StudentDetailScreen(
                    studId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/questions',
              builder: (_, _) => const QuestionsScreen(),
            ),
            GoRoute(
              path: '/devices',
              builder: (_, _) => const DevicesScreen(),
            ),
            GoRoute(
              path: '/reports',
              builder: (_, _) => const ReportsScreen(),
            ),
            GoRoute(
              path: '/content-versions',
              builder: (_, _) => const ContentVersionsScreen(),
            ),
            GoRoute(
              path: '/audit-log',
              builder: (_, _) => const AuditLogScreen(),
            ),
            GoRoute(
              path: '/sync-logs',
              builder: (_, _) => const SyncLogsScreen(),
            ),
            GoRoute(
              path: '/system-health',
              builder: (_, _) => const SystemHealthScreen(),
            ),
          ],
        ),
      ],
    );

class KowAdminApp extends ConsumerWidget {
  const KowAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final router = _buildRouter(auth);

    return MaterialApp.router(
      title: 'KOW Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
