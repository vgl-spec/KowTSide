import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excel/excel.dart' as xls;
import 'package:intl/intl.dart';

import '../core/question_export_service.dart';
import '../core/score_utils.dart';
import '../core/theme.dart';
import '../models/dashboard.dart';
import '../models/reporting.dart';
import '../models/student.dart';
import '../providers/live_updates_provider.dart';
import '../providers/reports_provider.dart';
import '../providers/students_provider.dart';
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
                  onPressed: () =>
                      _exportOverallXlsx(context, dashboard, students),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Export Analytics'),
                ),
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
            _AreaPerformanceCard(students: students),
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

  static Future<void> _exportOverallXlsx(
    BuildContext context,
    DashboardData dashboard,
    List<Student> students,
  ) async {
    try {
      final now = DateTime.now();
      final sortedStudents = [...students]
        ..sort((a, b) {
          final areaSort = a.area.toLowerCase().compareTo(b.area.toLowerCase());
          if (areaSort != 0) return areaSort;
          final scoreSort = b.avgScore.compareTo(a.avgScore);
          if (scoreSort != 0) return scoreSort;
          return b.totalSessions.compareTo(a.totalSessions);
        });
      final excel = xls.Excel.createExcel();
      final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[defaultSheetName];
      final headerStyle = xls.CellStyle(
        bold: true,
        backgroundColorHex: xls.ExcelColor.fromHexString('#DCEBFF'),
        horizontalAlign: xls.HorizontalAlign.Center,
      );

      sheet.appendRow(<xls.CellValue>[
        xls.TextCellValue('Generated At'),
        xls.TextCellValue('Total Learners'),
        xls.TextCellValue('Total Sessions'),
        xls.TextCellValue('Average Score'),
        xls.TextCellValue('Overall Pass Rate (%)'),
      ]);
      sheet.appendRow(<xls.CellValue>[
        xls.TextCellValue(_sanitizeExcelText(now.toIso8601String())),
        xls.IntCellValue(dashboard.totalStudents),
        xls.IntCellValue(dashboard.totalScores),
        xls.DoubleCellValue(dashboard.averageScore),
        xls.DoubleCellValue(dashboard.passRatePct),
      ]);

      sheet.appendRow(<xls.CellValue>[
        xls.TextCellValue(''),
        xls.TextCellValue(''),
        xls.TextCellValue(''),
        xls.TextCellValue(''),
        xls.TextCellValue(''),
      ]);

      final learnerHeader = <xls.CellValue>[
        xls.TextCellValue('Student ID'),
        xls.TextCellValue('Nickname'),
        xls.TextCellValue('Full Name'),
        xls.TextCellValue('Area'),
        xls.TextCellValue('Grade Level'),
        xls.TextCellValue('Age'),
        xls.TextCellValue('Sessions'),
        xls.TextCellValue('Average Score'),
        xls.TextCellValue('Proficiency'),
      ];
      sheet.appendRow(learnerHeader);
      for (final student in sortedStudents) {
        sheet.appendRow(<xls.CellValue>[
          xls.TextCellValue(_sanitizeExcelText(student.displayStudId)),
          xls.TextCellValue(_sanitizeExcelText(student.nickname)),
          xls.TextCellValue(_sanitizeExcelText(student.fullName)),
          xls.TextCellValue(_sanitizeExcelText(_normalizedArea(student.area))),
          xls.TextCellValue(_sanitizeExcelText(student.gradelvl)),
          xls.IntCellValue(student.age),
          xls.IntCellValue(student.totalSessions),
          xls.DoubleCellValue(student.avgScore),
          xls.TextCellValue(_sanitizeExcelText(student.proficiency)),
        ]);
      }
      final learnerHeaderRow = 3;
      for (var col = 0; col < learnerHeader.length; col++) {
        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(
                    columnIndex: col,
                    rowIndex: learnerHeaderRow,
                  ),
                )
                .cellStyle =
            headerStyle;
      }
      for (var col = 0; col < 5; col++) {
        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
                )
                .cellStyle =
            headerStyle;
      }
      sheet.setDefaultColumnWidth(22);
      final bytes = excel.encode();
      if (bytes == null) {
        throw StateError('Excel encoding returned empty result.');
      }
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      await downloadBinaryFile(
        filename: 'analytics_overall_$stamp.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analytics Spreadsheets Downloaded.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }
}

class _AreaPerformanceCard extends ConsumerStatefulWidget {
  final List<Student> students;
  const _AreaPerformanceCard({required this.students});

  @override
  ConsumerState<_AreaPerformanceCard> createState() =>
      _AreaPerformanceCardState();
}

class _AreaPerformanceCardState extends ConsumerState<_AreaPerformanceCard> {
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Student>>{};
    for (final student in widget.students) {
      final area = student.area.trim().isEmpty
          ? 'Unspecified Area'
          : student.area.trim();
      groups.putIfAbsent(area, () => <Student>[]).add(student);
    }
    final rows = groups.entries.map((entry) {
      final totalSessions = entry.value.fold<int>(
        0,
        (sum, s) => sum + s.totalSessions,
      );
      final avg = entry.value.isEmpty
          ? 0.0
          : entry.value.fold<double>(0, (sum, s) => sum + s.avgScore) /
                entry.value.length;
      return _AreaSummary(
        area: entry.key,
        learners: entry.value.length,
        sessions: totalSessions,
        averageScore: avg,
      );
    }).toList()..sort((a, b) => b.averageScore.compareTo(a.averageScore));

