import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/system_monitoring.dart';
import '../providers/live_updates_provider.dart';
import '../providers/system_monitoring_provider.dart';
import '../widgets/page_skeletons.dart';

class SystemHealthScreen extends ConsumerWidget {
  const SystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(wsEventsProvider, (_, next) {
      next.whenData((event) {
        if (shouldInvalidateForWsEvent(event.type)) {
          ref.invalidate(systemHealthProvider);
        }
      });
    });

    final healthAsync = ref.watch(systemHealthProvider);
    return SafeArea(
      child: healthAsync.when(
        loading: () => const SystemHealthLoadingSkeleton(),
        error: (error, _) => _ErrorState(
          message: 'Failed to load system health: $error',
          onRetry: () => ref.invalidate(systemHealthProvider),
        ),
        data: (health) => _SystemHealthBody(health: health),
      ),
    );
  }
}

class _SystemHealthBody extends ConsumerWidget {
  final SystemHealthData health;

  const _SystemHealthBody({required this.health});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final rowTileWidth = width >= 1440
        ? 170.0
        : width >= 1100
        ? 160.0
        : width >= 760
        ? (width - 96) / 2
        : width - 48;
    final healthColumns = width >= 1680
        ? 4
        : width >= 1320
        ? 3
        : width >= 900
        ? 2
        : 1;
    final cards = [
      _HealthCard(
        title: 'API Gateway',
        status: health.apiHealthy ? 'Healthy' : 'Degraded',
        metric: health.status.toUpperCase(),
        detail: 'Last checked ${_formatTimestamp(health.timestamp)}',
        color: health.apiHealthy ? AppTheme.accent : AppTheme.warning,
        icon: Icons.api_rounded,
      ),
      _HealthCard(
        title: 'Oracle Database',
        status: health.dbHealthy ? 'Healthy' : 'Down',
        metric: health.dbHealthy
            ? '${health.oracleDetails.responseMs} ms'
            : health.oracle.toUpperCase(),
        detail: health.dbHealthy
            ? 'DB time ${_formatTimestamp(health.oracleDetails.dbTime)}'
            : (health.oracleDetails.error ?? 'Database connection failed'),
        color: health.dbHealthy ? AppTheme.success : AppTheme.error,
        icon: Icons.storage_rounded,
      ),
      _HealthCard(
        title: 'WebSocket Broker',
        status: health.wsHealthy ? 'Connected' : 'Idle',
        metric: '${health.wsClients} clients',
        detail: 'Admin dashboards listening for live events',
        color: health.wsHealthy ? AppTheme.info : AppTheme.warning,
        icon: Icons.wifi_tethering_rounded,
      ),
      _HealthCard(
        title: 'Device Sync',
        status:
            health.syncedDevices == health.activeDevices &&
                health.activeDevices > 0
            ? 'In sync'
            : 'Needs attention',
        metric: '${health.syncedDevices}/${health.activeDevices}',
        detail: 'Synced versus registered devices',
        color:
            health.syncedDevices == health.activeDevices &&
                health.activeDevices > 0
            ? AppTheme.accent
            : AppTheme.tertiary,
        icon: Icons.tablet_android_rounded,
      ),
    ];

