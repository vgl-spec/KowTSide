import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/score_utils.dart';
import '../core/theme.dart';
import '../models/dashboard.dart';
import '../providers/dashboard_provider.dart';
import '../providers/live_updates_provider.dart';
import '../widgets/admin_charts.dart';
import '../widgets/flareline_components.dart';
import '../widgets/page_skeletons.dart';
import '../widgets/pool_health_matrix.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(wsEventsProvider, (_, next) {
      next.whenData((event) {
        if (shouldInvalidateForWsEvent(event.type)) {
          ref.invalidate(dashboardProvider);
        }
      });
    });

    final dashboardAsync = ref.watch(dashboardProvider);

    return SafeArea(
      child: dashboardAsync.when(
        loading: () => const DashboardLoadingSkeleton(),
        error: (error, _) => _ErrorState(
          message: 'Failed to load the teacher dashboard: $error',
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) => _DashboardView(
          data: data,
          onRefresh: () => ref.invalidate(dashboardProvider),
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final DashboardData data;
  final VoidCallback onRefresh;

  const _DashboardView({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scoreBySubject = _buildSubjectRows(data);
    final scoreByGroup = _buildAgeGroupRows(data);
    final averagePassRate = data.ageGroupProgress.isEmpty
        ? data.passRatePct
        : data.ageGroupProgress
                  .map((entry) => entry.passRatePct)
                  .reduce((a, b) => a + b) /
              data.ageGroupProgress.length;

    final criticalPools =
        data.poolHealth.where((entry) => entry.questionCount < 5).toList()
          ..sort((a, b) => a.questionCount.compareTo(b.questionCount));

    final lowPools = data.poolHealth
        .where((entry) => entry.questionCount >= 5 && entry.questionCount < 8)
        .length;
    final healthyPools =
        data.poolHealth.length - criticalPools.length - lowPools;

    final poolSegments = <ChartSegment>[
      ChartSegment(
        label: 'Healthy',
        value: healthyPools.toDouble(),
        color: AppTheme.success,
      ),
      ChartSegment(
        label: 'Low',
        value: lowPools.toDouble(),
        color: AppTheme.warning,
      ),
      ChartSegment(
        label: 'Critical',
        value: criticalPools.length.toDouble(),
        color: AppTheme.error,
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        children: [
          FlarePageHeader(
            title: 'Teacher Dashboard',
            subtitle:
                'A classroom-first overview focused on learner outcomes, question pool health, and immediate teaching priorities.',
            actions: [
              FilledButton.tonalIcon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _KpiGrid(
            children: [
              FlareMetricTile(
                label: 'Registered Learners',
                value: '${data.totalStudents}',
                hint: 'Students synced from learning devices',
                icon: Icons.groups_rounded,
                color: AppTheme.primary,
                onTap: () => context.go('/students'),
                actionLabel: 'Open learner roster',
              ),
              FlareMetricTile(
                label: 'Quiz Attempts',
                value: '${data.totalScores}',
                hint: 'Total recorded classroom sessions',
                icon: Icons.fact_check_rounded,
                color: AppTheme.info,
                onTap: () => context.go('/reports?focus=sessions'),
                actionLabel: 'Open session reports',
              ),
              FlareMetricTile(
                label: 'Average Score',
                value: '${data.averageScore.toStringAsFixed(1)} / 5',
                hint:
                    'Weighted mean across synced attempts on the 5-point scale',
                icon: Icons.auto_graph_rounded,
                color: AppTheme.success,
                onTap: () => context.go('/reports?focus=score'),
                actionLabel: 'Open score trends',
              ),
              FlareMetricTile(
                label: 'Average Pass Rate',
                value: '${averagePassRate.toStringAsFixed(1)}%',
                hint: 'Across all age-group/subject pools',
                icon: Icons.check_circle_outline_rounded,
                color: AppTheme.tertiary,
                onTap: () => context.go('/reports?focus=pass-rate'),
                actionLabel: 'Open pass-rate charts',
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (width >= 1240)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _chartSection(
                    context,
                    title: 'Subject Score Profile',
                    subtitle:
                        'Average learner score per subject on the 5-point scale, aggregated from age-group records.',
                    child: scoreBySubject.isEmpty
                        ? const FlareEmptyState(
                            message: 'No performance data available yet.',
                          )
                        : SingleBarChart(
                            data: scoreBySubject
                                .map(
                                  (row) => SimpleBarDatum(
                                    label: row.label,
                                    value: row.averageScore,
                                    color: _subjectColor(row.label),
                                  ),
                                )
                                .toList(),
                            maxY: kFivePointScoreMax,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _chartSection(
                    context,
                    title: 'Pass Rate by Age Group',
                    subtitle:
                        'Average pass-rate percentage per learner group for rapid instructional targeting.',
                    child: scoreByGroup.isEmpty
                        ? const FlareEmptyState(
                            message: 'No age-group data available yet.',
                          )
                        : SingleBarChart(
                            data: scoreByGroup
                                .map(
                                  (row) => SimpleBarDatum(
                                    label: row.label,
                                    value: row.passRate,
                                    color:
                                        row.label.toLowerCase().contains(
                                          'punla',
                                        )
                                        ? AppTheme.primary
                                        : AppTheme.tertiary,
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
            _chartSection(
              context,
              title: 'Subject Score Profile',
              subtitle:
                  'Average learner score per subject on the 5-point scale, aggregated from age-group records.',
              child: scoreBySubject.isEmpty
                  ? const FlareEmptyState(
                      message: 'No performance data available yet.',
                    )
                  : SingleBarChart(
                      data: scoreBySubject
                          .map(
                            (row) => SimpleBarDatum(
                              label: row.label,
                              value: row.averageScore,
                              color: _subjectColor(row.label),
                            ),
                          )
                          .toList(),
                      maxY: kFivePointScoreMax,
                    ),
            ),
            const SizedBox(height: 14),
            _chartSection(
              context,
              title: 'Pass Rate by Age Group',
              subtitle:
                  'Average pass-rate percentage per learner group for rapid instructional targeting.',
              child: scoreByGroup.isEmpty
                  ? const FlareEmptyState(
                      message: 'No age-group data available yet.',
                    )
                  : SingleBarChart(
                      data: scoreByGroup
                          .map(
                            (row) => SimpleBarDatum(
                              label: row.label,
                              value: row.passRate,
                              color: row.label.toLowerCase().contains('punla')
                                  ? AppTheme.primary
                                  : AppTheme.tertiary,
                            ),
                          )
                          .toList(),
                      maxY: 100,
                      percentageScale: true,
                    ),
            ),
          ],
          const SizedBox(height: 14),
          if (width >= 1240)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _chartSection(
                    context,
                    title: 'Question Pool Distribution',
                    subtitle:
                        'Balance across Healthy, Low, and Critical pools. Keep each pool at five or more active items.',
                    child: data.poolHealth.isEmpty
                        ? const FlareEmptyState(
                            message: 'No pool data available yet.',
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DonutBreakdownChart(
                                segments: poolSegments,
                                centerLabel: 'Pools',
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Recommendation: keep at least 9-10 questions for each subject and difficulty level.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _chartSection(
                    context,
                    title: 'Pool Matrix',
                    subtitle:
                        'Detailed health view by grade group, subject, and difficulty.',
                    child: data.poolHealth.isEmpty
                        ? const FlareEmptyState(
                            message: 'No pool health data available yet.',
                          )
                        : PoolHealthMatrix(entries: data.poolHealth),
                  ),
                ),
              ],
            )
          else ...[
            _chartSection(
              context,
              title: 'Question Pool Distribution',
              subtitle:
                  'Balance across Healthy, Low, and Critical pools. Keep each pool at five or more active items.',
              child: data.poolHealth.isEmpty
                  ? const FlareEmptyState(
                      message: 'No pool data available yet.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DonutBreakdownChart(
                          segments: poolSegments,
                          centerLabel: 'Pools',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Recommendation: keep at least 9-10 questions for each subject and difficulty level.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            _chartSection(
              context,
              title: 'Pool Matrix',
              subtitle:
                  'Detailed health view by grade group, subject, and difficulty.',
              child: data.poolHealth.isEmpty
                  ? const FlareEmptyState(
                      message: 'No pool health data available yet.',
                    )
                  : PoolHealthMatrix(entries: data.poolHealth),
            ),
          ],
          const SizedBox(height: 14),
          FlareSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FlareSectionTitle(
                  title: 'Priority Pools to Expand',
                  subtitle:
                      'These pools have fewer than five active questions and should be prioritized to reduce repetition in learner sessions.',
                ),
                const SizedBox(height: 10),
                if (criticalPools.isEmpty)
                  const FlareEmptyState(
                    message:
                        'All pools meet the minimum target. Continue balancing by adding variety in underused subjects.',
                  )
                else
                  ...criticalPools.take(8).map((entry) {
                    final missing = 5 - entry.questionCount;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.error,
                        ),
                      ),
                      title: Text(
                        '${entry.gradelvl} • ${entry.subject} • ${entry.difficulty}',
                      ),
                      subtitle: Text(
                        missing > 0
                            ? 'Add at least $missing item${missing == 1 ? '' : 's'} to reach the minimum pool size.'
                            : 'At minimum threshold.',
                      ),
                      trailing: FlarePill(
                        label: '${entry.questionCount} items',
                        color: AppTheme.error,
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartSection(
    BuildContext context, {
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

  List<_PerformanceRow> _buildSubjectRows(DashboardData data) {
    final rows = _groupBySubject(data.ageGroupProgress);
    if (rows.isNotEmpty) {
      return rows;
    }
    if (data.totalScores <= 0 && data.totalStudents <= 0) {
      return const [];
    }
    return [
      _PerformanceRow(
        label: 'Overall',
        activeStudents: data.totalStudents,
        averageScore: data.averageScore,
        passRate: data.passRatePct,
      ),
    ];
  }

  List<_PerformanceRow> _buildAgeGroupRows(DashboardData data) {
    final rows = _groupByAgeGroup(data.ageGroupProgress);
    if (rows.isNotEmpty) {
      return rows;
    }
    if (data.totalScores <= 0 && data.totalStudents <= 0) {
      return const [];
    }
    return [
      _PerformanceRow(
        label: 'All Learners',
        activeStudents: data.totalStudents,
        averageScore: data.averageScore,
        passRate: data.passRatePct,
      ),
    ];
  }

  List<_PerformanceRow> _groupBySubject(List<AgeGroupProgress> source) {
    final grouped = <String, List<AgeGroupProgress>>{};

    for (final row in source) {
      grouped.putIfAbsent(row.subject, () => <AgeGroupProgress>[]).add(row);
    }

    final rows = grouped.entries.map((entry) {
      final students = entry.value.fold<int>(
        0,
        (sum, row) => sum + row.activeStudents,
      );
      final score = _weightedAverage(
        values: entry.value.map((row) => row.avgScore).toList(),
        weights: entry.value
            .map((row) => row.activeStudents.toDouble())
            .toList(),
      );
      final passRate = _weightedAverage(
        values: entry.value.map((row) => row.passRatePct).toList(),
        weights: entry.value
            .map((row) => row.activeStudents.toDouble())
            .toList(),
      );

      return _PerformanceRow(
        label: entry.key,
        activeStudents: students,
        averageScore: score,
        passRate: passRate,
      );
    }).toList();

    rows.sort((a, b) => b.averageScore.compareTo(a.averageScore));
    return rows;
  }

  List<_PerformanceRow> _groupByAgeGroup(List<AgeGroupProgress> source) {
    final grouped = <String, List<AgeGroupProgress>>{};

    for (final row in source) {
      grouped.putIfAbsent(row.gradelvl, () => <AgeGroupProgress>[]).add(row);
    }

    final rows = grouped.entries.map((entry) {
      final students = entry.value.fold<int>(
        0,
        (sum, row) => sum + row.activeStudents,
      );
      final score = _weightedAverage(
        values: entry.value.map((row) => row.avgScore).toList(),
        weights: entry.value
            .map((row) => row.activeStudents.toDouble())
            .toList(),
      );
      final passRate = _weightedAverage(
        values: entry.value.map((row) => row.passRatePct).toList(),
        weights: entry.value
            .map((row) => row.activeStudents.toDouble())
            .toList(),
      );

      return _PerformanceRow(
        label: entry.key,
        activeStudents: students,
        averageScore: score,
        passRate: passRate,
      );
    }).toList();

    rows.sort((a, b) => b.passRate.compareTo(a.passRate));
    return rows;
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
}

class _PerformanceRow {
  final String label;
  final int activeStudents;
  final double averageScore;
  final double passRate;

  const _PerformanceRow({
    required this.label,
    required this.activeStudents,
    required this.averageScore,
    required this.passRate,
  });
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
