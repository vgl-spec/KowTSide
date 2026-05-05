import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/score_utils.dart';
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
  final String? focusSection;

  const ReportsScreen({super.key, this.focusSection});

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

    if (snapshot == null && snapshotAsync.isLoading) {
      return const SafeArea(child: ReportsLoadingSkeleton());
    }

    final error = snapshotAsync.asError?.error;
    if (error != null && snapshot == null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 10),
              Text('Failed to load reports: $error'),
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

    final dashboard = snapshot?.dashboard;
    final students = snapshot?.students;
    final leaderboard = snapshot?.leaderboard;
    if (dashboard == null || students == null || leaderboard == null) {
      return const SafeArea(child: ReportsLoadingSkeleton());
    }

    final supportList = _buildSupportList(students);
    final supportRate = students.isEmpty
        ? 0.0
        : (supportList.length / students.length) * 100;
    final topLeaderboard = leaderboard.take(8).toList();
    final proficiencySegments = _buildProficiencySegments(students);
    final subjectSummaries = _buildSubjectSummaries(
      dashboard.ageGroupProgress,
      dashboard,
    );
    final ageGroupSummaries = _buildGroupSummaries(
      dashboard.ageGroupProgress,
      dashboard,
    );

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
                  value: '${dashboard.averageScore.toStringAsFixed(1)} / 5',
                  hint: 'Overall classroom performance on the 5-point scale',
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
            FlareSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FlareSectionTitle(
                    title: 'Proficiency Distribution',
                    subtitle:
                        'Current learner segmentation by proficiency label.',
                  ),
                  const SizedBox(height: 12),
                  DonutBreakdownChart(
                    segments: proficiencySegments,
                    centerLabel: 'Learners',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FlareSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FlareSectionTitle(
                    title: 'Pass Rate by Subject',
                    subtitle:
                        'Weighted pass-rate percentage per subject based on active students.',
                  ),
                  const SizedBox(height: 12),
                  subjectSummaries.isEmpty
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
                ],
              ),
            ),
            const SizedBox(height: 14),
            FlareSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FlareSectionTitle(
                    title: 'Age Group Performance Balance',
                    subtitle:
                        'Comparison of pass rate and average score on aligned 5-point classroom scales by age group.',
                  ),
                  const SizedBox(height: 12),
                  ageGroupSummaries.isEmpty
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
                                  leftValue: row.passRate / 20,
                                  rightValue: row.avgScore,
                                ),
                              )
                              .toList(),
                          leftLegend: 'Pass rate / 5',
                          rightLegend: 'Average score / 5',
                          maxY: kFivePointScoreMax,
                        ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FlareSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FlareSectionTitle(
                    title: 'Top Learners by Score',
                    subtitle: 'Leaderboard snapshot (top 8).',
                  ),
                  const SizedBox(height: 12),
                  topLeaderboard.isEmpty
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
                ],
              ),
            ),
            const SizedBox(height: 14),
            _PrioritySupportQueueCard(items: supportList),
            const SizedBox(height: 14),
            _LeaderboardDetailsCard(entries: leaderboard),
          ],
        ),
      ),
    );
  }

  static Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(reportsSnapshotProvider);
    await ref.read(reportsSnapshotProvider.future);
  }
}

class _PrioritySupportQueueCard extends StatelessWidget {
  final List<_StudentSupportItem> items;
  const _PrioritySupportQueueCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return FlareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlareSectionTitle(
            title: 'Priority Support Queue',
            subtitle:
                'Paginated and scrollable queue. Displays up to 100 learners per page for faster rendering.',
          ),
          const SizedBox(height: 12),
          _PrioritySupportQueue(items: items),
        ],
      ),
    );
  }
}

class _PrioritySupportQueue extends StatefulWidget {
  final List<_StudentSupportItem> items;
  const _PrioritySupportQueue({required this.items});

  @override
  State<_PrioritySupportQueue> createState() => _PrioritySupportQueueState();
}

class _PrioritySupportQueueState extends State<_PrioritySupportQueue> {
  static const int _pageSize = 100;
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const FlareEmptyState(
        message: 'No students are currently flagged.',
      );
    }

    final total = widget.items.length;
    final totalPages = ((total + _pageSize - 1) ~/ _pageSize).clamp(1, 1000000);
    final page = _page > totalPages ? totalPages : _page;
    if (_page != page) _page = page;

    final start = (page - 1) * _pageSize;
    final end = (start + _pageSize > total) ? total : start + _pageSize;
    final rows = widget.items.sublist(start, end);

    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final item = rows[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _priorityColor(
                    item.priority,
                  ).withValues(alpha: 0.16),
                  child: Text(
                    item.student.nickname.isEmpty
                        ? '?'
                        : item.student.nickname.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: _priorityColor(item.priority),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(item.student.fullName),
                subtitle: Text('${item.student.gradelvl} • ${item.reason}'),
                trailing: FlarePill(
                  label: item.priority,
                  color: _priorityColor(item.priority),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _Pager(
          page: page,
          totalPages: totalPages,
          totalRows: total,
          pageSize: _pageSize,
          onPageSelected: (next) => setState(() => _page = next),
        ),
      ],
    );
  }
}

class _LeaderboardDetailsCard extends StatefulWidget {
  final List<LeaderboardEntry> entries;
  const _LeaderboardDetailsCard({required this.entries});

  @override
  State<_LeaderboardDetailsCard> createState() =>
      _LeaderboardDetailsCardState();
}

