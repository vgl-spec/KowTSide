import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/websocket_service.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final List<String> _wsLog = [];

  @override
  void initState() {
    super.initState();
    WebSocketService.instance.events.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {
        _wsLog.insert(0, '[${event.type}] ${_formatEvent(event)}');
        if (_wsLog.length > 24) {
          _wsLog.removeLast();
        }
      });

      if (event.type == 'sync_complete' || event.type == 'student_registered') {
        ref.invalidate(dashboardProvider);
      }
    });
  }

  String _formatEvent(WsEvent event) {
    switch (event.type) {
      case 'sync_complete':
        return '${event.data['device_name'] ?? 'Device'} synced';
      case 'content_updated':
        return 'Content version updated to ${event.data['version_tag']}';
      case 'student_registered':
        return 'New student synced: ${event.data['nickname'] ?? 'Unknown'}';
      case 'device_connected':
        return '${event.data['device_name'] ?? 'Device'} connected';
      default:
        return event.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final auth = ref.watch(authProvider);

    return SafeArea(
      child: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 10),
              Text('Failed to load dashboard: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(dashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final width = MediaQuery.of(context).size.width;
          final compact = width < 1180;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Chip(
                      avatar: const Icon(Icons.person_outline, size: 16),
                      label: Text(auth.username),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => ref.invalidate(dashboardProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh Data'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _KpiCard(
                      title: 'Total Students',
                      value: '${data.totalStudents}',
                      subtitle: 'Registered learners',
                      icon: Icons.group_rounded,
                      color: AppTheme.primary,
                    ),
                    _KpiCard(
                      title: 'Total Sessions',
                      value: '${data.totalSessions}',
                      subtitle: 'All-time gameplay sessions',
                      icon: Icons.sports_esports_rounded,
                      color: AppTheme.accent,
                    ),
                    _KpiCard(
                      title: 'Active Devices',
                      value: '${data.activeDevices}',
                      subtitle: 'Tablets currently syncing',
                      icon: Icons.tablet_android_rounded,
                      color: AppTheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Age Group Performance',
                  subtitle:
                      'Progress roll-up by age group and subject (from vw_age_group_progress).',
                  child: data.ageGroupProgress.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('No progress data available yet.'),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Group')),
                              DataColumn(label: Text('Subject')),
                              DataColumn(label: Text('Students')),
                              DataColumn(label: Text('Avg Score')),
                              DataColumn(label: Text('Pass Rate')),
                            ],
                            rows: data.ageGroupProgress.map((progress) {
                              final passColor = progress.passRatePct >= 70
                                  ? AppTheme.accent
                                  : progress.passRatePct >= 50
                                  ? AppTheme.tertiary
                                  : AppTheme.error;
                              return DataRow(
                                cells: [
                                  DataCell(Text(progress.gradelvl)),
                                  DataCell(Text(progress.subject)),
                                  DataCell(Text('${progress.activeStudents}')),
                                  DataCell(
                                    Text(progress.avgScore.toStringAsFixed(1)),
                                  ),
                                  DataCell(
                                    Text(
                                      '${progress.passRatePct.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: passColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                if (compact) ...[
                  _buildRecentSyncSection(context, data.recentSyncs),
                  const SizedBox(height: 12),
                  _buildLiveEventsSection(context),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildRecentSyncSection(
                          context,
                          data.recentSyncs,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _buildLiveEventsSection(context)),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentSyncSection(BuildContext context, List recentSyncs) {
    return _SectionCard(
      title: 'Recent Sync Activity',
      subtitle: 'Latest completed device uploads.',
      child: recentSyncs.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: Text('No recent syncs yet.'),
            )
          : Column(
              children: recentSyncs.map((sync) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.sync_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  title: Text(sync.deviceName),
                  subtitle: Text(sync.lastSyncedAt),
                  trailing: Chip(
                    label: Text('${sync.studentsSynced} students'),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildLiveEventsSection(BuildContext context) {
    return _SectionCard(
      title: 'Live Events',
      subtitle: 'WebSocket updates from active sync sessions.',
      child: _wsLog.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Waiting for real-time events...'),
            )
          : Column(
              children: _wsLog.take(10).map((entry) {
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  leading: const Icon(
                    Icons.circle,
                    size: 8,
                    color: AppTheme.accent,
                  ),
                  title: Text(entry, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 286,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
