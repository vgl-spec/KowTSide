import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/student.dart';
import '../providers/live_updates_provider.dart';
import '../providers/students_provider.dart';
import '../widgets/admin_charts.dart';
import '../widgets/flareline_components.dart';
import '../widgets/page_skeletons.dart';

class StudentDetailScreen extends ConsumerWidget {
  final int studId;

  const StudentDetailScreen({super.key, required this.studId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(wsEventsProvider, (_, next) {
      next.whenData((event) {
        if (shouldInvalidateForWsEvent(event.type)) {
          ref.invalidate(studentDetailProvider(studId));
          ref.invalidate(studentsProvider);
        }
      });
    });

    final detailAsync = ref.watch(studentDetailProvider(studId));

    return SafeArea(
      child: detailAsync.when(
        loading: () => const StudentDetailLoadingSkeleton(),
        error: (error, _) => _ErrorState(
          message: 'Failed to load learner profile: $error',
          onRetry: () => ref.invalidate(studentDetailProvider(studId)),
        ),
        data: (detail) => _DetailBody(
          detail: detail,
          onRefresh: () => ref.invalidate(studentDetailProvider(studId)),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final StudentDetail detail;
  final VoidCallback onRefresh;

  const _DetailBody({required this.detail, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final profile = detail.profile;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1220;
    final contentWidth = width - 48;
    const cardSpacing = 14.0;
    final compactCardWidth = isWide
        ? ((contentWidth - cardSpacing) / 2).clamp(460.0, 620.0).toDouble()
        : contentWidth;
    final alignedCardMinHeight = isWide ? 318.0 : null;
    final analytics = detail.analytics.isNotEmpty
        ? detail.analytics
        : _derivedAnalytics(detail.recentScores);
    final followUps = _teacherFollowUps(detail);
    final recentTrend = detail.recentScores.take(8).toList().reversed.toList();
    final progressSection = _PagedTableCard<SubjectProgress>(
      width: compactCardWidth,
      minHeight: alignedCardMinHeight,
      title: 'Subject Progress',
      subtitle:
          'Highest unlocked difficulty, total time played, and latest play date.',
      items: detail.progress,
      emptyMessage: 'No progress data is available yet.',
      columns: const [
        'Subject',
        'Group',
        'Highest Level',
        'Time Played',
        'Last Played',
      ],
      rowBuilder: (progress) => [
        Text(progress.subject),
        Text(progress.gradelvl),
        Text(progress.diffLabel),
        Text(progress.timeLabel),
        Text(progress.lastPlayedAt),
      ],
    );
    final scorePatternSection = _PagedTableCard<SubjectAnalytics>(
      width: compactCardWidth,
      minHeight: alignedCardMinHeight,
      title: 'Score Pattern',
      subtitle: analytics.isEmpty
          ? 'Backend analytics are not available yet for this learner.'
          : 'Performance summary grouped by subject.',
      items: analytics,
      emptyMessage: 'No score analytics or recent scores are available yet.',
      columns: const [
        'Subject',
        'Group',
        'Lowest',
        'Average',
        'Highest',
        'Attempts',
      ],
      rowBuilder: (analyticsRow) => [
        Text(analyticsRow.subject),
        Text(analyticsRow.gradelvl),
        Text(analyticsRow.lowestScore.toStringAsFixed(1)),
        Text(
          analyticsRow.averageScore.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(analyticsRow.highestScore.toStringAsFixed(1)),
        Text('${analyticsRow.totalAttempts}'),
      ],
    );
    final recentScoresSection = _PagedTableCard<ScoreRecord>(
      width: compactCardWidth,
      minHeight: alignedCardMinHeight,
      title: 'Recent Scores',
      subtitle: 'Latest score submissions synced from classroom play sessions.',
      items: detail.recentScores,
      emptyMessage: 'No recent score records yet.',
      columns: const [
        'Subject',
        'Group',
        'Difficulty',
        'Score',
        'Result',
        'Played At',
      ],
      rowsPerPage: 5,
      rowBuilder: (score) => [
        Text(score.subject),
        Text(score.gradelvl),
        Text(score.difficulty),
        Text('${score.score.toStringAsFixed(0)}/${score.totalItems}'),
        _ResultChip(passed: score.passed),
        Text(score.playedAt),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlarePageHeader(
            title: '${profile.nickname} • Learner Profile',
            subtitle:
                'Detailed learner context for teacher follow-up and intervention planning.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/students'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to learners'),
              ),
              FlarePill(label: profile.gradelvl, color: AppTheme.primary),
              FlarePill(
                label: profile.proficiency,
                color: _proficiencyColor(profile.proficiency),
              ),
              FilledButton.tonalIcon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isWide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: _buildProfileCard(context, profile)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TeacherFollowUpCard(
                      profile: profile,
                      followUps: followUps,
                      recentScores: detail.recentScores,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _buildProfileCard(context, profile),
            const SizedBox(height: 12),
            _TeacherFollowUpCard(
              profile: profile,
              followUps: followUps,
              recentScores: detail.recentScores,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: cardSpacing,
            runSpacing: cardSpacing,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [progressSection, scorePatternSection],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: cardSpacing,
            runSpacing: cardSpacing,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(
                width: compactCardWidth,
                child: _SectionCard(
                  minHeight: alignedCardMinHeight,
                  title: 'Recent Score Trend',
                  subtitle:
                      'Most recent attempts visualized to quickly spot momentum or regression.',
                  child: recentTrend.isEmpty
                      ? const FlareEmptyState(
                          message: 'No recent score records yet.',
                        )
                      : SingleBarChart(
                          data: recentTrend
                              .map(
                                (score) => SimpleBarDatum(
                                  label: score.subject,
                                  value: score.score,
                                  color: score.passed
                                      ? AppTheme.success
                                      : AppTheme.error,
                                ),
                              )
                              .toList(),
                          maxY: 10,
                        ),
                ),
              ),
              recentScoresSection,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Student profile) {
    return FlareSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: _proficiencyColor(
                  profile.proficiency,
                ).withValues(alpha: 0.18),
                child: Text(
                  profile.nickname.isEmpty
                      ? '?'
                      : profile.nickname.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _proficiencyColor(profile.proficiency),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nickname: ${profile.nickname}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 24,
            runSpacing: 14,
            children: [
              _InfoBlock('Birthday', profile.birthday),
              _InfoBlock('Age', '${profile.age} years old'),
              _InfoBlock('Sex', profile.sex),
              _InfoBlock('Grade Group', profile.gradelvl),
              _InfoBlock('Sessions', '${profile.totalSessions}'),
              _InfoBlock(
                'Average Score',
                '${profile.avgScore.toStringAsFixed(1)} / 10',
              ),
              _InfoBlock('Proficiency', profile.proficiency),
            ],
          ),
        ],
      ),
    );
  }

  List<SubjectAnalytics> _derivedAnalytics(List<ScoreRecord> scores) {
    if (scores.isEmpty) {
      return const <SubjectAnalytics>[];
    }

    final grouped = <String, List<ScoreRecord>>{};
    for (final score in scores) {
      final key = '${score.subject}|${score.gradelvl}';
      grouped.putIfAbsent(key, () => <ScoreRecord>[]).add(score);
    }

    return grouped.entries.map((entry) {
      final values = entry.value.map((score) => score.score).toList();
      final first = entry.value.first;
      final lowest = values.reduce((a, b) => a < b ? a : b);
      final highest = values.reduce((a, b) => a > b ? a : b);
      final average = values.reduce((a, b) => a + b) / values.length;

      return SubjectAnalytics(
        subject: first.subject,
        gradelvl: first.gradelvl,
        lowestScore: lowest,
        averageScore: average,
        highestScore: highest,
        totalAttempts: values.length,
      );
    }).toList();
  }

  List<String> _teacherFollowUps(StudentDetail detail) {
    final items = <String>[];

    if (detail.profile.proficiency == 'Needs support') {
      items.add(
        'This learner is currently flagged as needing support. Review the most recent failed attempts and reinforce the weakest subject first.',
      );
    }

    for (final progress in detail.progress) {
      if (progress.highestDiffPassed == 0) {
        items.add(
          'No difficulty has been passed yet in ${progress.subject}. Keep practice at the easy level before moving forward.',
        );
      }
    }

    for (final score
        in detail.recentScores.where((score) => !score.passed).take(2)) {
      items.add(
        '${score.subject} ${score.difficulty.toLowerCase()} was not passed on ${score.playedAt}. Consider a guided review before the next attempt.',
      );
    }

    if (items.isEmpty) {
      items.add(
        'Current performance looks stable. Continue practice across subjects and watch for new score trends after the next sync.',
      );
    }

    return items;
  }
}

class _TeacherFollowUpCard extends StatelessWidget {
  final Student profile;
  final List<String> followUps;
  final List<ScoreRecord> recentScores;

  const _TeacherFollowUpCard({
    required this.profile,
    required this.followUps,
    required this.recentScores,
  });

  @override
  Widget build(BuildContext context) {
    final passedAttempts = recentScores.where((score) => score.passed).length;

    return FlareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlareSectionTitle(
            title: 'Teacher follow-up',
            subtitle: 'A quick interpretation of the current learner profile.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FlarePill(
                label: '${profile.totalSessions} sessions',
                color: AppTheme.primary,
              ),
              FlarePill(
                label: '${recentScores.length} recent scores',
                color: AppTheme.tertiary,
              ),
              FlarePill(
                label: '$passedAttempts passed',
                color: AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...followUps.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PagedTableCard<T> extends StatefulWidget {
  final double width;
  final double? minHeight;
  final String title;
  final String subtitle;
  final List<T> items;
  final List<String> columns;
  final List<Widget> Function(T item) rowBuilder;
  final String emptyMessage;
  final int rowsPerPage;

  const _PagedTableCard({
    required this.width,
    this.minHeight,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.columns,
    required this.rowBuilder,
    required this.emptyMessage,
    this.rowsPerPage = 4,
  });

  @override
  State<_PagedTableCard<T>> createState() => _PagedTableCardState<T>();
}

class _PagedTableCardState<T> extends State<_PagedTableCard<T>> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant _PagedTableCard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxPage = _maxPage;
    if (_page > maxPage) {
      _page = maxPage;
    }
  }

  int get _maxPage {
    if (widget.items.isEmpty) return 0;
    return ((widget.items.length - 1) / widget.rowsPerPage).floor();
  }

  @override
  Widget build(BuildContext context) {
    final pageItems = widget.items
        .skip(_page * widget.rowsPerPage)
        .take(widget.rowsPerPage)
        .toList();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 48,
      ),
      child: SizedBox(
        width: widget.width,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
          child: FlareSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FlareSectionTitle(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  trailing: widget.items.length > widget.rowsPerPage
                      ? FlarePill(
                          label: '${widget.items.length} rows',
                          color: AppTheme.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                if (widget.items.isEmpty)
                  _EmptyState(message: widget.emptyMessage)
                else ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: widget.columns
                          .map((column) => DataColumn(label: Text(column)))
                          .toList(),
                      rows: pageItems.map((item) {
                        return DataRow(
                          cells: widget
                              .rowBuilder(item)
                              .map(DataCell.new)
                              .toList(),
                        );
                      }).toList(),
                    ),
                  ),
                  if (widget.items.length > widget.rowsPerPage) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Page ${_page + 1} of ${_maxPage + 1}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        IconButton(
                          tooltip: 'Previous page',
                          onPressed: _page == 0
                              ? null
                              : () => setState(() => _page -= 1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        IconButton(
                          tooltip: 'Next page',
                          onPressed: _page >= _maxPage
                              ? null
                              : () => setState(() => _page += 1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
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
  final double? minHeight;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      child: FlareSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlareSectionTitle(title: title, subtitle: subtitle),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBlock(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final bool passed;

  const _ResultChip({required this.passed});

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppTheme.accent : AppTheme.error;

    return FlarePill(label: passed ? 'Passed' : 'Needs review', color: color);
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(8), child: Text(message));
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

Color _proficiencyColor(String proficiency) {
  switch (proficiency) {
    case 'Excelling':
      return AppTheme.accent;
    case 'On track':
      return AppTheme.primary;
    case 'Needs support':
      return AppTheme.error;
    default:
      return AppTheme.tertiary;
  }
}
