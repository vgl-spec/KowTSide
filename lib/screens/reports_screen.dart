import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/dashboard.dart';
import '../models/reporting.dart';
import '../models/student.dart';
import '../providers/live_updates_provider.dart';
import '../providers/reports_provider.dart';
import '../widgets/admin_charts.dart';
import '../widgets/flareline_components.dart';
import '../widgets/page_skeletons.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(wsEventsProvider, (_, next) {
      next.whenData((event) {
        if (shouldInvalidateForWsEvent(event.type)) {
          ref.invalidate(reportsSnapshotProvider);
        }
      });
    });

    final snapshotAsync = ref.watch(reportsSnapshotProvider);
    final snapshot = snapshotAsync.valueOrNull;
    final dashboard = snapshot?.dashboard;
    final students = snapshot?.students;
    final leaderboard = snapshot?.leaderboard;

    final isInitialLoading = snapshot == null && snapshotAsync.isLoading;

    if (isInitialLoading) {
      return const SafeArea(child: ReportsLoadingSkeleton());
    }

    final firstError = snapshotAsync.asError?.error;

    if (firstError != null && snapshot == null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 10),
              Text('Failed to load reports: $firstError'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _refreshAll(ref),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (dashboard == null || students == null || leaderboard == null) {
      return const SafeArea(child: ReportsLoadingSkeleton());
    }

    final supportList = _buildSupportList(students);
    final supportRate = students.isEmpty
        ? 0.0
        : (supportList.length / students.length) * 100;

    final subjectSummaries = _buildSubjectSummaries(dashboard.ageGroupProgress);
    final ageGroupSummaries = _buildGroupSummaries(dashboard.ageGroupProgress);

    final proficiencySegments = _buildProficiencySegments(students);
    final topLeaderboard = leaderboard.take(8).toList();

    final passRateAverage = dashboard.ageGroupProgress.isEmpty
        ? 0.0
        : dashboard.ageGroupProgress
                  .map((item) => item.passRatePct)
                  .reduce((a, b) => a + b) /
              dashboard.ageGroupProgress.length;

    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _refreshAll(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: [
            FlarePageHeader(
              title: 'Teacher Reports',
              subtitle:
                  'Use these analytics to prioritize interventions, identify content gaps, and monitor learner momentum.',
              actions: [
                FilledButton.tonalIcon(
                  onPressed: () => _refreshAll(ref),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _KpiGrid(
              children: [
                FlareMetricTile(
                  label: 'Total Learners',
                  value: '${dashboard.totalStudents}',
                  hint: '${students.length} loaded in this view',
                  icon: Icons.groups_rounded,
                  color: AppTheme.primary,
                ),
                FlareMetricTile(
                  label: 'Total Sessions',
                  value: '${dashboard.totalScores}',
                  hint: _formatSessionsPerStudent(
                    dashboard.totalScores,
                    dashboard.totalStudents,
                  ),
                  icon: Icons.sports_esports_rounded,
                  color: AppTheme.info,
                ),
                FlareMetricTile(
                  label: 'Average Score',
                  value: '${dashboard.averageScore.toStringAsFixed(1)} / 10',
                  hint:
                      'Average pass rate ${passRateAverage.toStringAsFixed(1)}%',
                  icon: Icons.query_stats_rounded,
                  color: AppTheme.success,
                ),
                FlareMetricTile(
                  label: 'Needs Attention',
                  value: '${supportList.length}',
                  hint: '${supportRate.toStringAsFixed(1)}% of learners',
                  icon: Icons.flag_circle_rounded,
                  color: AppTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (width >= 1240)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _section(
                      title: 'Proficiency Distribution',
                      subtitle:
                          'Current learner segmentation by proficiency label from student records.',
                      child: DonutBreakdownChart(
                        segments: proficiencySegments,
                        centerLabel: 'Learners',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _section(
                      title: 'Pass Rate by Subject',
                      subtitle:
                          'Weighted pass-rate percentage per subject based on active students.',
                      child: subjectSummaries.isEmpty
                          ? const FlareEmptyState(
                              message: 'No subject summary data available.',
                            )
                          : SingleBarChart(
                              data: subjectSummaries
                                  .map(
                                    (row) => SimpleBarDatum(
                                      label: row.label,
                                      value: row.passRate,
                                      color: _subjectColor(row.label),
                                    ),
                                  )
                                  .toList(),
                              maxY: 100,
                              percentageScale: true,
                            ),
                    ),
                  ),
                ],
              )
            else ...[
              _section(
                title: 'Proficiency Distribution',
                subtitle:
                    'Current learner segmentation by proficiency label from student records.',
                child: DonutBreakdownChart(
                  segments: proficiencySegments,
                  centerLabel: 'Learners',
                ),
              ),
              const SizedBox(height: 14),
              _section(
                title: 'Pass Rate by Subject',
                subtitle:
                    'Weighted pass-rate percentage per subject based on active students.',
                child: subjectSummaries.isEmpty
                    ? const FlareEmptyState(
                        message: 'No subject summary data available.',
                      )
                    : SingleBarChart(
                        data: subjectSummaries
                            .map(
                              (row) => SimpleBarDatum(
                                label: row.label,
                                value: row.passRate,
                                color: _subjectColor(row.label),
                              ),
                            )
                            .toList(),
                        maxY: 100,
                        percentageScale: true,
                      ),
              ),
            ],
            const SizedBox(height: 14),
            _section(
              title: 'Age Group Performance Balance',
              subtitle:
                  'Comparison of pass rate and score index (average score x 10) by age group.',
              child: ageGroupSummaries.isEmpty
                  ? const FlareEmptyState(
                      message: 'No age-group performance data available.',
                    )
                  : DualMetricBarChart(
                      data: ageGroupSummaries
                          .map(
                            (row) => DualBarDatum(
                              label: row.label.contains('Punla')
                                  ? 'Punla'
                                  : 'Binhi',
                              leftValue: row.passRate,
                              rightValue: row.avgScore * 10,
                            ),
                          )
                          .toList(),
                      leftLegend: 'Pass rate %',
                      rightLegend: 'Score index (x10)',
                      maxY: 100,
                    ),
            ),
            const SizedBox(height: 14),
            if (width >= 1240)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _section(
                      title: 'Top Learners by Score',
                      subtitle:
                          'Leaderboard snapshot (top 8) by cumulative score from existing report endpoint.',
                      child: topLeaderboard.isEmpty
                          ? const FlareEmptyState(
                              message: 'No leaderboard entries available.',
                            )
                          : SingleBarChart(
                              data: topLeaderboard
                                  .map(
                                    (entry) => SimpleBarDatum(
                                      label: entry.nickname,
                                      value: entry.totalScore,
                                      color: AppTheme.primary,
                                    ),
                                  )
                                  .toList(),
                              maxY: _leaderboardMax(topLeaderboard),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _section(
                      title: 'Priority Support Queue',
                      subtitle:
                          'Learners prioritized by proficiency, average score, and participation intensity.',
                      child: supportList.isEmpty
                          ? const FlareEmptyState(
                              message: 'No students are currently flagged.',
                            )
                          : Column(
                              children: supportList.take(8).map((item) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: _priorityColor(
                                      item.priority,
                                    ).withValues(alpha: 0.16),
                                    child: Text(
                                      item.student.nickname.isEmpty
                                          ? '?'
                                          : item.student.nickname
                                                .substring(0, 1)
                                                .toUpperCase(),
                                      style: TextStyle(
                                        color: _priorityColor(item.priority),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  title: Text(item.student.fullName),
                                  subtitle: Text(
                                    '${item.student.gradelvl} • ${item.reason}',
                                  ),
                                  trailing: FlarePill(
                                    label: item.priority,
                                    color: _priorityColor(item.priority),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                ],
              )
            else ...[
              _section(
                title: 'Top Learners by Score',
                subtitle:
                    'Leaderboard snapshot (top 8) by cumulative score from existing report endpoint.',
                child: topLeaderboard.isEmpty
                    ? const FlareEmptyState(
                        message: 'No leaderboard entries available.',
                      )
                    : SingleBarChart(
                        data: topLeaderboard
                            .map(
                              (entry) => SimpleBarDatum(
                                label: entry.nickname,
                                value: entry.totalScore,
                                color: AppTheme.primary,
                              ),
                            )
                            .toList(),
                        maxY: _leaderboardMax(topLeaderboard),
                      ),
              ),
              const SizedBox(height: 14),
              _section(
                title: 'Priority Support Queue',
                subtitle:
                    'Learners prioritized by proficiency, average score, and participation intensity.',
                child: supportList.isEmpty
                    ? const FlareEmptyState(
                        message: 'No students are currently flagged.',
                      )
                    : Column(
                        children: supportList.take(8).map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: _priorityColor(
                                item.priority,
                              ).withValues(alpha: 0.16),
                              child: Text(
                                item.student.nickname.isEmpty
                                    ? '?'
                                    : item.student.nickname
                                          .substring(0, 1)
                                          .toUpperCase(),
                                style: TextStyle(
                                  color: _priorityColor(item.priority),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(item.student.fullName),
                            subtitle: Text(
                              '${item.student.gradelvl} • ${item.reason}',
                            ),
                            trailing: FlarePill(
                              label: item.priority,
                              color: _priorityColor(item.priority),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
            const SizedBox(height: 14),
            _section(
              title: 'Leaderboard Details',
              subtitle:
                  'Detailed ranking table from backend or mock report data for verification and mentoring assignments.',
              child: leaderboard.isEmpty
                  ? const FlareEmptyState(
                      message: 'No leaderboard entries available yet.',
                    )
                  : _LeaderboardDetailsTable(entries: leaderboard),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return FlareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlareSectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  static Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(reportsSnapshotProvider);
    await ref.read(reportsSnapshotProvider.future);
  }
}

class _RankDot extends StatelessWidget {
  final int rank;

  const _RankDot({required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = rank == 1
        ? AppTheme.warning
        : rank == 2
        ? AppTheme.info
        : rank == 3
        ? AppTheme.tertiary
        : AppTheme.surfaceLow;

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LeaderboardDetailsTable extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _LeaderboardDetailsTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    final table = Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.22),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('Rank')), 
              Expanded(flex: 2, child: Text('Nickname')),
              Expanded(flex: 3, child: Text('Full Name')),
              Expanded(flex: 2, child: Text('Group')),
              Expanded(flex: 2, child: Text('Total Score')),
              Expanded(flex: 1, child: Text('Sessions')),
            ],
          ),
        ),
        ...entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      _RankDot(rank: entry.rank),
                      const SizedBox(width: 8),
                      Text('${entry.rank}'),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.nickname,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(flex: 3, child: Text(entry.fullName)),
                Expanded(flex: 2, child: Text(entry.gradelvl)),
                Expanded(
                  flex: 2,
                  child: Text(entry.totalScore.toStringAsFixed(1)),
                ),
                Expanded(flex: 1, child: Text('${entry.sessions}')),
              ],
            ),
          );
        }),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        if (isNarrow) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: 900, child: table),
          );
        }
        return table;
      },
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final List<Widget> children;

  const _KpiGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1280
            ? 4
            : width >= 860
            ? 2
            : 1;

        final itemWidth = (width - (12 * (columns - 1))) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _StudentSupportItem {
  final Student student;
  final String priority;
  final String reason;

  const _StudentSupportItem({
    required this.student,
    required this.priority,
    required this.reason,
  });
}

class _PerformanceSummary {
  final String label;
  final int activeStudents;
  final double avgScore;
  final double passRate;

  const _PerformanceSummary({
    required this.label,
    required this.activeStudents,
    required this.avgScore,
    required this.passRate,
  });
}

List<_StudentSupportItem> _buildSupportList(List<Student> students) {
  final list = students
      .where((student) {
        final proficiency = student.proficiency.toLowerCase();
        return proficiency.contains('needs support') ||
            student.avgScore < 7.0 ||
            student.totalSessions < 8;
      })
      .map((student) {
        final reasons = <String>[];
        final proficiency = student.proficiency.toLowerCase();

        if (proficiency.contains('needs support')) {
          reasons.add('Proficiency tag');
        }
        if (student.avgScore < 7.0) {
          reasons.add('Avg < 7.0');
        }
        if (student.totalSessions < 8) {
          reasons.add('Low sessions');
        }

        final priority = _computePriority(student, reasons);
        return _StudentSupportItem(
          student: student,
          priority: priority,
          reason: reasons.join(', '),
        );
      })
      .toList();

  list.sort((a, b) {
    final prioritySort = _priorityWeight(
      a.priority,
    ).compareTo(_priorityWeight(b.priority));
    if (prioritySort != 0) return prioritySort;

    final avgSort = a.student.avgScore.compareTo(b.student.avgScore);
    if (avgSort != 0) return avgSort;

    return a.student.totalSessions.compareTo(b.student.totalSessions);
  });

  return list;
}

String _computePriority(Student student, List<String> reasons) {
  final hasNeedsSupport = student.proficiency.toLowerCase().contains(
    'needs support',
  );
  final highRisk = hasNeedsSupport || student.avgScore < 6.0;

  if (highRisk) return 'High';
  if (student.avgScore < 7.0 || reasons.length > 1) return 'Medium';
  return 'Low';
}

Color _priorityColor(String priority) {
  switch (priority) {
    case 'High':
      return AppTheme.error;
    case 'Medium':
      return AppTheme.warning;
    default:
      return AppTheme.info;
  }
}

int _priorityWeight(String priority) {
  switch (priority) {
    case 'High':
      return 0;
    case 'Medium':
      return 1;
    default:
      return 2;
  }
}

Color _subjectColor(String subject) {
  switch (subject.toLowerCase()) {
    case 'mathematics':
      return AppTheme.primary;
    case 'science':
      return AppTheme.success;
    case 'filipino':
      return AppTheme.tertiary;
    case 'english':
      return AppTheme.info;
    default:
      return AppTheme.accent;
  }
}

String _formatSessionsPerStudent(int totalSessions, int totalStudents) {
  if (totalStudents <= 0) return 'No active students';
  final average = totalSessions / totalStudents;
  return '${average.toStringAsFixed(1)} sessions per learner';
}

List<ChartSegment> _buildProficiencySegments(List<Student> students) {
  final needsSupport = students
      .where((student) => student.proficiency == 'Needs support')
      .length;
  final onTrack = students
      .where((student) => student.proficiency == 'On track')
      .length;
  final excelling = students
      .where((student) => student.proficiency == 'Excelling')
      .length;

  return [
    ChartSegment(
      label: 'Needs support',
      value: needsSupport.toDouble(),
      color: AppTheme.error,
    ),
    ChartSegment(
      label: 'On track',
      value: onTrack.toDouble(),
      color: AppTheme.primary,
    ),
    ChartSegment(
      label: 'Excelling',
      value: excelling.toDouble(),
      color: AppTheme.success,
    ),
  ];
}

List<_PerformanceSummary> _buildSubjectSummaries(List<AgeGroupProgress> rows) {
  final bySubject = <String, List<AgeGroupProgress>>{};
  for (final row in rows) {
    bySubject.putIfAbsent(row.subject, () => <AgeGroupProgress>[]).add(row);
  }

  final summaries = bySubject.entries.map((entry) {
    final values = entry.value;
    final totalStudents = values.fold<int>(
      0,
      (sum, row) => sum + row.activeStudents,
    );

    final avgScore = _weightedAverage(
      values: values.map((row) => row.avgScore).toList(),
      weights: values.map((row) => row.activeStudents.toDouble()).toList(),
    );

    final passRate = _weightedAverage(
      values: values.map((row) => row.passRatePct).toList(),
      weights: values.map((row) => row.activeStudents.toDouble()).toList(),
    );

    return _PerformanceSummary(
      label: entry.key,
      activeStudents: totalStudents,
      avgScore: avgScore,
      passRate: passRate,
    );
  }).toList();

  summaries.sort((a, b) => b.passRate.compareTo(a.passRate));
  return summaries;
}

List<_PerformanceSummary> _buildGroupSummaries(List<AgeGroupProgress> rows) {
  final byGroup = <String, List<AgeGroupProgress>>{};
  for (final row in rows) {
    byGroup.putIfAbsent(row.gradelvl, () => <AgeGroupProgress>[]).add(row);
  }

  final summaries = byGroup.entries.map((entry) {
    final values = entry.value;
    final totalStudents = values.fold<int>(
      0,
      (sum, row) => sum + row.activeStudents,
    );

    final avgScore = _weightedAverage(
      values: values.map((row) => row.avgScore).toList(),
      weights: values.map((row) => row.activeStudents.toDouble()).toList(),
    );

    final passRate = _weightedAverage(
      values: values.map((row) => row.passRatePct).toList(),
      weights: values.map((row) => row.activeStudents.toDouble()).toList(),
    );

    return _PerformanceSummary(
      label: entry.key,
      activeStudents: totalStudents,
      avgScore: avgScore,
      passRate: passRate,
    );
  }).toList();

  summaries.sort((a, b) => b.passRate.compareTo(a.passRate));
  return summaries;
}

double _weightedAverage({
  required List<double> values,
  required List<double> weights,
}) {
  if (values.isEmpty || weights.isEmpty || values.length != weights.length) {
    return 0;
  }

  final totalWeight = weights.reduce((a, b) => a + b);
  if (totalWeight <= 0) {
    return values.reduce((a, b) => a + b) / values.length;
  }

  var weightedSum = 0.0;
  for (var index = 0; index < values.length; index++) {
    weightedSum += values[index] * weights[index];
  }

  return weightedSum / totalWeight;
}

double _leaderboardMax(List<LeaderboardEntry> rows) {
  if (rows.isEmpty) return 100;
  final maxScore = rows
      .map((row) => row.totalScore)
      .reduce((a, b) => a > b ? a : b);

  return (maxScore + 10).clamp(20, 1000).toDouble();
}
