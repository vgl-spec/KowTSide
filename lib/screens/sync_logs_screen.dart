import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/system_monitoring.dart';
import '../providers/live_updates_provider.dart';
import '../providers/system_monitoring_provider.dart';
import '../widgets/page_skeletons.dart';

class SyncLogsScreen extends ConsumerStatefulWidget {
  const SyncLogsScreen({super.key});

  @override
  ConsumerState<SyncLogsScreen> createState() => _SyncLogsScreenState();
}

class _SyncLogsScreenState extends ConsumerState<SyncLogsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'All';
  int _page = 1;

  static const int _rowsPerPage = 12;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(wsEventsProvider, (_, next) {
      next.whenData((event) {
        if (shouldInvalidateForWsEvent(event.type)) {
          ref.invalidate(syncLogsProvider);
        }
      });
    });

    final syncLogsAsync = ref.watch(syncLogsProvider);
    final syncLogs = syncLogsAsync.valueOrNull;
    if (syncLogsAsync.isLoading && syncLogs == null) {
      return const SafeArea(child: SyncLogsLoadingSkeleton());
    }

    if (syncLogsAsync.hasError && syncLogs == null) {
      return SafeArea(
        child: _ErrorState(
          message: 'Failed to load sync logs: ${syncLogsAsync.error}',
          onRetry: () => ref.invalidate(syncLogsProvider),
        ),
      );
    }

    final records = _filtered(syncLogs?.records ?? const []);
    final successRate = syncLogs?.successRate ?? 0;
    final failedCount = syncLogs?.failedCount ?? 0;
    final skippedCount = syncLogs?.skippedCount ?? 0;
    final totalCount = syncLogs?.records.length ?? 0;
    final compact = MediaQuery.of(context).size.width < 980;
    final totalPages = records.isEmpty
      ? 1
      : ((records.length + _rowsPerPage - 1) ~/ _rowsPerPage);
    final safePage = _page > totalPages ? totalPages : _page;
    final startIndex = (safePage - 1) * _rowsPerPage;
    final pageRecords = records.skip(startIndex).take(_rowsPerPage).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(syncLogsProvider);
          await ref.read(syncLogsProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Sync Logs',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(
                  width: compact ? MediaQuery.of(context).size.width - 80 : 320,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() => _page = 1),
                    decoration: InputDecoration(
                      hintText: 'Search by device, event, or id...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _page = 1;
                        }),
                      ),
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => ref.invalidate(syncLogsProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh Logs'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: compact ? 1 : 4,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: compact ? 2.8 : 1.8,
              children: [
                _MiniStatCard(
                  title: 'Success Rate',
                  value: '${successRate.toStringAsFixed(1)}%',
                  subtitle: 'Derived from recent sync batches',
                  icon: Icons.timeline_rounded,
                  color: AppTheme.accent,
                ),
                _MiniStatCard(
                  title: 'Failures',
                  value: '$failedCount',
                  subtitle: 'Sync batches marked failed',
                  icon: Icons.report_problem_rounded,
                  color: AppTheme.error,
                ),
                _MiniStatCard(
                  title: 'Skipped',
                  value: '$skippedCount',
                  subtitle: 'Non-critical or no-op syncs',
                  icon: Icons.skip_next_rounded,
                  color: AppTheme.tertiary,
                ),
                _MiniStatCard(
                  title: 'Processed',
                  value: '$totalCount',
                  subtitle: 'Latest records from the backend',
                  icon: Icons.sync_rounded,
                  color: AppTheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Transaction Logs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        dropdownColor: AppTheme.surface,
                        items: const ['All', 'Success', 'Failed', 'Skipped']
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _statusFilter = value;
                              _page = 1;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 1100;
                final tableMinWidth = desktop
                    ? constraints.maxWidth - 20
                    : constraints.maxWidth;

                return Card(
                  child: records.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No sync records match your current filters.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.all(desktop ? 14 : 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: tableMinWidth,
                              ),
                              child: DataTable(
                                columnSpacing: desktop ? 32 : 18,
                                horizontalMargin: desktop ? 20 : 12,
                                headingRowHeight: 54,
                                dataRowMinHeight: desktop ? 60 : 52,
                                dataRowMaxHeight: desktop ? 70 : 60,
                                columns: const [
                                  DataColumn(
                                    label: SizedBox(
                                      width: 240,
                                      child: Text('Device UUID'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 250,
                                      child: Text('Device Name'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 190,
                                      child: Text('Event'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 160,
                                      child: Text('Received'),
                                    ),
                                  ),
                                  DataColumn(
                                    numeric: true,
                                    label: SizedBox(
                                      width: 110,
                                      child: Text('Students'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 130,
                                      child: Text('Status'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 320,
                                      child: Text('Error'),
                                    ),
                                  ),
                                ],
                                rows: pageRecords.map((record) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 240,
                                          child: Text(
                                            record.deviceUuid,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 250,
                                          child: Text(
                                            record.deviceName,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 190,
                                          child: Text(
                                            record.eventType,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 160,
                                          child: Text(
                                            _formatManilaTimestamp(
                                              record.syncedAt,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 110,
                                          child: Text(
                                            '${record.studentsSynced}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 130,
                                          child: _StatusPill(
                                            status: record.status,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 320,
                                          child: Text(
                                            (record.errorMessage ??
                                                    record.errorPayload ??
                                                    '')
                                                .trim()
                                                .isEmpty
                                                ? '-'
                                                : (record.errorMessage ??
                                                      record.errorPayload ??
                                                      ''),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: record.isFailed
                                                  ? AppTheme.error
                                                  : null,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                );
              },
            ),
            const SizedBox(height: 12),
            _SyncLogPaginationBar(
              page: safePage,
              totalPages: totalPages,
              totalRows: records.length,
              rowsPerPage: _rowsPerPage,
              onPageSelected: (page) => setState(() => _page = page),
            ),
          ],
        ),
      ),
    );
  }

  List<SyncLogRecord> _filtered(List<SyncLogRecord> source) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return source.where((record) {
      final statusMatches =
          _statusFilter == 'All' ||
          record.status == _statusFilter.toLowerCase();
      if (!statusMatches) return false;
      if (query.isEmpty) return true;
      return record.deviceUuid.toLowerCase().contains(query) ||
          record.deviceName.toLowerCase().contains(query) ||
          record.eventType.toLowerCase().contains(query);
    }).toList();
  }

  String _formatManilaTimestamp(DateTime? value) {
    if (value == null) return 'Not synced yet';
    final manilaTime = value.toUtc().add(const Duration(hours: 8));
    return DateFormat('dd MMM yyyy, hh:mm a').format(manilaTime);
  }
}

class _SyncLogPaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalRows;
  final int rowsPerPage;
  final ValueChanged<int> onPageSelected;

  const _SyncLogPaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalRows,
    required this.rowsPerPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pages = _visiblePages(page, totalPages);
    final startRow = totalRows == 0 ? 0 : ((page - 1) * rowsPerPage) + 1;
    final endRow = totalRows == 0
        ? 0
        : (page * rowsPerPage > totalRows ? totalRows : page * rowsPerPage);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          totalRows == 0
              ? 'No rows to display'
              : 'Showing $startRow-$endRow of $totalRows records',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Wrap(
          spacing: 6,
          children: [
            IconButton(
              onPressed: page > 1 ? () => onPageSelected(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            ...pages.map(
              (value) => FilledButton.tonal(
                onPressed: value == page ? null : () => onPageSelected(value),
                child: Text('$value'),
              ),
            ),
            IconButton(
              onPressed: page < totalPages ? () => onPageSelected(page + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  List<int> _visiblePages(int page, int totalPages) {
    if (totalPages <= 5) {
      return List<int>.generate(totalPages, (index) => index + 1);
    }

    final start = (page - 2).clamp(1, totalPages - 4);
    return List<int>.generate(5, (index) => start + index);
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'success' => AppTheme.accent,
      'failed' => AppTheme.error,
      'skipped' => AppTheme.tertiary,
      _ => AppTheme.info,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        normalized,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.45,
          color: color,
        ),
      ),
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