    final rowCountTiles = [
      _CountTile(
        label: 'Students',
        value: '${health.rowCounts.students}',
        color: AppTheme.primary,
      ),
      _CountTile(
        label: 'Scores',
        value: '${health.rowCounts.scores}',
        color: AppTheme.info,
      ),
      _CountTile(
        label: 'Questions',
        value: '${health.rowCounts.activeQuestions}',
        color: AppTheme.success,
      ),
      _CountTile(
        label: 'Devices',
        value: '${health.rowCounts.devices}',
        color: AppTheme.primary,
      ),
      _CountTile(
        label: 'Sync Logs',
        value: '${health.rowCounts.syncLogs}',
        color: AppTheme.tertiary,
      ),
      _CountTile(
        label: 'Admins',
        value: '${health.rowCounts.admins}',
        color: AppTheme.warning,
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(systemHealthProvider);
        await ref.read(systemHealthProvider.future);
      },
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
                'System Health',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              FilledButton.tonalIcon(
                onPressed: () => ref.invalidate(systemHealthProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh Health'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: healthColumns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width >= 1320
                ? 3.35
                : width >= 900
                ? 2.95
                : 2.65,
            children: cards,
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Live Row Counts',
            subtitle:
                'These values come directly from the PM2-backed Oracle tables.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: rowCountTiles
                  .map((tile) => SizedBox(width: rowTileWidth, child: tile))
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          if (health.oracleDetails.pool != null)
            _SectionCard(
              title: 'Oracle Pool Snapshot',
              subtitle:
                  'Current connection pool state reported by the running API process.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PoolTile(
                    label: 'Pool Min',
                    value: '${health.oracleDetails.pool!.poolMin}',
                  ),
                  _PoolTile(
                    label: 'Pool Max',
                    value: '${health.oracleDetails.pool!.poolMax}',
                  ),
                  _PoolTile(
                    label: 'Open',
                    value: '${health.oracleDetails.pool!.connectionsOpen}',
                  ),
                  _PoolTile(
                    label: 'In Use',
                    value: '${health.oracleDetails.pool!.connectionsInUse}',
                  ),
                ],
              ),
            ),
          if (health.oracleDetails.pool != null) const SizedBox(height: 14),
          _SectionCard(
            title: 'Runtime Snapshot',
            subtitle:
                'Live process metrics from the active Node.js API instance.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricPill(
                  label: 'Uptime',
                  value: _formatUptime(health.uptimeSeconds),
                  color: AppTheme.accent,
                ),
                _MetricPill(
                  label: 'Memory RSS',
                  value: _formatBytes(health.rssBytes),
                  color: AppTheme.info,
                ),
                _MetricPill(
                  label: 'Heap Used',
                  value: _formatBytes(health.heapUsedBytes),
                  color: AppTheme.primary,
                ),
                _MetricPill(
                  label: 'Heap Total',
                  value: _formatBytes(health.heapTotalBytes),
                  color: AppTheme.warning,
                ),
                _MetricPill(
                  label: 'Invalid Objects',
                  value: '${health.invalidObjectCount}',
                  color: health.invalidObjectCount == 0
                      ? AppTheme.accent
                      : AppTheme.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Object Status Summary',
            subtitle:
                'Health of Oracle tables, views, procedures, triggers, and sequences.',
            child: health.objectStatusSummary.isEmpty
                ? const _EmptyState(
                    message: 'No Oracle object summary was returned.',
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: health.objectStatusSummary.map((item) {
                      final isValid = item.status.toUpperCase() == 'VALID';
                      return _StatusSummaryPill(
                        label: '${item.objectType} ${item.status}',
                        value: '${item.count}',
                        color: isValid ? AppTheme.accent : AppTheme.error,
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Critical Oracle Objects',
            subtitle:
                'Tracked schema objects required by devices, analytics, and the teacher console.',
            child: health.criticalObjects.isEmpty
                ? const _EmptyState(
                    message: 'No critical object metadata was returned.',
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final desktopTable = constraints.maxWidth >= 1050;
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLow.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.all(desktopTable ? 14 : 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: desktopTable
                                  ? constraints.maxWidth - 16
                                  : constraints.maxWidth,
                            ),
                            child: DataTable(
                              columnSpacing: desktopTable ? 30 : 16,
                              horizontalMargin: desktopTable ? 18 : 10,
                              headingRowHeight: 52,
                              dataRowMinHeight: desktopTable ? 58 : 50,
                              dataRowMaxHeight: desktopTable ? 66 : 58,
                              columns: const [
                                DataColumn(
                                  label: SizedBox(
                                    width: 300,
                                    child: Text('Object'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 160,
                                    child: Text('Type'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 120,
                                    child: Text('Status'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 180,
                                    child: Text('Last DDL'),
                                  ),
                                ),
                              ],
                              rows: health.criticalObjects.map((item) {
                                final valid =
                                    item.status.toUpperCase() == 'VALID';
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 300,
                                        child: Text(
                                          item.objectName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 160,
                                        child: Text(item.objectType),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: _StatusChip(
                                          label: item.status,
                                          color: valid
                                              ? AppTheme.accent
                                              : AppTheme.error,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 180,
                                        child: Text(
                                          _formatTimestamp(item.lastDdlTime),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String title;
  final String status;
  final String metric;
  final String detail;
  final Color color;
  final IconData icon;

  const _HealthCard({
    required this.title,
    required this.status,
    required this.metric,
    required this.detail,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusChip(label: status, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              metric,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CountTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
          ),
        ],
      ),
    );
  }
}

class _PoolTile extends StatelessWidget {
  final String label;
  final String value;

  const _PoolTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusSummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _formatTimestamp(DateTime? value) {
  if (value == null) return 'Unknown';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _formatUptime(int seconds) {
  final days = seconds ~/ 86400;
  final hours = (seconds % 86400) ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return '${days}d ${hours}h ${minutes}m';
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unitIndex = 0;

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex += 1;
  }

  final formatted = unitIndex == 0
      ? size.toStringAsFixed(0)
      : size.toStringAsFixed(1);
  return '$formatted ${units[unitIndex]}';
}