    return FlareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlareSectionTitle(
            title: 'Area Performance and Leaderboard',
            subtitle:
                'Click an area for visit-by-visit comparison and learner session breakdown.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_outlined, size: 16),
                label: Text(
                  _range == null
                      ? 'Select date range'
                      : '${DateFormat('yyyy-MM-dd').format(_range!.start)} to ${DateFormat('yyyy-MM-dd').format(_range!.end)}',
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _exportAreaXlsx(rows),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export Area Leaderboard'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          rows.isEmpty
              ? const FlareEmptyState(
                  message: 'No area performance rows available.',
                )
              : Column(
                  children: rows
                      .map(
                        (row) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(row.area),
                          subtitle: Text(
                            '${row.learners} learners | ${row.sessions} sessions | ${row.averageScore.toStringAsFixed(2)} avg score',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _openAreaDrilldown(row.area),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null && mounted) {
      setState(() => _range = picked);
    }
  }

  Future<void> _exportAreaXlsx(List<_AreaSummary> rows) async {
    try {
      final excel = xls.Excel.createExcel();
      final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[defaultSheetName];
      final headerStyle = xls.CellStyle(
        bold: true,
        backgroundColorHex: xls.ExcelColor.fromHexString('#DCEBFF'),
        horizontalAlign: xls.HorizontalAlign.Center,
      );
      sheet.appendRow(<xls.CellValue>[
        xls.TextCellValue('Area'),
        xls.TextCellValue('Total Learners'),
        xls.TextCellValue('Total Sessions'),
        xls.TextCellValue('Average Score'),
      ]);
      final sortedRows = [...rows]
        ..sort((a, b) => b.averageScore.compareTo(a.averageScore));
      for (final row in sortedRows) {
        sheet.appendRow(<xls.CellValue>[
          xls.TextCellValue(_sanitizeExcelText(row.area)),
          xls.IntCellValue(row.learners),
          xls.IntCellValue(row.sessions),
          xls.DoubleCellValue(row.averageScore),
        ]);
      }
      for (var col = 0; col < 4; col++) {
        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
                )
                .cellStyle =
            headerStyle;
      }
      sheet.setDefaultColumnWidth(24);
      final bytes = excel.encode();
      if (bytes == null) {
        throw StateError('Excel encoding returned empty result.');
      }
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await downloadBinaryFile(
        filename: 'leaderboard_by_area_$stamp.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Area leaderboard spreadsheets downloaded.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Area export failed: $error')));
    }
  }

  Future<void> _openAreaDrilldown(String area) async {
    final areaStudents = widget.students
        .where(
          (s) =>
              (s.area.trim().isEmpty ? 'Unspecified Area' : s.area.trim()) ==
              area,
        )
        .toList();
    final details = await Future.wait(
      areaStudents.map(
        (student) => ref.read(studentDetailProvider(student.studId).future),
      ),
    );
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) =>
          _AreaDrilldownDialog(area: area, details: details, range: _range),
    );
  }
}

class _AreaDrilldownDialog extends StatelessWidget {
  final String area;
  final List<StudentDetail> details;
  final DateTimeRange? range;

  const _AreaDrilldownDialog({
    required this.area,
    required this.details,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final visitsByDay = <String, List<double>>{};
    for (final detail in details) {
      for (final score in detail.recentScores) {
        final playedAt = DateTime.tryParse(score.playedAt);
        if (playedAt == null) continue;
        if (range != null &&
            (playedAt.isBefore(range!.start) ||
                playedAt.isAfter(range!.end.add(const Duration(days: 1))))) {
          continue;
        }
        final key = DateFormat('yyyy-MM-dd').format(playedAt);
        visitsByDay.putIfAbsent(key, () => <double>[]).add(score.score);
      }
    }
    final sortedDays = visitsByDay.keys.toList()..sort();
    final chartData = sortedDays
        .map(
          (day) => SimpleBarDatum(
            label: day.substring(5),
            value:
                visitsByDay[day]!.reduce((a, b) => a + b) /
                visitsByDay[day]!.length,
            color: AppTheme.primary,
          ),
        )
        .toList();

    return Dialog(
      child: SizedBox(
        width: 1100,
        height: 760,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                area,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Visit comparison, learner sessions, unlocked progress, and profile shortcuts.',
              ),
              const SizedBox(height: 14),
              Expanded(
                child: chartData.isEmpty
                    ? const FlareEmptyState(
                        message: 'No score visits found in selected range.',
                      )
                    : SingleBarChart(data: chartData, maxY: 5),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: details.length,
                  itemBuilder: (context, index) {
                    final detail = details[index];
                    final highestUnlocked = detail.progress.isEmpty
                        ? 'None'
                        : detail.progress.map((p) => p.diffLabel).join(', ');
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${detail.profile.fullName} (${detail.profile.displayStudId})',
                        ),
                        subtitle: Text(
                          'Age ${detail.profile.age} | ${detail.profile.gradelvl} | Sessions ${detail.profile.totalSessions} | Unlocked: $highestUnlocked',
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () =>
                              context.go('/students/${detail.profile.studId}'),
                          child: const Text('View Learner Profile'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaSummary {
  final String area;
  final int learners;
  final int sessions;
  final double averageScore;

  const _AreaSummary({
    required this.area,
    required this.learners,
    required this.sessions,
    required this.averageScore,
  });
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

String _sanitizeExcelText(String input) {
  if (input.isEmpty) return input;
  final buffer = StringBuffer();
  for (final codePoint in input.runes) {
    final isAllowedControl =
        codePoint == 0x09 || codePoint == 0x0A || codePoint == 0x0D;
    final isInvalidControl = codePoint < 0x20 && !isAllowedControl;
    if (!isInvalidControl) {
      buffer.writeCharCode(codePoint);
    }
  }
  return buffer.toString();
}

String _normalizedArea(String raw) {
  final area = raw.trim();
  if (area.isEmpty) return 'Unspecified Area';
  return area;
}
