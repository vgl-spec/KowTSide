import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../core/role_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'page_skeletons.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({super.key, required this.child, required this.currentRoute});

  static const _navItems = [
    _NavItem(
      route: '/dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    _NavItem(
      route: '/students',
      label: 'Learners',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    _NavItem(
      route: '/questions',
      label: 'Question Bank',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
    ),
    _NavItem(
      route: '/reports',
      label: 'Reports',
      icon: Icons.insert_chart_outlined_rounded,
      activeIcon: Icons.insert_chart_rounded,
    ),
    _NavItem(
      route: '/activity-logs',
      label: 'Activity Logs',
      icon: Icons.history_rounded,
      activeIcon: Icons.manage_history_rounded,
    ),
    _NavItem(
      route: '/userbase',
      label: 'Userbase',
      icon: Icons.admin_panel_settings_outlined,
      activeIcon: Icons.admin_panel_settings_rounded,
      superadminOnly: true,
    ),
    _NavItem(
      route: '/devices',
      label: 'Devices',
      icon: Icons.tablet_android_outlined,
      activeIcon: Icons.tablet_android_rounded,
      superadminOnly: true,
    ),
    _NavItem(
      route: '/sync-logs',
      label: 'Sync Logs',
      icon: Icons.sync_outlined,
      activeIcon: Icons.sync_rounded,
      superadminOnly: true,
    ),
    _NavItem(
      route: '/system-health',
      label: 'System Health',
      icon: Icons.health_and_safety_outlined,
      activeIcon: Icons.health_and_safety_rounded,
      superadminOnly: true,
    ),
  ];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _isRouteSwitching = false;
  String? _pendingRoute;

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isRouteSwitching && widget.currentRoute != oldWidget.currentRoute) {
      setState(() {
        _isRouteSwitching = false;
        _pendingRoute = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkTheme = themeMode == ThemeMode.dark;
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 960;
    final showLabels = width >= 1240;
    final navItems = AppShell._navItems
        .where((item) => !item.superadminOnly || isSuperadminRole(auth.role))
        .toList();

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: showLabels ? 272 : 92,
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary,
                border: Border(
                  right: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.28),
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        showLabels ? 20 : 0,
                        20,
                        16,
                        16,
                      ),
                      child: Row(
                        mainAxisAlignment: showLabels
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.26),
                              ),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: AppTheme.primary,
                            ),
                          ),
                          if (showLabels) ...[
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KOW Teacher',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Classroom Console',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: navItems.length,
                        itemBuilder: (context, index) {
                          final item = navItems[index];
                          final selected = widget.currentRoute.startsWith(
                            item.route,
                          );
                          return _DrawerMenuTile(
                            item: item,
                            selected: selected,
                            showLabel: showLabels,
                            onPressed: () => _navigateTo(item.route),
                          );
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Divider(height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: Row(
                        mainAxisAlignment: showLabels
                            ? MainAxisAlignment.spaceBetween
                            : MainAxisAlignment.center,
                        children: [
                          if (showLabels)
                            Text(
                              'Quick actions',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: isDarkTheme
                                    ? 'Switch to light theme'
                                    : 'Switch to dark theme',
                                icon: Icon(
                                  isDarkTheme
                                      ? Icons.light_mode_outlined
                                      : Icons.dark_mode_outlined,
                                ),
                                onPressed: () => ref
                                    .read(themeModeProvider.notifier)
                                    .toggleThemeMode(),
                              ),
                              IconButton(
                                tooltip: 'Teacher guide',
                                icon: const Icon(Icons.help_outline),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Learners are read-only. Question edits automatically update the content version for student devices.',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Container(
                        padding: EdgeInsets.all(showLabels ? 10 : 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.28),
                          ),
                        ),
                        child: showLabels
                            ? Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primary
                                        .withValues(alpha: 0.2),
                                    child: Text(
                                      _initials(auth.username),
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          auth.username,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          roleDisplayName(auth.role),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Sign out',
                                    icon: const Icon(Icons.logout_outlined),
                                    onPressed: () =>
                                        _confirmLogout(context, ref),
                                  ),
                                ],
                              )
                            : IconButton(
                                tooltip: 'Sign out',
                                icon: const Icon(Icons.logout_outlined),
                                onPressed: () => _confirmLogout(context, ref),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: widget.child),
                  if (_isRouteSwitching)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: _buildRouteSkeleton(
                          _pendingRoute ?? widget.currentRoute,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),
          if (_isRouteSwitching)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: _buildRouteSkeleton(
                  _pendingRoute ?? widget.currentRoute,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'theme-toggle-fab',
        onPressed: () => ref.read(themeModeProvider.notifier).toggleThemeMode(),
        child: Icon(
          isDarkTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            border: Border(
              top: BorderSide(color: scheme.outline.withValues(alpha: 0.28)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: navItems.map((item) {
              final selected = widget.currentRoute.startsWith(item.route);
              return _BottomNavChip(
                item: item,
                selected: selected,
                onPressed: () => _navigateTo(item.route),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'A';

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  void _navigateTo(String route) {
    if (widget.currentRoute == route) {
      return;
    }

    setState(() {
      _isRouteSwitching = true;
      _pendingRoute = route;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(route);
    });
  }

  Widget _buildRouteSkeleton(String route) {
    if (route.startsWith('/dashboard')) {
      return const DashboardLoadingSkeleton();
    }
    if (route.startsWith('/students/')) {
      return const StudentDetailLoadingSkeleton();
    }
    if (route.startsWith('/students')) {
      return const StudentsLoadingSkeleton();
    }
    if (route.startsWith('/questions')) {
      return const QuestionsLoadingSkeleton();
    }
    if (route.startsWith('/reports')) {
      return const ReportsLoadingSkeleton();
    }
    if (route.startsWith('/activity-logs') ||
        route.startsWith('/userbase')) {
      return const StandardPageLoadingSkeleton();
    }
    if (route.startsWith('/devices')) {
      return const DevicesLoadingSkeleton();
    }
    if (route.startsWith('/sync-logs')) {
      return const SyncLogsLoadingSkeleton();
    }
    if (route.startsWith('/system-health')) {
      return const SystemHealthLoadingSkeleton();
    }
    return const StandardPageLoadingSkeleton();
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool superadminOnly;

  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.superadminOnly = false,
  });
}

class _DrawerMenuTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool showLabel;
  final VoidCallback onPressed;

  const _DrawerMenuTile({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const selectedColor = AppTheme.primary;
    final textColor = selected
        ? selectedColor
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 0),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.accent.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: showLabel
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 20,
                color: textColor,
              ),
              if (showLabel) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavChip extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onPressed;

  const _BottomNavChip({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const selectedColor = AppTheme.primary;
    final color = selected
        ? selectedColor
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? selectedColor.withValues(alpha: 0.32)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
