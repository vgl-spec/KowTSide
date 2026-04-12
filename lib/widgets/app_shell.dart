import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'page_skeletons.dart';

/// Persistent navigation shell with a side drawer on wide screens
/// and a bottom nav on narrow screens.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({super.key, required this.child, required this.currentRoute});

  static const _navItems = [
    _NavItem(
      route: '/dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
    ),
    _NavItem(
      route: '/students',
      label: 'Students',
      icon: Icons.group_outlined,
      activeIcon: Icons.group,
    ),
    _NavItem(
      route: '/questions',
      label: 'Questions',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz,
    ),
    _NavItem(
      route: '/devices',
      label: 'Devices',
      icon: Icons.tablet_android_outlined,
      activeIcon: Icons.tablet_android,
    ),
    _NavItem(
      route: '/reports',
      label: 'Reports',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
    ),
    _NavItem(
      route: '/content-versions',
      label: 'Content',
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
    ),
    _NavItem(
      route: '/audit-log',
      label: 'Audit Log',
      icon: Icons.policy_outlined,
      activeIcon: Icons.policy,
    ),
    _NavItem(
      route: '/sync-logs',
      label: 'Sync Logs',
      icon: Icons.sync_alt_outlined,
      activeIcon: Icons.sync_alt,
    ),
    _NavItem(
      route: '/system-health',
      label: 'Health',
      icon: Icons.health_and_safety_outlined,
      activeIcon: Icons.health_and_safety,
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
    final isWide = width >= 900;
    final showLabels = width >= 1220;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: showLabels ? 260 : 92,
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary,
                border: Border(
                  right: BorderSide(color: scheme.outline.withOpacity(0.3)),
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
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.28),
                              ),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: AppTheme.primary,
                            ),
                          ),
                          if (showLabels) ...[
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KOW Admin',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Control Center',
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
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: AppShell._navItems.length,
                        itemBuilder: (context, index) {
                          final item = AppShell._navItems[index];
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
                              'Quick Actions',
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
                                tooltip: 'Settings',
                                icon: const Icon(Icons.settings_outlined),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Settings page is planned next.',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'Help',
                                icon: const Icon(Icons.help_outline),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'KOW support guide will be added soon.',
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
                            color: scheme.outline.withOpacity(0.28),
                          ),
                        ),
                        child: showLabels
                            ? Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primary
                                        .withOpacity(0.2),
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
                                          auth.role,
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

    // Narrow: bottom nav
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(widget.currentRoute),
        destinations: AppShell._navItems
            .map(
              (n) => NavigationDestination(
                icon: Icon(n.icon),
                selectedIcon: Icon(n.activeIcon),
                label: n.label,
              ),
            )
            .toList(),
        onDestinationSelected: (i) => _navigateTo(AppShell._navItems[i].route),
      ),
    );
  }

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'A';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  int _selectedIndex(String route) {
    for (var i = 0; i < AppShell._navItems.length; i++) {
      if (route.startsWith(AppShell._navItems[i].route)) return i;
    }
    return 0;
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
      if (!mounted) {
        return;
      }
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
    if (route.startsWith('/devices')) {
      return const DevicesLoadingSkeleton();
    }

    return const StandardPageLoadingSkeleton();
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
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
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sign Out'),
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
  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
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
                ? AppTheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.accent.withOpacity(0.35)
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
