import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/dashboard.dart';

class PoolHealthMatrix extends StatelessWidget {
  final List<PoolHealthEntry> entries;

  const PoolHealthMatrix({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<PoolHealthEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.gradelvl, () => <PoolHealthEntry>[]).add(entry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _LegendChip(
              label: 'Healthy (8+)',
              color: AppTheme.accent,
            ),
            _LegendChip(
              label: 'Low (5-7)',
              color: AppTheme.tertiary,
            ),
            _LegendChip(
              label: 'Critical (0-4)',
              color: AppTheme.error,
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final group in grouped.entries) ...[
          Text(
            group.key,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.28),
              ),
            ),
            child: _PoolGroupTable(entries: group.value),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _PoolGroupTable extends StatelessWidget {
  final List<PoolHealthEntry> entries;

  const _PoolGroupTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    final rows = _toRows(entries);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FlexColumnWidth(2.6),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1.1),
          3: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.22),
            ),
            children: const [
              _HeaderCell(label: 'Subject', alignStart: true),
              _HeaderCell(label: 'Easy'),
              _HeaderCell(label: 'Average'),
              _HeaderCell(label: 'Hard'),
            ],
          ),
          ...rows.map((row) {
            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
                ),
              ),
              children: [
                _BodyCell(text: row.subject, alignStart: true),
                Center(child: _CountChip(entry: row.easy)),
                Center(child: _CountChip(entry: row.average)),
                Center(child: _CountChip(entry: row.hard)),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<_SubjectPoolRow> _toRows(List<PoolHealthEntry> source) {
    final subjects = <String, Map<String, PoolHealthEntry>>{};
    for (final entry in source) {
      subjects.putIfAbsent(entry.subject, () => <String, PoolHealthEntry>{})[
          entry.difficulty] = entry;
    }

    final rows = subjects.entries
        .map(
          (entry) => _SubjectPoolRow(
            subject: entry.key,
            easy: entry.value['Easy'],
            average: entry.value['Average'],
            hard: entry.value['Hard'],
          ),
        )
        .toList();

    rows.sort((a, b) => a.subject.compareTo(b.subject));
    return rows;
  }
}

class _SubjectPoolRow {
  final String subject;
  final PoolHealthEntry? easy;
  final PoolHealthEntry? average;
  final PoolHealthEntry? hard;

  const _SubjectPoolRow({
    required this.subject,
    required this.easy,
    required this.average,
    required this.hard,
  });
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final bool alignStart;

  const _HeaderCell({required this.label, this.alignStart = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 10, 12, alignStart ? 10 : 10),
      child: Align(
        alignment: alignStart ? Alignment.centerLeft : Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  final bool alignStart;

  const _BodyCell({required this.text, this.alignStart = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Align(
        alignment: alignStart ? Alignment.centerLeft : Alignment.center,
        child: Text(text),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final PoolHealthEntry? entry;

  const _CountChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    final count = entry?.questionCount ?? 0;
    final color = _statusColor(count);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(int count) {
    if (count >= 8) return AppTheme.accent;
    if (count >= 5) return AppTheme.tertiary;
    return AppTheme.error;
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