class _LeaderboardDetailsCardState extends State<_LeaderboardDetailsCard> {
  static const int _pageSize = 100;
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return const FlareSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlareSectionTitle(
              title: 'Leaderboard Details',
              subtitle: 'Detailed ranking table with pagination.',
            ),
            SizedBox(height: 12),
            FlareEmptyState(message: 'No leaderboard entries available yet.'),
          ],
        ),
      );
    }

    final total = widget.entries.length;
    final totalPages = ((total + _pageSize - 1) ~/ _pageSize).clamp(1, 1000000);
    final page = _page > totalPages ? totalPages : _page;
    if (_page != page) _page = page;
    final start = (page - 1) * _pageSize;
    final end = (start + _pageSize > total) ? total : start + _pageSize;
    final rows = widget.entries.sublist(start, end);

    return FlareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlareSectionTitle(
            title: 'Leaderboard Details',
            subtitle:
                'Paginated and scrollable table. Loads 100 rows per page in the UI.',
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: SingleChildScrollView(
              child: _LeaderboardDetailsTable(entries: rows),
            ),
          ),
          const SizedBox(height: 10),
          _Pager(
            page: page,
            totalPages: totalPages,
            totalRows: total,
            pageSize: _pageSize,
            onPageSelected: (next) => setState(() => _page = next),
          ),
        ],
      ),
    );
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
        ...entries.map(
          (entry) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
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
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
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

class _Pager extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalRows;
  final int pageSize;
  final ValueChanged<int> onPageSelected;

  const _Pager({
    required this.page,
    required this.totalPages,
    required this.totalRows,
    required this.pageSize,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final start = totalRows == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = totalRows == 0
        ? 0
        : (page * pageSize > totalRows ? totalRows : page * pageSize);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Showing $start-$end of $totalRows'),
        OutlinedButton(
          onPressed: page > 1 ? () => onPageSelected(page - 1) : null,
          child: const Text('Previous'),
        ),
        Text('Page $page of $totalPages'),
        OutlinedButton(
          onPressed: page < totalPages ? () => onPageSelected(page + 1) : null,
          child: const Text('Next'),
        ),
      ],
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
      .where(
        (student) =>
            _hasSupportNeed(student.proficiency) ||
            student.avgScore < kFivePointOnTrackThreshold ||
            student.totalSessions < 8,
      )
      .map((student) {
        final reasons = <String>[];
        final proficiency = student.proficiency.toLowerCase();
        if (_hasSupportNeed(proficiency)) reasons.add('Proficiency tag');
        if (student.avgScore < kFivePointOnTrackThreshold) {
          reasons.add(
            'Avg < ${kFivePointOnTrackThreshold.toStringAsFixed(1)}/5',
          );
        }
        if (student.totalSessions < 8) reasons.add('Low sessions');
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
  final hasNeedsSupport = _hasSupportNeed(student.proficiency);
  final highRisk =
      student.proficiency.trim().toLowerCase() == 'needs significant support' ||
      student.avgScore < kFivePointSupportThreshold;
  if (highRisk) return 'High';
  if (hasNeedsSupport ||
      student.avgScore < kFivePointOnTrackThreshold ||
      reasons.length > 1) {
    return 'Medium';
  }
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

String _formatSessionsPerStudent(int totalSessions, int totalStudents) {
  if (totalStudents <= 0) return 'No active students';
  final average = totalSessions / totalStudents;
  return '${average.toStringAsFixed(1)} sessions per learner';
}

List<ChartSegment> _buildProficiencySegments(List<Student> students) {
  final needsSupport = students.where((student) {
    return _hasSupportNeed(student.proficiency);
  }).length;
  final onTrack = students
      .where(
        (student) => student.proficiency.trim().toLowerCase() == 'on track',
      )
      .length;
  final excelling = students
      .where(
        (student) => student.proficiency.trim().toLowerCase() == 'excelling',
      )
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

bool _hasSupportNeed(String proficiency) {
  final normalized = proficiency.trim().toLowerCase();
  return (normalized.contains('needs') && normalized.contains('support')) ||
      normalized.contains('at risk');
}

List<_PerformanceSummary> _buildSubjectSummaries(
  List<AgeGroupProgress> rows,
  DashboardData dashboard,
) {
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
  if (summaries.isNotEmpty) {
    return summaries;
  }
  if (dashboard.totalStudents <= 0 && dashboard.totalScores <= 0) {
    return summaries;
  }
  return [
    _PerformanceSummary(
      label: 'Overall',
      activeStudents: dashboard.totalStudents,
      avgScore: dashboard.averageScore,
      passRate: dashboard.passRatePct,
    ),
  ];
}

List<_PerformanceSummary> _buildGroupSummaries(
  List<AgeGroupProgress> rows,
  DashboardData dashboard,
) {
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
  if (summaries.isNotEmpty) {
    return summaries;
  }
  if (dashboard.totalStudents <= 0 && dashboard.totalScores <= 0) {
    return summaries;
  }
  return [
    _PerformanceSummary(
      label: 'All Learners',
      activeStudents: dashboard.totalStudents,
      avgScore: dashboard.averageScore,
      passRate: dashboard.passRatePct,
    ),
  ];
}

double _weightedAverage({
  required List<double> values,
  required List<double> weights,
}) {
  if (values.isEmpty || weights.isEmpty || values.length != weights.length) {
    return 0;
  }
  final totalWeight = weights.reduce((a, b) => a + b);
  if (totalWeight <= 0) return values.reduce((a, b) => a + b) / values.length;
  var weightedSum = 0.0;
  for (var i = 0; i < values.length; i++) {
    weightedSum += values[i] * weights[i];
  }
  return weightedSum / totalWeight;
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

double _leaderboardMax(List<LeaderboardEntry> rows) {
  if (rows.isEmpty) return 100;
  final maxScore = rows
      .map((row) => row.totalScore)
      .reduce((a, b) => a > b ? a : b);
  return (maxScore + 10).clamp(20, 1000).toDouble();
}
