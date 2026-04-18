import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/student.dart';
import '../providers/students_provider.dart';
import '../widgets/page_skeletons.dart';

Color _proficiencyColor(String proficiency) {
  switch (proficiency) {
    case 'Excelling':
      return AppTheme.accent;
    case 'On track':
      return AppTheme.primary;
    case 'Needs support':
      return AppTheme.tertiary;
    default:
      return AppTheme.error;
  }
}

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return SafeArea(
      child: studentsAsync.when(
        loading: () => const StudentsLoadingSkeleton(),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 10),
              Text('$error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(studentsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
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

  List<Student> get _filtered {
    return widget.students.where((student) {
      final searchLower = _search.toLowerCase();
      final nameMatch =
          student.nickname.toLowerCase().contains(searchLower) ||
          student.fullName.toLowerCase().contains(searchLower);
      final groupMatch =
          _groupFilter == 'All' || student.gradelvl.contains(_groupFilter);
      return nameMatch && groupMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final punlaCount = widget.students
        .where((student) => student.gradelvl.contains('Punla'))
        .length;
    final binhiCount = widget.students
        .where((student) => student.gradelvl.contains('Binhi'))
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Students',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              FilledButton.tonalIcon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                label: 'Total Students',
                value: '${widget.students.length}',
                color: AppTheme.primary,
              ),
              _MetricChip(
                label: 'Punla',
                value: '$punlaCount',
                color: AppTheme.accent,
              ),
              _MetricChip(
                label: 'Binhi',
                value: '$binhiCount',
                color: AppTheme.tertiary,
              ),
              _MetricChip(
                label: 'Showing',
                value: '${filtered.length}',
                color: AppTheme.info,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or nickname...',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _groupFilter,
                  dropdownColor: AppTheme.surface,
                  items: const ['All', 'Punla', 'Binhi']
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text('Group: $value'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _groupFilter = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No students match the current filter.'),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Nickname')),
                              DataColumn(label: Text('Full Name')),
                              DataColumn(label: Text('Age')),
                              DataColumn(label: Text('Group')),
                              DataColumn(label: Text('Sex')),
                              DataColumn(label: Text('Sessions')),
                              DataColumn(label: Text('Avg Score')),
                              DataColumn(label: Text('Proficiency')),
                            ],
                            rows: filtered.map((student) {
                              final proficiencyColor = _proficiencyColor(
                                student.proficiency,
                              );
                              return DataRow(
                                onSelectChanged: (_) =>
                                    context.go('/students/${student.studId}'),
                                cells: [
                                  DataCell(Text('${student.studId}')),
                                  DataCell(
                                    Text(
                                      student.nickname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(student.fullName)),
                                  DataCell(Text('${student.age}')),
                                  DataCell(Text(student.gradelvl)),
                                  DataCell(Text(student.sex)),
                                  DataCell(Text('${student.totalSessions}')),
                                  DataCell(
                                    Text(student.avgScore.toStringAsFixed(1)),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: proficiencyColor.withValues(alpha: 
                                          0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        student.proficiency,
                                        style: TextStyle(
                                          color: proficiencyColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
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
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
