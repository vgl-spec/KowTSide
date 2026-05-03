import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/student.dart';
import '../providers/live_updates_provider.dart';
import '../providers/students_provider.dart';
import '../widgets/flareline_components.dart';
import '../widgets/page_skeletons.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(wsEventsProvider, (_, next) {
      next.whenData((event) {
        if (shouldInvalidateForWsEvent(event.type)) {
          ref.invalidate(studentsProvider);
        }
      });
    });

    final studentsAsync = ref.watch(studentsProvider);

    return SafeArea(
      child: studentsAsync.when(
        loading: () => const StudentsLoadingSkeleton(),
        error: (error, _) => _ErrorState(
          message: 'Failed to load learners: $error',
          onRetry: () => ref.invalidate(studentsProvider),
        ),
        data: (students) => _StudentsView(
          students: students,
          onRefresh: () => ref.invalidate(studentsProvider),
        ),
      ),
    );
  }
}

class _StudentsView extends StatefulWidget {
  final List<Student> students;
  final VoidCallback onRefresh;

  const _StudentsView({required this.students, required this.onRefresh});

  @override
  State<_StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<_StudentsView> {
  String _search = '';
  String _groupFilter = 'All';
  String _supportFilter = 'All';
  String _sortBy = 'Name';
  int _page = 0;
  static const int _rowsPerPage = 8;

  List<Student> get _filtered {
    final searchLower = _search.trim().toLowerCase();
    final results = widget.students.where((student) {
      final matchesSearch =
          searchLower.isEmpty ||
          student.nickname.toLowerCase().contains(searchLower) ||
          student.fullName.toLowerCase().contains(searchLower);
      final matchesGroup =
          _groupFilter == 'All' || student.gradelvl.contains(_groupFilter);
      final matchesSupport = switch (_supportFilter) {
        'Needs support' => _isNeedsSupport(student),
        'On track' => student.proficiency == 'On track',
        'Excelling' => student.proficiency == 'Excelling',
        _ => true,
      };

      return matchesSearch && matchesGroup && matchesSupport;
    }).toList();

    // Sort learners according to selected sort mode.
    results.sort((a, b) {
      switch (_sortBy) {
        case 'Name':
          final nameCompare = a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
          if (nameCompare != 0) return nameCompare;
          return a.avgScore.compareTo(b.avgScore);
        case 'Age':
          final ageCompare = a.age.compareTo(b.age);
          if (ageCompare != 0) return ageCompare;
          return a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
        case 'Support':
          final supportCompare = _supportPriority(a.proficiency).compareTo(_supportPriority(b.proficiency));
          if (supportCompare != 0) return supportCompare;
          return a.avgScore.compareTo(b.avgScore);
        default:
          final nameCompare = a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
          if (nameCompare != 0) return nameCompare;
          return a.avgScore.compareTo(b.avgScore);
      }
    });

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final maxPage = filtered.isEmpty
        ? 0
        : ((filtered.length - 1) / _rowsPerPage).floor();
    if (_page > maxPage) {
      _page = maxPage;
    }
    final supportQueue =
        widget.students
            .where((student) => student.proficiency != 'Excelling')
            .toList()
          ..sort((a, b) {
            final supportCompare = _supportPriority(
              a.proficiency,
            ).compareTo(_supportPriority(b.proficiency));
            if (supportCompare != 0) {
              return supportCompare;
            }
            return a.avgScore.compareTo(b.avgScore);
          });
    final punlaCount = widget.students
        .where(_isPunla)
        .length;
    final binhiCount = widget.students
        .where((student) => student.gradelvl.contains('Binhi'))
        .length;
    final needsSupportCount = widget.students
        .where(_isNeedsSupport)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlarePageHeader(
            title: 'Learners',
            subtitle:
                'Read-only learner records synced from tablets. Filter quickly to find students who need coaching support.',
            actions: [
              FlarePill(
                label: '${filtered.length} showing',
                color: AppTheme.info,
              ),
              FilledButton.tonalIcon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _KpiGrid(
            children: [
              FlareMetricTile(
                label: 'Total Learners',
                value: '${widget.students.length}',
                hint: 'All synced learner profiles',
                icon: Icons.groups_rounded,
                color: AppTheme.primary,
              ),
              FlareMetricTile(
                label: 'Punla Learners',
                value: '$punlaCount',
                hint: 'Ages 4-5 grouping',
                icon: Icons.eco_rounded,
                color: AppTheme.success,
              ),
              FlareMetricTile(
                label: 'Binhi Learners',
                value: '$binhiCount',
                hint: 'Ages 6-7 grouping',
                icon: Icons.grass_rounded,
                color: AppTheme.tertiary,
              ),
              FlareMetricTile(
                label: 'Needs Support',
                value: '$needsSupportCount',
                hint: 'Priority learners for review',
                icon: Icons.flag_circle_rounded,
                color: AppTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportHeight = constraints.maxHeight;
                final preferredMainHeight = viewportHeight * 0.66;
                final mainHeight = preferredMainHeight < 520
                    ? 520.0
                    : preferredMainHeight;

                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: mainHeight,
                          child: _buildMainContent(context, filtered),
                        ),
                        const SizedBox(height: 16),
                        _SupportPanelPaged(students: supportQueue),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, List<Student> students) {
    return FlareSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search learner or nickname...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ),
                _SimpleDropdown(
                  label: 'Group',
                  value: _groupFilter,
                  options: const ['All', 'Punla', 'Binhi'],
                  onChanged: (value) => setState(() => _groupFilter = value),
                ),
                _SimpleDropdown(
                  label: 'Support',
                  value: _supportFilter,
                  options: const [
                    'All',
                    'Needs support',
                    'On track',
                    'Excelling',
                  ],
                  onChanged: (value) => setState(() => _supportFilter = value),
                ),
                _SimpleDropdown(
                  label: 'Sort',
                  value: _sortBy,
                  options: const ['Name', 'Age', 'Support'],
                  onChanged: (value) => setState(() => _sortBy = value),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildLearnerTable(context, students)),
        ],
      ),
    );
  }

  Widget _buildLearnerTable(BuildContext context, List<Student> students) {
    final maxPage = students.isEmpty
        ? 0
        : ((students.length - 1) / _rowsPerPage).floor();
    final pageItems = students.skip(_page * _rowsPerPage).take(_rowsPerPage);

    return students.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No learners match the current filters.'),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                            ),
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Learner')),
                              DataColumn(label: Text('Age')),
                              DataColumn(label: Text('Group')),
                              DataColumn(label: Text('Sessions')),
                              DataColumn(label: Text('Average')),
                              DataColumn(label: Text('Proficiency')),
                              DataColumn(label: Text('')),
                            ],
                            rows: pageItems.map((student) {
                              return DataRow(
                                onSelectChanged: (_) =>
                                    context.go('/students/${student.studId}'),
                                cells: [
                                  DataCell(
                                    Text(
                                      student.displayStudId,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 220,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            student.nickname,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            student.fullName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(Text('${student.age}')),
                                  DataCell(Text(student.gradelvl)),
                                  DataCell(Text('${student.totalSessions}')),
                                  DataCell(
                                    Text(
                                      student.avgScore.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _ProficiencyChip(
                                      proficiency: student.proficiency,
                                    ),
                                  ),
                                  DataCell(
                                    OutlinedButton.icon(
                                      onPressed: () => context.go(
                                        '/students/${student.studId}',
                                      ),
                                      icon: const Icon(
                                        Icons.visibility_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('View'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
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
                    );
                  },
                ),
              ),
              if (students.length > _rowsPerPage) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${_page * _rowsPerPage + 1} - ${(_page * _rowsPerPage + pageItems.length)} of ${students.length} learners',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Previous page',
                            onPressed: _page == 0
                                ? null
                                : () => setState(() => _page -= 1),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          Text(
                            'Page ${_page + 1} of ${maxPage + 1}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          IconButton(
                            tooltip: 'Next page',
                            onPressed: _page >= maxPage
                                ? null
                                : () => setState(() => _page += 1),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
  }

  int _supportPriority(String proficiency) {
    final normalized = proficiency.trim().toLowerCase();
    if (normalized.contains('needs support')) return 0;
    if (normalized == 'on track') return 1;
    if (normalized == 'excelling') return 2;
    return 3;
  }

  bool _isPunla(Student student) {
    final grade = student.gradelvl.trim().toLowerCase();
    if (grade.contains('punla')) return true;
    return student.age >= 3 && student.age <= 5;
  }

  bool _isNeedsSupport(Student student) {
    final normalized = student.proficiency.trim().toLowerCase();
    final flaggedByLabel =
        (normalized.contains('needs') && normalized.contains('support')) ||
        normalized.contains('at risk');
    if (flaggedByLabel) return true;
    return student.avgScore < 7.0;
  }
}

class _SupportPanel extends StatelessWidget {
  final List<Student> students;

  const _SupportPanel({required this.students});

  @override
  Widget build(BuildContext context) {
    final highlighted = students.take(12).toList();

    // Give this panel more vertical space so teachers can view more follow-up
    // rows without extra navigation.
    final maxHeight = MediaQuery.of(context).size.height * 0.62;

    return FlareSurfaceCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FlareSectionTitle(
                title: 'Teacher follow-up',
                subtitle:
                    'Learners who may need extra review based on current proficiency and average score.',
              ),
              const SizedBox(height: 12),
              if (highlighted.isEmpty)
                const Text('No follow-up learners identified right now.')
              else
                ...highlighted.map((student) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _proficiencyColor(
                        student.proficiency,
                      ).withValues(alpha: 0.16),
                      child: Text(
                        student.nickname.isEmpty
                            ? '?'
                            : student.nickname.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: _proficiencyColor(student.proficiency),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(student.fullName),
                    subtitle: Text(
                      '${student.gradelvl} • ${student.avgScore.toStringAsFixed(1)}/10 average',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: _ProficiencyChip(proficiency: student.proficiency),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportPanelPaged extends StatefulWidget {
  final List<Student> students;

  const _SupportPanelPaged({required this.students});

  @override
  State<_SupportPanelPaged> createState() => _SupportPanelPagedState();
}

class _SupportPanelPagedState extends State<_SupportPanelPaged> {
  static const int _rowsPerPage = 100;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final total = widget.students.length;
    final maxPage = total == 0 ? 0 : ((total - 1) / _rowsPerPage).floor();
    if (_page > maxPage) {
      _page = maxPage;
    }
    final pageItems = widget.students
        .skip(_page * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    final maxHeight = MediaQuery.of(context).size.height * 0.52;

    return FlareSurfaceCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FlareSectionTitle(
                title: 'Teacher follow-up',
                subtitle:
                    'Learners who may need extra review based on current proficiency and average score.',
              ),
              const SizedBox(height: 12),
              if (pageItems.isEmpty)
                const Text('No follow-up learners identified right now.')
              else
                Column(
                  children: [
                    ...pageItems.map((student) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _proficiencyColor(
                            student.proficiency,
                          ).withValues(alpha: 0.16),
                          child: Text(
                            student.nickname.isEmpty
                                ? '?'
                                : student.nickname.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: _proficiencyColor(student.proficiency),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(student.fullName),
                        subtitle: Text(
                          '${student.gradelvl} • ${student.avgScore.toStringAsFixed(1)}/10 average',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _ProficiencyChip(proficiency: student.proficiency),
                      );
                    }),
                    if (total > _rowsPerPage) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${_page * _rowsPerPage + 1}-${_page * _rowsPerPage + pageItems.length} of $total',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Previous page',
                                onPressed: _page == 0
                                    ? null
                                    : () => setState(() => _page -= 1),
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                              Text(
                                'Page ${_page + 1} of ${maxPage + 1}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              IconButton(
                                tooltip: 'Next page',
                                onPressed: _page >= maxPage
                                    ? null
                                    : () => setState(() => _page += 1),
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
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

class _SimpleDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SimpleDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: options
            .map(
              (option) =>
                  DropdownMenuItem<String>(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }
}

class _ProficiencyChip extends StatelessWidget {
  final String proficiency;

  const _ProficiencyChip({required this.proficiency});

  @override
  Widget build(BuildContext context) {
    final color = _proficiencyColor(proficiency);

    return FlarePill(label: proficiency, color: color);
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

