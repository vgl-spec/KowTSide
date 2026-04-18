import 'package:flutter/material.dart';
import '../core/theme.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _entityFilter = 'All';
  String _actionFilter = 'All';

  final List<_AuditEntry> _entries = const [
    _AuditEntry(
      timestamp: '2026-04-11 10:05',
      actor: 'kow_admin',
      entity: 'questionTb',
      action: 'UPDATE',
      recordId: 'question_id=2031',
      summary: 'Updated option set for English hard-level question.',
      severity: _AuditSeverity.info,
    ),
    _AuditEntry(
      timestamp: '2026-04-11 09:47',
      actor: 'content.team',
      entity: 'questionTb',
      action: 'INSERT',
      recordId: 'question_id=2035',
      summary: 'Added new Science prompt for Binhi average level.',
      severity: _AuditSeverity.success,
    ),
    _AuditEntry(
      timestamp: '2026-04-11 09:11',
      actor: 'system',
      entity: 'syncLogTb',
      action: 'ERROR',
      recordId: 'sync_id=88911',
      summary: 'Device heartbeat timed out after max retry count.',
      severity: _AuditSeverity.critical,
    ),
    _AuditEntry(
      timestamp: '2026-04-10 17:03',
      actor: 'jeremiah.v',
      entity: 'adminTb',
      action: 'LOGIN',
      recordId: 'admin_id=1',
      summary: 'Administrator session created from web panel.',
      severity: _AuditSeverity.info,
    ),
    _AuditEntry(
      timestamp: '2026-04-10 16:31',
      actor: 'system',
      entity: 'contentVersionTb',
      action: 'VERSION_BUMP',
      recordId: 'version_tag=v43',
      summary: 'Content version bumped after question mutation.',
      severity: _AuditSeverity.success,
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_AuditEntry> get _filtered {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _entries.where((entry) {
      final entityMatch =
          _entityFilter == 'All' || entry.entity == _entityFilter;
      final actionMatch =
          _actionFilter == 'All' || entry.action == _actionFilter;
      if (!entityMatch || !actionMatch) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return entry.actor.toLowerCase().contains(query) ||
          entry.entity.toLowerCase().contains(query) ||
          entry.action.toLowerCase().contains(query) ||
          entry.summary.toLowerCase().contains(query) ||
          entry.recordId.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Audit Log',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 980 ? 280 : 360,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search actor, entity, action...',
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
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _entityFilter,
                    dropdownColor: AppTheme.surface,
                    items:
                        const [
                              'All',
                              'questionTb',
                              'syncLogTb',
                              'adminTb',
                              'contentVersionTb',
                            ]
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text('Entity: $value'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _entityFilter = value);
                      }
                    },
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _actionFilter,
                    dropdownColor: AppTheme.surface,
                    items:
                        const [
                              'All',
                              'INSERT',
                              'UPDATE',
                              'ERROR',
                              'LOGIN',
                              'VERSION_BUMP',
                            ]
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text('Action: $value'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _actionFilter = value);
                      }
                    },
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: MediaQuery.of(context).size.width < 960 ? 1 : 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2,
              children: [
                _AuditMetricCard(
                  title: 'Total Events (24h)',
                  value: '${_entries.length}',
                  color: AppTheme.primary,
                  icon: Icons.receipt_long_rounded,
                ),
                _AuditMetricCard(
                  title: 'Critical Alerts',
                  value:
                      '${_entries.where((e) => e.severity == _AuditSeverity.critical).length}',
                  color: AppTheme.error,
                  icon: Icons.priority_high_rounded,
                ),
                _AuditMetricCard(
                  title: 'Mutation Events',
                  value:
                      '${_entries.where((e) => e.action == 'INSERT' || e.action == 'UPDATE').length}',
                  color: AppTheme.accent,
                  icon: Icons.edit_note_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Immutable Activity Ledger',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Timestamp')),
                          DataColumn(label: Text('Actor')),
                          DataColumn(label: Text('Entity')),
                          DataColumn(label: Text('Action')),
                          DataColumn(label: Text('Record')),
                          DataColumn(label: Text('Summary')),
                          DataColumn(label: Text('Severity')),
                        ],
                        rows: filtered
                            .map(
                              (entry) => DataRow(
                                cells: [
                                  DataCell(Text(entry.timestamp)),
                                  DataCell(Text(entry.actor)),
                                  DataCell(Text(entry.entity)),
                                  DataCell(Text(entry.action)),
                                  DataCell(
                                    Text(
                                      entry.recordId,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 360,
                                      ),
                                      child: Text(
                                        entry.summary,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _SeverityTag(
                                      label: entry.severity.label,
                                      color: entry.severity.color,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Showing ${filtered.length} entries',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _AuditMetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                Icon(icon, color: color, size: 18),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityTag extends StatelessWidget {
  final String label;
  final Color color;

  const _SeverityTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _AuditSeverity {
  info('Info', AppTheme.info),
  success('Success', AppTheme.accent),
  critical('Critical', AppTheme.error);

  final String label;
  final Color color;

  const _AuditSeverity(this.label, this.color);
}

class _AuditEntry {
  final String timestamp;
  final String actor;
  final String entity;
  final String action;
  final String recordId;
  final String summary;
  final _AuditSeverity severity;

  const _AuditEntry({
    required this.timestamp,
    required this.actor,
    required this.entity,
    required this.action,
    required this.recordId,
    required this.summary,
    required this.severity,
  });
}
