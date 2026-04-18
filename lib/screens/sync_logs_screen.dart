import 'package:flutter/material.dart';
import '../core/theme.dart';

class SyncLogsScreen extends StatefulWidget {
  const SyncLogsScreen({super.key});
  @override
  State<SyncLogsScreen> createState() => _SyncLogsScreenState();
}

class _SyncLogsScreenState extends State<SyncLogsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _expandedRows = <String>{};
  String _statusFilter = 'All';

  final List<_SyncLogEntry> _logs = const [
    _SyncLogEntry(
      id: 'KOW-882-XJ9',
      student: 'Alex Johnson',
      eventType: 'QUIZ_SUBMIT',
      receivedAt: '2 mins ago',
      status: _LogStatus.success,
    ),
    _SyncLogEntry(
      id: 'KOW-119-PL2',
      student: 'Sarah Miller',
      eventType: 'APP_HEARTBEAT',
      receivedAt: '5 mins ago',
      status: _LogStatus.failed,
      errorPayload:
          '{\n'
          '  "status": "failed",\n'
          '  "reason": "CONNECTION_TIMED_OUT",\n'
          '  "retry_count": 3,\n'
          '  "endpoint": "/v1/sync/heartbeat",\n'
          '  "latency": "15000ms"\n'
          '}',
    ),
    _SyncLogEntry(
      id: 'KOW-504-AA3',
      student: 'James Chen',
      eventType: 'CACHE_FLUSH',
      receivedAt: '12 mins ago',
      status: _LogStatus.skipped,
    ),
    _SyncLogEntry(
      id: 'KOW-921-MM1',
      student: 'Maria Garcia',
      eventType: 'COURSE_COMPLETE',
      receivedAt: '15 mins ago',
      status: _LogStatus.success,
    ),
    _SyncLogEntry(
      id: 'KOW-703-TR7',
      student: 'Noah Reyes',
      eventType: 'STUDENT_REGISTER',
      receivedAt: '21 mins ago',
      status: _LogStatus.success,
    ),
    _SyncLogEntry(
      id: 'KOW-311-CM8',
      student: 'Lia Santos',
      eventType: 'PROFILE_SYNC',
      receivedAt: '33 mins ago',
      status: _LogStatus.failed,
      errorPayload:
          '{\n'
          '  "status": "failed",\n'
          '  "reason": "TOKEN_EXPIRED",\n'
          '  "retry_count": 1,\n'
          '  "endpoint": "/v1/sync/profile",\n'
          '  "latency": "820ms"\n'
          '}',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_SyncLogEntry> get _filteredLogs {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _logs.where((log) {
      final matchesStatus =
          _statusFilter == 'All' || log.status.label == _statusFilter;
      if (!matchesStatus) {
        return false;
      }
      if (q.isEmpty) {
        return true;
      }
      return log.id.toLowerCase().contains(q) ||
          log.student.toLowerCase().contains(q) ||
          log.eventType.toLowerCase().contains(q);
    }).toList();
  }

  int _countByStatus(_LogStatus status) =>
      _logs.where((log) => log.status == status).length;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 980;
    final successCount = _countByStatus(_LogStatus.success);
    final failedCount = _countByStatus(_LogStatus.failed);
    final skippedCount = _countByStatus(_LogStatus.skipped);
    final successRate = _logs.isEmpty
        ? 0.0
        : (successCount / _logs.length) * 100;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  width: compact ? width - 80 : 320,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search sync batches...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() {}),
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
                _PulseCard(successRate: successRate),
                _MiniStatCard(
                  title: 'Failures',
                  value: '$failedCount',
                  subtitle: 'Critical interruptions',
                  icon: Icons.report_problem_rounded,
                  color: AppTheme.error,
                ),
                _MiniStatCard(
                  title: 'Skipped',
                  value: '$skippedCount',
                  subtitle: 'Duplicate/non-critical',
                  icon: Icons.skip_next_rounded,
                  color: AppTheme.tertiary,
                ),
                _MiniStatCard(
                  title: 'Processed',
                  value: '${_logs.length}',
                  subtitle: 'Last 24 hours',
                  icon: Icons.sync_rounded,
                  color: AppTheme.accent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Transaction Logs',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const _PillChip(label: 'LIVE', color: AppTheme.accent),
                        _PillChip(
                          label: 'FILTER: $_statusFilter',
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
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
                                setState(() => _statusFilter = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (compact)
                    _buildCompactList(context)
                  else
                    _buildDesktopTable(context),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLow,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Showing 1-${_filteredLogs.length.clamp(0, 25)} '
                            'of ${_filteredLogs.length} events',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Wrap(
                          spacing: 4,
                          children: [
                            _PaginationButton('1', active: true),
                            _PaginationButton('2'),
                            _PaginationButton('3'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: compact ? width - 60 : 440,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Engine 4.2.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monitoring 4,209 educational tablets across '
                        '12 barangay regions. Average latency 142ms.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const _MiniMeta(label: 'Uptime', value: '99.998%'),
                const _MiniMeta(label: 'Last Reboot', value: '14d 2h 11m'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    final filtered = _filteredLogs;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          color: AppTheme.surfaceLow,
          child: const Row(
            children: [
              _HeaderCell('Device UUID', flex: 2),
              _HeaderCell('Student', flex: 2),
              _HeaderCell('Event Type', flex: 2),
              _HeaderCell('Received At', flex: 2),
              _HeaderCell('Status', flex: 1, center: true),
              _HeaderCell('Actions', flex: 1, end: true),
            ],
          ),
        ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No sync events match the current filter.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...filtered.take(25).map((log) {
            final expanded = _expandedRows.contains(log.id);
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (expanded) {
                        _expandedRows.remove(log.id);
                      } else {
                        _expandedRows.add(log.id);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.textLowEmphasis.withValues(alpha: 0.16),
                        ),
                      ),
                      color: expanded
                          ? AppTheme.surfaceLow.withValues(alpha: 0.55)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            log.id,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(flex: 2, child: Text(log.student)),
                        Expanded(
                          flex: 2,
                          child: Text(
                            log.eventType,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.textHighEmphasis,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            log.receivedAt,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.center,
                            child: Icon(
                              log.status.icon,
                              color: log.status.color,
                              size: 19,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              expanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (expanded && log.errorPayload != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 400,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Error Payload',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundPrimary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SelectableText(
                                  log.errorPayload!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: AppTheme.textMediumEmphasis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 310,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Troubleshooting Hints',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              const _HintItem(
                                text:
                                    'Check device internet gateway stability.',
                              ),
                              const _HintItem(
                                text: 'Verify authentication token expiration.',
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton(
                                    onPressed: () {},
                                    child: const Text('Retry Sync'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => setState(
                                      () => _expandedRows.remove(log.id),
                                    ),
                                    child: const Text('Dismiss'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildCompactList(BuildContext context) {
    final filtered = _filteredLogs;

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'No sync events match the current filter.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: filtered.take(25).map((log) {
          final expanded = _expandedRows.contains(log.id);
          return Container(
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.textLowEmphasis.withValues(alpha: 0.3),
              ),
            ),
            child: ExpansionTile(
              collapsedIconColor: AppTheme.textMediumEmphasis,
              iconColor: AppTheme.primary,
              onExpansionChanged: (open) {
                setState(() {
                  if (open) {
                    _expandedRows.add(log.id);
                  } else {
                    _expandedRows.remove(log.id);
                  }
                });
              },
              title: Text(
                log.student,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${log.eventType} - ${log.receivedAt}'),
              leading: Icon(log.status.icon, color: log.status.color),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              children: [
                Row(
                  children: [
                    const Text('Device: '),
                    Expanded(
                      child: Text(
                        log.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (log.errorPayload != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      log.errorPayload!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.textMediumEmphasis,
                      ),
                    ),
                  )
                else if (expanded)
                  Text(
                    'No error payload. Transaction completed normally.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  final double successRate;

  const _PulseCard({required this.successRate});

  @override
  Widget build(BuildContext context) {
    final bars = [0.5, 0.75, 0.65, 1.0, 0.88, 0.32, 0.72];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [AppTheme.surfaceHigh, AppTheme.surface.withValues(alpha: 0.92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.textLowEmphasis.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Live Sync Status',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Operational Pulse',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  '${successRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accent,
                  ),
                ),
                Text(
                  'Success Rate (Last 24h)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 110,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: bars.map((height) {
                final isFailureBar = height < 0.4;
                return Container(
                  width: 8,
                  height: 56 * height,
                  decoration: BoxDecoration(
                    color: isFailureBar ? AppTheme.error : AppTheme.accent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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

class _PillChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PillChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
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

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool center;
  final bool end;

  const _HeaderCell(
    this.label, {
    required this.flex,
    this.center = false,
    this.end = false,
  });

  @override
  Widget build(BuildContext context) {
    Alignment alignment = Alignment.centerLeft;
    if (center) {
      alignment = Alignment.center;
    } else if (end) {
      alignment = Alignment.centerRight;
    }

    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HintItem extends StatelessWidget {
  final String text;

  const _HintItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final String text;
  final bool active;

  const _PaginationButton(this.text, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: active
              ? Theme.of(context).colorScheme.onPrimary
              : AppTheme.textMediumEmphasis,
        ),
      ),
    );
  }
}

enum _LogStatus {
  success(Icons.check_circle, AppTheme.accent, 'Success'),
  failed(Icons.error, AppTheme.error, 'Failed'),
  skipped(Icons.skip_next, AppTheme.tertiary, 'Skipped');

  final IconData icon;
  final Color color;
  final String label;

  const _LogStatus(this.icon, this.color, this.label);
}

class _SyncLogEntry {
  final String id;
  final String student;
  final String eventType;
  final String receivedAt;
  final _LogStatus status;
  final String? errorPayload;

  const _SyncLogEntry({
    required this.id,
    required this.student,
    required this.eventType,
    required this.receivedAt,
    required this.status,
    this.errorPayload,
  });
}
