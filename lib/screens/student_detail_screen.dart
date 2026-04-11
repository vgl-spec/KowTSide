import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/students_provider.dart';
import '../models/student.dart';

class StudentDetailScreen extends ConsumerWidget {
  final int studId;
  const StudentDetailScreen({super.key, required this.studId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentDetailProvider(studId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Student #$studId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(studentDetailProvider(studId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text('$e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(studentDetailProvider(studId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detail) => _DetailBody(detail: detail),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final StudentDetail detail;
  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    final s = detail.profile;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      s.nickname.isNotEmpty
                          ? s.nickname[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 28,
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Wrap(
                      spacing: 32,
                      runSpacing: 8,
                      children: [
                        _Info('Nickname', s.nickname),
                        _Info('Full Name', s.fullName),
                        _Info('Age', '${s.age} years'),
                        _Info('Group', s.gradelvl),
                        _Info('Sex', s.sex),
                        _Info('Total Sessions', '${s.totalSessions}'),
                        _Info('Avg Score', s.avgScore.toStringAsFixed(2)),
                        _Info('Proficiency', s.proficiency),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress per subject
          Text('Subject Progress', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: detail.progress.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No progress data yet.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Subject')),
                        DataColumn(label: Text('Group')),
                        DataColumn(label: Text('Highest Level')),
                        DataColumn(label: Text('Time Played')),
                      ],
                      rows: detail.progress.map((p) => DataRow(cells: [
                            DataCell(Text(p.subject)),
                            DataCell(Text(p.gradelvl)),
                            DataCell(Text(p.diffLabel)),
                            DataCell(Text(p.timeLabel)),
                          ])).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Analytics per subject
          Text('Score Analytics', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: detail.analytics.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No analytics data yet.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Subject')),
                        DataColumn(label: Text('Group')),
                        DataColumn(label: Text('Lowest')),
                        DataColumn(label: Text('Average')),
                        DataColumn(label: Text('Highest')),
                        DataColumn(label: Text('Attempts')),
                      ],
                      rows: detail.analytics.map((a) => DataRow(cells: [
                            DataCell(Text(a.subject)),
                            DataCell(Text(a.gradelvl)),
                            DataCell(Text(a.lowestScore.toStringAsFixed(1))),
                            DataCell(Text(a.averageScore.toStringAsFixed(2),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                            DataCell(Text(a.highestScore.toStringAsFixed(1))),
                            DataCell(Text('${a.totalAttempts}')),
                          ])).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Recent scores
          Text('Recent Scores', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: detail.recentScores.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No score records yet.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Subject')),
                        DataColumn(label: Text('Difficulty')),
                        DataColumn(label: Text('Score')),
                        DataColumn(label: Text('Result')),
                        DataColumn(label: Text('Played At')),
                      ],
                      rows: detail.recentScores.map((sc) => DataRow(cells: [
                            DataCell(Text(sc.subject)),
                            DataCell(Text(sc.difficulty)),
                            DataCell(Text(
                                '${sc.score.toStringAsFixed(0)}/10')),
                            DataCell(
                              sc.passed
                                  ? const Chip(
                                      label: Text('Passed'),
                                      backgroundColor: Color(0xFFE8F5E9),
                                      labelStyle:
                                          TextStyle(color: Colors.green),
                                      padding: EdgeInsets.zero,
                                    )
                                  : const Chip(
                                      label: Text('Failed'),
                                      backgroundColor: Color(0xFFFFEBEE),
                                      labelStyle: TextStyle(color: Colors.red),
                                      padding: EdgeInsets.zero,
                                    ),
                            ),
                            DataCell(Text(sc.playedAt)),
                          ])).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      );
}
